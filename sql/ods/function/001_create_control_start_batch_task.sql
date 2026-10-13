CREATE OR REPLACE FUNCTION control.start_batch_task(
    p_batch_id            BIGINT,
    p_workflow_code       VARCHAR(100),
    p_workflow_task_id    BIGINT,
    p_task_code           VARCHAR(100),
    p_execution_order     INTEGER,
    p_execution_type      VARCHAR(30),
    p_execution_ref       VARCHAR(256),
    p_expected_attempt_no INTEGER
)
RETURNS TABLE (
    batch_task_id    BIGINT,
    batch_id         BIGINT,
    workflow_code    VARCHAR(100),
    workflow_task_id BIGINT,
    task_code        VARCHAR(100),
    execution_order  INTEGER,
    execution_type   VARCHAR(30),
    execution_ref    VARCHAR(256),
    attempt_no       INTEGER,
    status            control.execution_status,
    started_at        TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_status       control.batch_status;
    v_execution_order    INTEGER;
    v_execution_type     VARCHAR(30);
    v_execution_ref      VARCHAR(256);
    v_is_observable      BOOLEAN;
    v_retryable          BOOLEAN;
    v_max_retry_count    INTEGER;
    v_attempt_no         INTEGER;
BEGIN

    /*
     * ============================================================
     * 1. Validate và lock batch
     * ============================================================
     */
    SELECT b.status
      INTO v_batch_status
      FROM control.batch b
     WHERE b.batch_id = p_batch_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'BATCH_NOT_FOUND',
                DETAIL = format(
                    'batch_id=%s',
                    p_batch_id
                );
    END IF;


    IF v_batch_status <> 'RUNNING' THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'BATCH_INVALID_STATE',
                DETAIL = format(
                    'batch_id=%s,status=%s',
                    p_batch_id,
                    v_batch_status
                );
    END IF;


    /*
     * ============================================================
     * 2. Resolve workflow task từ DB
     *
     * Không tin execution metadata do caller truyền vào.
     * Caller chỉ cung cấp expected values.
     * ============================================================
     */
    SELECT
        wt.execution_order,
        wt.execution_type,
        wt.execution_ref,
        td.is_observable,
        td.retryable,
        td.max_retry_count

      INTO
        v_execution_order,
        v_execution_type,
        v_execution_ref,
        v_is_observable,
        v_retryable,
        v_max_retry_count

      FROM control.workflow_task wt

      JOIN control.task_definition td
        ON td.task_code = wt.task_code

     WHERE wt.workflow_task_id = p_workflow_task_id
       AND wt.workflow_code = p_workflow_code
       AND wt.task_code = p_task_code
       AND wt.is_enabled = TRUE
       AND td.is_enabled = TRUE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'WORKFLOW_TASK_NOT_FOUND',
                DETAIL = format(
                    'workflow_code=%s,workflow_task_id=%s,task_code=%s',
                    p_workflow_code,
                    p_workflow_task_id,
                    p_task_code
                );
    END IF;


    /*
     * ============================================================
     * 3. Task phải observable
     * ============================================================
     */
    IF NOT v_is_observable THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'TASK_NOT_OBSERVABLE',
                DETAIL = format(
                    'workflow_task_id=%s,task_code=%s',
                    p_workflow_task_id,
                    p_task_code
                );
    END IF;


    /*
     * ============================================================
     * 4. Validate execution metadata
     *
     * Bảo vệ trường hợp dispatcher đang dùng metadata cũ
     * trong khi workflow_task đã bị thay đổi.
     * ============================================================
     */
    IF v_execution_order <> p_execution_order THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'WORKFLOW_TASK_METADATA_CHANGED',
                DETAIL = format(
                    'workflow_task_id=%s,expected_execution_order=%s,current_execution_order=%s',
                    p_workflow_task_id,
                    p_execution_order,
                    v_execution_order
                );
    END IF;


    IF v_execution_type <> p_execution_type THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'WORKFLOW_TASK_METADATA_CHANGED',
                DETAIL = format(
                    'workflow_task_id=%s,expected_execution_type=%s,current_execution_type=%s',
                    p_workflow_task_id,
                    p_execution_type,
                    v_execution_type
                );
    END IF;


    IF v_execution_ref <> p_execution_ref THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'WORKFLOW_TASK_METADATA_CHANGED',
                DETAIL = format(
                    'workflow_task_id=%s,expected_execution_ref=%s,current_execution_ref=%s',
                    p_workflow_task_id,
                    p_execution_ref,
                    v_execution_ref
                );
    END IF;


    /*
     * ============================================================
     * 5. Không cho phép active attempt
     * ============================================================
     */
    IF EXISTS (
        SELECT 1
          FROM control.batch_task bt
         WHERE bt.batch_id = p_batch_id
           AND bt.task_code = p_task_code
           AND bt.status IN (
               'PENDING',
               'RUNNING'
           )
    ) THEN

        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'TASK_ALREADY_RUNNING',
                DETAIL = format(
                    'batch_id=%s,task_code=%s',
                    p_batch_id,
                    p_task_code
                );

    END IF;


    /*
     * ============================================================
     * 6. Xác định attempt thực tế tiếp theo
     * ============================================================
     */
    SELECT
        COALESCE(
            MAX(bt.attempt_no),
            0
        ) + 1

      INTO v_attempt_no

      FROM control.batch_task bt

     WHERE bt.batch_id = p_batch_id
       AND bt.task_code = p_task_code;


    /*
     * ============================================================
     * 7. Chống stale dispatcher
     *
     * get_next_workflow_task() đã trả:
     *
     *     next_attempt_no
     *
     * Nếu attempt thực tế khác expected attempt
     * thì dispatcher đang dùng kết quả cũ.
     * ============================================================
     */
    IF v_attempt_no <> p_expected_attempt_no THEN

        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'TASK_ATTEMPT_STATE_CHANGED',
                DETAIL = format(
                    'batch_id=%s,task_code=%s,expected_attempt_no=%s,current_attempt_no=%s',
                    p_batch_id,
                    p_task_code,
                    p_expected_attempt_no,
                    v_attempt_no
                );

    END IF;


    /*
     * ============================================================
     * 8. Create batch_task
     * ============================================================
     */
    INSERT INTO control.batch_task AS bt (
        batch_id,
        task_code,
        workflow_task_id,
        execution_order,
        status,
        attempt_no,
        started_at
    )
    VALUES (
        p_batch_id,
        p_task_code,
        p_workflow_task_id,
        v_execution_order,
        'RUNNING',
        v_attempt_no,
        CURRENT_TIMESTAMP
    )
    RETURNING
        bt.batch_task_id,
        bt.batch_id,
        bt.task_code,
        bt.execution_order,
        bt.attempt_no,
        bt.status,
        bt.started_at
    INTO
        batch_task_id,
        batch_id,
        task_code,
        execution_order,
        attempt_no,
        status,
        started_at;

    workflow_code := p_workflow_code;
    workflow_task_id := p_workflow_task_id;
    execution_type := v_execution_type;
    execution_ref := v_execution_ref;

    RETURN NEXT;
END;
$$;

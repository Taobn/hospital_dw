CREATE OR REPLACE FUNCTION control.cleanup_stale_batch_tasks(
    p_batch_id             BIGINT,
    p_stale_after_seconds  INTEGER DEFAULT 3600
)
RETURNS TABLE (
   batch_task_id BIGINT,
    task_code     VARCHAR(100),
    attempt_no    INTEGER,
    previous_status control.execution_status,
    new_status      control.execution_status,
    error_code      VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_status control.batch_status;
BEGIN

    IF p_stale_after_seconds <= 0 THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'INVALID_STALE_TIMEOUT',
                DETAIL = format(
                    'stale_after_seconds=%s',
                    p_stale_after_seconds
                );
    END IF;


    /*
     * 1. Lock batch.
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


    /*
     * 2. Chỉ cleanup execution đang active.
     */
    RETURN QUERY
    WITH stale_tasks AS (
        SELECT
            bt.batch_task_id,
            bt.task_code,
            bt.attempt_no,
            bt.status AS previous_status
        FROM control.batch_task bt
        JOIN control.task_definition td
          ON td.task_code = bt.task_code
        WHERE bt.batch_id = p_batch_id
          AND bt.status = 'RUNNING'
          AND bt.started_at IS NOT NULL
          AND bt.started_at < CURRENT_TIMESTAMP
                - make_interval(
                    secs => COALESCE(
                        td.timeout_seconds,
                        p_stale_after_seconds
                    )
                )
        FOR UPDATE OF bt
    ),
    updated_tasks AS (
        UPDATE control.batch_task bt
           SET
               status = 'FAILED',
               completed_at = CURRENT_TIMESTAMP,
               error_code = 'EXECUTION_TIMEOUT',
               error_message = format(
                   'Task exceeded execution timeout. batch_id=%s, task_code=%s, attempt_no=%s',
                   bt.batch_id,
                   bt.task_code,
                   bt.attempt_no
               ),
               updated_at = CURRENT_TIMESTAMP
          FROM stale_tasks st
         WHERE bt.batch_task_id = st.batch_task_id
        RETURNING
            bt.batch_task_id,
            bt.task_code,
            bt.attempt_no,
            st.previous_status,
            bt.status AS new_status,
            bt.error_code
    )
    SELECT
        ut.batch_task_id,
        ut.task_code,
        ut.attempt_no,
        ut.previous_status,
        ut.new_status,
        ut.error_code
    FROM updated_tasks ut
    ORDER BY ut.batch_task_id;

END;
$$;

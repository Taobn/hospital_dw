CREATE OR REPLACE FUNCTION control.get_next_workflow_task(
    p_batch_id      BIGINT,
    p_workflow_code VARCHAR(100)
)
RETURNS TABLE (
    batch_id         BIGINT,
    workflow_code    VARCHAR(100),
    workflow_task_id BIGINT,
    task_code        VARCHAR(100),
    execution_order  INTEGER,
    execution_type   VARCHAR(30),
    execution_ref    VARCHAR(256),
    retryable        BOOLEAN,
    max_retry_count  INTEGER,
    next_attempt_no  INTEGER,
    task_status      control.execution_status,
    dispatch_status   VARCHAR(20),
    started_at        TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_batch_status control.batch_status;
BEGIN

    /*
     * ============================================================
     * 1. Validate batch
     * ============================================================
     */
    SELECT b.status
      INTO v_batch_status
      FROM control.batch b
     WHERE b.batch_id = p_batch_id;

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
     * ============================================================
     * 2. Batch phải đang RUNNING
     *
     * COMPLETE / FAILED / CANCELLED batch không được dispatcher
     * tiếp tục xử lý.
     * ============================================================
     */
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
     * 3. Build state của từng observable task
     * ============================================================
     */
    RETURN QUERY
    WITH task_state AS (

        SELECT
            wt.workflow_task_id,
            wt.task_code,
            wt.execution_order,
            wt.execution_type,
            wt.execution_ref,

            td.retryable,
            td.max_retry_count,

            /*
             * Tổng số attempt đã thực hiện.
             */
            COUNT(bt.batch_task_id) AS attempt_count,

            /*
             * Attempt cuối cùng.
             */
            MAX(bt.attempt_no) AS last_attempt_no,

            /*
             * Có attempt SUCCESS hay không.
             */
            COALESCE(
                BOOL_OR(
                    bt.status = 'SUCCESS'
                ),
                FALSE
            ) AS has_success,

            /*
             * Có attempt PENDING/RUNNING hay không.
             */
            COALESCE(
                BOOL_OR(
                    bt.status IN ('PENDING', 'RUNNING')
                ),
                FALSE
            ) AS has_active,

            /*
             * Trạng thái của active attempt.
             */
            MAX(bt.status)
                FILTER (
                    WHERE bt.status IN ('PENDING', 'RUNNING')
                ) AS active_status,

            /*
             * Thời điểm bắt đầu active attempt.
             */
            MAX(bt.started_at)
                FILTER (
                    WHERE bt.status IN ('PENDING', 'RUNNING')
                ) AS active_started_at,

            /*
             * Trạng thái attempt cuối cùng.
             */
            (
                ARRAY_AGG(
                    bt.status
                    ORDER BY bt.attempt_no DESC
                )
            )[1] AS last_status

        FROM control.workflow_task wt

        JOIN control.task_definition td
          ON td.task_code = wt.task_code

        LEFT JOIN control.batch_task bt
          ON bt.batch_id = p_batch_id
         AND bt.task_code = wt.task_code

        WHERE wt.workflow_code = p_workflow_code
          AND wt.is_enabled = TRUE
          AND td.is_enabled = TRUE
          AND td.is_observable = TRUE

        GROUP BY
            wt.workflow_task_id,
            wt.task_code,
            wt.execution_order,
            wt.execution_type,
            wt.execution_ref,
            td.retryable,
            td.max_retry_count
    ),


    /*
     * ============================================================
     * 4. Task đang active
     *
     * Nếu tồn tại:
     *
     *     STAGE = RUNNING
     *
     * thì dispatcher phải WAIT.
     *
     * Không được lấy task tiếp theo.
     * ============================================================
     */
    active_task AS (

        SELECT
            ts.*
        FROM task_state ts

        WHERE ts.has_active = TRUE

        ORDER BY
            ts.execution_order

        LIMIT 1
    ),


    /*
     * ============================================================
     * 5. Task tiếp theo có thể RUN
     *
     * Chỉ xét khi task chưa SUCCESS và không active.
     * ============================================================
     */
    next_task AS (

        SELECT
            ts.*
        FROM task_state ts

        WHERE ts.has_success = FALSE

          /*
           * Không chạy song song trong workflow này.
           */
          AND ts.has_active = FALSE

          AND (
                /*
                 * Task chưa từng chạy.
                 */
                ts.attempt_count = 0

                OR

                /*
                 * Task FAILED/CANCELLED và còn retry.
                 *
                 * max_retry_count là số lần retry
                 * sau attempt đầu tiên.
                 */
                (
                    ts.last_status IN (
                        'FAILED',
                        'CANCELLED'
                    )
                    AND ts.retryable = TRUE
                    AND ts.attempt_count <= ts.max_retry_count
                )
              )

        ORDER BY
            ts.execution_order

        LIMIT 1
    ),


    /*
     * ============================================================
     * 6. Task FAILED nhưng đã hết retry
     *
     * Đây là trạng thái workflow FAILED.
     * ============================================================
     */
    failed_task AS (

        SELECT
            ts.*
        FROM task_state ts

        WHERE ts.has_success = FALSE
          AND ts.has_active = FALSE

          AND ts.last_status IN (
              'FAILED',
              'CANCELLED'
          )

          AND (
                ts.retryable = FALSE
                OR ts.attempt_count > ts.max_retry_count
              )

        ORDER BY
            ts.execution_order

        LIMIT 1
    ),


    /*
     * ============================================================
     * 7. Kiểm tra workflow đã hoàn tất hay chưa.
     *
     * COMPLETE khi:
     *
     *     không còn active
     *     không còn failed task
     *     không còn task cần chạy
     *
     * Và phải có ít nhất một observable task.
     * ============================================================
     */
    workflow_complete AS (

        SELECT
            COUNT(*) > 0
            AND BOOL_AND(
                ts.has_success = TRUE
            ) AS is_complete

        FROM task_state ts
    )


    /*
     * ============================================================
     * 8. Dispatch result
     *
     * Priority:
     *
     *     ACTIVE  → WAIT
     *     FAILED  → FAILED
     *     NEXT    → RUN
     *     ALL OK  → COMPLETE
     * ============================================================
     */

    /*
     * ------------------------------------------------------------
     * CASE 1: Có task đang chạy
     * ------------------------------------------------------------
     */
    SELECT
        p_batch_id,
        p_workflow_code,

        at.workflow_task_id,
        at.task_code,
        at.execution_order,
        at.execution_type,
        at.execution_ref,

        at.retryable,
        at.max_retry_count,

        at.last_attempt_no AS next_attempt_no,

        at.active_status AS task_status,

        'WAIT'::VARCHAR(20) AS dispatch_status,

        at.active_started_at AS started_at

    FROM active_task at


    UNION ALL


    /*
     * ------------------------------------------------------------
     * CASE 2: Có task FAILED hết retry
     * ------------------------------------------------------------
     */
    SELECT
        p_batch_id,
        p_workflow_code,

        ft.workflow_task_id,
        ft.task_code,
        ft.execution_order,
        ft.execution_type,
        ft.execution_ref,

        ft.retryable,
        ft.max_retry_count,

        ft.last_attempt_no AS next_attempt_no,

        ft.last_status AS task_status,

        'FAILED'::VARCHAR(20) AS dispatch_status,

        NULL::TIMESTAMPTZ AS started_at

    FROM failed_task ft

    WHERE NOT EXISTS (
        SELECT 1
        FROM active_task
    )


    UNION ALL


    /*
     * ------------------------------------------------------------
     * CASE 3: Có task tiếp theo cần chạy
     * ------------------------------------------------------------
     */
    SELECT
        p_batch_id,
        p_workflow_code,

        nt.workflow_task_id,
        nt.task_code,
        nt.execution_order,
        nt.execution_type,
        nt.execution_ref,

        nt.retryable,
        nt.max_retry_count,

        COALESCE(
            nt.last_attempt_no,
            0
        ) + 1 AS next_attempt_no,

        NULL::control.execution_status AS task_status,

        'RUN'::VARCHAR(20) AS dispatch_status,

        NULL::TIMESTAMPTZ AS started_at

    FROM next_task nt

    WHERE NOT EXISTS (
        SELECT 1
        FROM active_task
    )

      AND NOT EXISTS (
          SELECT 1
          FROM failed_task
      )


    UNION ALL


    /*
     * ------------------------------------------------------------
     * CASE 4: Workflow COMPLETE
     * ------------------------------------------------------------
     */
    SELECT
        p_batch_id,
        p_workflow_code,

        NULL::BIGINT AS workflow_task_id,
        NULL::VARCHAR(100) AS task_code,
        NULL::INTEGER AS execution_order,
        NULL::VARCHAR(30) AS execution_type,
        NULL::VARCHAR(256) AS execution_ref,

        NULL::BOOLEAN AS retryable,
        NULL::INTEGER AS max_retry_count,

        NULL::INTEGER AS next_attempt_no,

        NULL::control.execution_status AS task_status,

        'COMPLETE'::VARCHAR(20) AS dispatch_status,

        NULL::TIMESTAMPTZ AS started_at

    FROM workflow_complete wc

    WHERE wc.is_complete = TRUE

      AND NOT EXISTS (
          SELECT 1
          FROM active_task
      )

      AND NOT EXISTS (
          SELECT 1
          FROM failed_task
      )

      AND NOT EXISTS (
          SELECT 1
          FROM next_task
      );

END;
$$;

BEGIN;

CREATE TABLE control.processing_run_task (
    processing_run_task_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    processing_run_id      BIGINT NOT NULL,

    task_code              VARCHAR(50) NOT NULL,

    execution_order        INTEGER NOT NULL,

    status                 control.execution_status
                           NOT NULL DEFAULT 'PENDING',

    attempt_no             INTEGER NOT NULL DEFAULT 1,

    started_at             TIMESTAMPTZ,

    completed_at           TIMESTAMPTZ,

    source_row_count       BIGINT,

    accepted_row_count     BIGINT,

    rejected_row_count     BIGINT,

    error_count            BIGINT NOT NULL DEFAULT 0,

    hop_run_id             VARCHAR(200),

    error_code             VARCHAR(100),

    error_message          TEXT,

    created_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_processing_run_task_run
        FOREIGN KEY (processing_run_id)
        REFERENCES control.processing_run (processing_run_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_processing_run_task_definition
        FOREIGN KEY (task_code)
        REFERENCES control.task_definition (task_code)
        ON DELETE RESTRICT,

    CONSTRAINT uq_processing_run_task_attempt
        UNIQUE (
            processing_run_id,
            task_code,
            attempt_no
        ),

    CONSTRAINT ck_processing_run_task_execution_order
        CHECK (
            execution_order > 0
        ),

    CONSTRAINT ck_processing_run_task_attempt
        CHECK (
            attempt_no > 0
        ),

    CONSTRAINT ck_processing_run_task_completed_at
        CHECK (
            completed_at IS NULL
            OR started_at IS NULL
            OR completed_at >= started_at
        ),

    CONSTRAINT ck_processing_run_task_source_row_count
        CHECK (
            source_row_count IS NULL
            OR source_row_count >= 0
        ),

    CONSTRAINT ck_processing_run_task_accepted_row_count
        CHECK (
            accepted_row_count IS NULL
            OR accepted_row_count >= 0
        ),

    CONSTRAINT ck_processing_run_task_rejected_row_count
        CHECK (
            rejected_row_count IS NULL
            OR rejected_row_count >= 0
        ),

    CONSTRAINT ck_processing_run_task_error_count
        CHECK (
            error_count >= 0
        )
);

CREATE INDEX ix_processing_run_task_run
    ON control.processing_run_task (processing_run_id);

CREATE INDEX ix_processing_run_task_task
    ON control.processing_run_task (task_code);

CREATE INDEX ix_processing_run_task_status
    ON control.processing_run_task (status);

CREATE INDEX ix_processing_run_task_running
    ON control.processing_run_task (
        status,
        started_at
    )
    WHERE status = 'RUNNING';

CREATE UNIQUE INDEX uq_processing_run_task_active_attempt
    ON control.processing_run_task (
        processing_run_id,
        task_code
    )
    WHERE status IN ('PENDING', 'RUNNING');

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.processing_run_task
TO hospital_ods_etl;

GRANT SELECT
ON control.processing_run_task
TO hospital_ods_app;

COMMIT;

BEGIN;

CREATE TYPE control.execution_status AS ENUM (
    'PENDING',
    'RUNNING',
    'SUCCESS',
    'PARTIAL',
    'FAILED',
    'CANCELLED',
    'SKIPPED'
);

CREATE TABLE control.batch_task (
    batch_task_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    batch_id               BIGINT NOT NULL,
    dataset_mapping_id     BIGINT,
    workflow_task_id 	   BIGINT,
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

    CONSTRAINT fk_batch_task_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch (batch_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_batch_task_dataset_mapping
        FOREIGN KEY (dataset_mapping_id)
        REFERENCES control.dataset_mapping (dataset_mapping_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_batch_task_workflow_task
	FOREIGN KEY (workflow_task_id)
	REFERENCES control.workflow_task(workflow_task_id)
	ON DELETE RESTRICT;

    CONSTRAINT fk_batch_task_task
        FOREIGN KEY (task_code)
        REFERENCES control.task_definition (task_code)
        ON DELETE RESTRICT,

    CONSTRAINT uq_batch_task_attempt
        UNIQUE (
            batch_id,
            task_code,
            attempt_no
        ),

    CONSTRAINT ck_batch_task_execution_order
        CHECK (
            execution_order > 0
        ),

    CONSTRAINT ck_batch_task_attempt
        CHECK (
            attempt_no > 0
        ),

    CONSTRAINT ck_batch_task_completed_at
        CHECK (
            completed_at IS NULL
            OR started_at IS NULL
            OR completed_at >= started_at
        ),

    CONSTRAINT ck_batch_task_source_row_count
        CHECK (
            source_row_count IS NULL
            OR source_row_count >= 0
        ),

    CONSTRAINT ck_batch_task_accepted_row_count
        CHECK (
            accepted_row_count IS NULL
            OR accepted_row_count >= 0
        ),

    CONSTRAINT ck_batch_task_rejected_row_count
        CHECK (
            rejected_row_count IS NULL
            OR rejected_row_count >= 0
        ),

    CONSTRAINT ck_batch_task_error_count
        CHECK (
            error_count >= 0
        )
);

COMMENT ON TABLE control.batch_task IS
    'Runtime execution state of logical tasks belonging to a RAW ingestion batch.';

COMMENT ON COLUMN control.batch_task.batch_id IS
    'ODS batch containing this task execution.';

COMMENT ON COLUMN control.batch_task.dataset_mapping_id IS
    'Dataset mapping context associated with the task. NULL is allowed for control-level tasks such as CONTEXT or RECONCILE.';

COMMENT ON COLUMN control.batch_task.task_code IS
    'Logical task referenced from control.task_definition.';

COMMENT ON COLUMN control.batch_task.execution_order IS
    'Snapshot of the logical execution order of the task within the batch.';

COMMENT ON COLUMN control.batch_task.status IS
    'Operational lifecycle state of the task execution.';

COMMENT ON COLUMN control.batch_task.attempt_no IS
    'Execution attempt number. A retry creates a new attempt while preserving previous attempt history.';

COMMENT ON COLUMN control.batch_task.hop_run_id IS
    'Apache Hop execution identifier associated with this task attempt, when available.';

CREATE INDEX ix_batch_task_batch
    ON control.batch_task (batch_id);

CREATE INDEX ix_batch_task_task
    ON control.batch_task (task_code);

CREATE INDEX ix_batch_task_status
    ON control.batch_task (status);

CREATE INDEX ix_batch_task_dataset_mapping
    ON control.batch_task (dataset_mapping_id);

CREATE INDEX ix_batch_task_running
    ON control.batch_task (status, started_at)
    WHERE status = 'RUNNING';

CREATE UNIQUE INDEX uq_batch_task_active_attempt
    ON control.batch_task (
        batch_id,
        task_code
    )
    WHERE status IN ('PENDING', 'RUNNING');

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.batch_task
TO hospital_ods_etl;

GRANT SELECT
ON control.batch_task
TO hospital_ods_app;

COMMIT;

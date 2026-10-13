BEGIN;

CREATE TABLE control.task_definition (
    task_code              VARCHAR(50) PRIMARY KEY,

    task_name              VARCHAR(255) NOT NULL,
    layer_code             VARCHAR(30) NOT NULL,
    task_group             VARCHAR(50) NOT NULL,

    description            TEXT,

    is_enabled             BOOLEAN NOT NULL DEFAULT TRUE,
    is_observable          BOOLEAN NOT NULL DEFAULT TRUE,

    retryable              BOOLEAN NOT NULL DEFAULT TRUE,
    max_retry_count        INTEGER NOT NULL DEFAULT 3,

    timeout_seconds        INTEGER,

    created_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_task_definition_layer
        CHECK (
            layer_code IN (
                'CONTROL',
                'RAW',
                'IDENTITY',
                'CANONICAL',
                'FACT',
                'DIM'
            )
        ),

    CONSTRAINT ck_task_definition_group
        CHECK (
            task_group IN (
                'CONTEXT',
                'PREPARATION',
                'DATA_MOVEMENT',
                'VALIDATION',
                'RECONCILE',
                'FINALIZATION'
            )
        ),

    CONSTRAINT ck_task_definition_max_retry
        CHECK (
            max_retry_count >= 0
        ),

    CONSTRAINT ck_task_definition_timeout
        CHECK (
            timeout_seconds IS NULL
            OR timeout_seconds > 0
        )
);

COMMENT ON TABLE control.task_definition IS
    'Metadata catalog defining logical ODS tasks. This table contains task definition and default execution policy, not runtime execution state.';

COMMENT ON COLUMN control.task_definition.task_code IS
    'Stable logical identifier of the task. Used as the technical contract across workflow and runtime execution.';

COMMENT ON COLUMN control.task_definition.task_name IS
    'Human-readable name of the task.';

COMMENT ON COLUMN control.task_definition.layer_code IS
    'Data platform layer primarily affected by the task: CONTROL, RAW, IDENTITY, CANONICAL, FACT or DIM.';

COMMENT ON COLUMN control.task_definition.task_group IS
    'Execution category of the task.';

COMMENT ON COLUMN control.task_definition.is_enabled IS
    'Whether the task definition is allowed to be used by new workflow executions.';

COMMENT ON COLUMN control.task_definition.is_observable IS
    'Whether executions of this task should be exposed as an observable operational task.';

COMMENT ON COLUMN control.task_definition.retryable IS
    'Default policy indicating whether the task may be retried after failure.';

COMMENT ON COLUMN control.task_definition.max_retry_count IS
    'Default maximum number of retry attempts allowed for the task.';

COMMENT ON COLUMN control.task_definition.timeout_seconds IS
    'Default execution timeout in seconds. NULL means no task-level timeout is defined.';

CREATE INDEX ix_task_definition_layer
    ON control.task_definition (layer_code);

CREATE INDEX ix_task_definition_enabled
    ON control.task_definition (is_enabled)
    WHERE is_enabled = TRUE;

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.task_definition
TO hospital_ods_etl;

GRANT SELECT
ON control.task_definition
TO hospital_ods_app;

COMMIT;

BEGIN;

CREATE TYPE control.processing_run_status AS ENUM (
    'PENDING',
    'RUNNING',
    'SUCCESS',
    'PARTIAL',
    'FAILED',
    'CANCELLED'
);

CREATE TABLE control.processing_run (
    processing_run_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    workflow_code          VARCHAR(50) NOT NULL,

    layer_code             VARCHAR(30) NOT NULL,

    status                 control.processing_run_status
                           NOT NULL DEFAULT 'PENDING',

    started_at             TIMESTAMPTZ,

    completed_at           TIMESTAMPTZ,

    hop_run_id             VARCHAR(200),

    error_code             VARCHAR(100),

    error_message          TEXT,

    created_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_processing_run_layer
        CHECK (
            layer_code IN (
                'IDENTITY',
                'CANONICAL',
                'FACT',
                'DIM'
            )
        ),

    CONSTRAINT ck_processing_run_completed_at
        CHECK (
            completed_at IS NULL
            OR started_at IS NULL
            OR completed_at >= started_at
        )
);

CREATE INDEX ix_processing_run_workflow
    ON control.processing_run (workflow_code);

CREATE INDEX ix_processing_run_layer
    ON control.processing_run (layer_code);

CREATE INDEX ix_processing_run_status
    ON control.processing_run (status);

CREATE INDEX ix_processing_run_running
    ON control.processing_run (
        status,
        started_at
    )
    WHERE status = 'RUNNING';

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.processing_run
TO hospital_ods_etl;

GRANT SELECT
ON control.processing_run
TO hospital_ods_app;

COMMIT;

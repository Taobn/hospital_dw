BEGIN;

CREATE TYPE control.processing_run_input_type AS ENUM (
    'BATCH',
    'PROCESSING_RUN'
);

CREATE TABLE control.processing_run_input (
    processing_run_input_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    processing_run_id          BIGINT NOT NULL,

    input_type                 control.processing_run_input_type NOT NULL,

    batch_id                   BIGINT,

    upstream_processing_run_id BIGINT,

    input_role                 VARCHAR(50),

    created_at                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_processing_run_input_run
        FOREIGN KEY (processing_run_id)
        REFERENCES control.processing_run (processing_run_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_processing_run_input_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch (batch_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_processing_run_input_upstream_run
        FOREIGN KEY (upstream_processing_run_id)
        REFERENCES control.processing_run (processing_run_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_processing_run_input_reference
        CHECK (
            (
                input_type = 'BATCH'
                AND batch_id IS NOT NULL
                AND upstream_processing_run_id IS NULL
            )
            OR
            (
                input_type = 'PROCESSING_RUN'
                AND batch_id IS NULL
                AND upstream_processing_run_id IS NOT NULL
            )
        ),

    CONSTRAINT uq_processing_run_input_batch
        UNIQUE (
            processing_run_id,
            batch_id
        ),

    CONSTRAINT uq_processing_run_input_upstream
        UNIQUE (
            processing_run_id,
            upstream_processing_run_id
        )
);

CREATE INDEX ix_processing_run_input_run
    ON control.processing_run_input (processing_run_id);

CREATE INDEX ix_processing_run_input_batch
    ON control.processing_run_input (batch_id)
    WHERE batch_id IS NOT NULL;

CREATE INDEX ix_processing_run_input_upstream
    ON control.processing_run_input (upstream_processing_run_id)
    WHERE upstream_processing_run_id IS NOT NULL;

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.processing_run_input
TO hospital_ods_etl;

GRANT SELECT
ON control.processing_run_input
TO hospital_ods_app;

COMMIT;

BEGIN;

CREATE TABLE control.batch (
    batch_id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    dataset_id               BIGINT NOT NULL,

    batch_code               VARCHAR(100) NOT NULL,

    processing_date          DATE NOT NULL,

    started_at               TIMESTAMPTZ NOT NULL,
    completed_at             TIMESTAMPTZ,

    status                   VARCHAR(20) NOT NULL DEFAULT 'RUNNING',

    source_row_count         BIGINT,
    accepted_row_count       BIGINT,
    rejected_row_count       BIGINT,

    error_count              INTEGER NOT NULL DEFAULT 0,

    hop_run_id               VARCHAR(200),

    error_message            TEXT,

    created_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_batch_dataset
        FOREIGN KEY (dataset_id)
        REFERENCES control.dataset (dataset_id),

    CONSTRAINT uq_batch_code
        UNIQUE (batch_code),

    CONSTRAINT ck_batch_status
        CHECK (
            status IN (
                'RUNNING',
                'SUCCESS',
                'PARTIAL',
                'FAILED',
                'CANCELLED'
            )
        ),

    CONSTRAINT ck_batch_completed_at
        CHECK (
            completed_at IS NULL
            OR completed_at >= started_at
        ),

    CONSTRAINT ck_batch_source_row_count
        CHECK (
            source_row_count IS NULL
            OR source_row_count >= 0
        ),

    CONSTRAINT ck_batch_accepted_row_count
        CHECK (
            accepted_row_count IS NULL
            OR accepted_row_count >= 0
        ),

    CONSTRAINT ck_batch_rejected_row_count
        CHECK (
            rejected_row_count IS NULL
            OR rejected_row_count >= 0
        ),

    CONSTRAINT ck_batch_error_count
        CHECK (
            error_count >= 0
        )
);

COMMENT ON TABLE control.batch IS
    'ODS-level processing boundary for one dataset execution. Detailed orchestration and runtime execution logs remain in Apache Hop.';

COMMENT ON COLUMN control.batch.dataset_id IS
    'Logical dataset processed by this batch.';

COMMENT ON COLUMN control.batch.batch_code IS
    'Stable unique identifier for an ODS processing batch.';

COMMENT ON COLUMN control.batch.processing_date IS
    'ODS processing date of the batch execution. This is not the source business date.';

COMMENT ON COLUMN control.batch.status IS
    'ODS processing result. Detailed task state remains in Apache Hop.';

COMMENT ON COLUMN control.batch.hop_run_id IS
    'Optional correlation identifier linking this ODS batch to an Apache Hop execution.';

COMMENT ON COLUMN control.batch.source_row_count IS
    'Number of rows observed from the source during this batch.';

COMMENT ON COLUMN control.batch.accepted_row_count IS
    'Number of rows successfully accepted into the target processing flow.';

COMMENT ON COLUMN control.batch.rejected_row_count IS
    'Number of rows rejected by ingestion or validation.';

CREATE INDEX ix_batch_dataset
    ON control.batch (dataset_id);

CREATE INDEX ix_batch_processing_date
    ON control.batch (processing_date);

CREATE INDEX ix_batch_status
    ON control.batch (status);

CREATE INDEX ix_batch_dataset_date
    ON control.batch (dataset_id, processing_date DESC);

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.batch
TO hospital_ods_etl;

GRANT USAGE, SELECT
ON SEQUENCE control.batch_batch_id_seq
TO hospital_ods_etl;

GRANT SELECT
ON control.batch
TO hospital_ods_app;

COMMIT;

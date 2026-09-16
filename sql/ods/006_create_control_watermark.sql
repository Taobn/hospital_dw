BEGIN;

CREATE TABLE control.watermark (
    watermark_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    dataset_id              BIGINT NOT NULL,

    watermark_type          VARCHAR(30) NOT NULL,

    watermark_column        VARCHAR(128),

    last_value_text         TEXT,

    last_value_timestamp    TIMESTAMPTZ,

    last_value_numeric      NUMERIC,

    last_batch_id            BIGINT,

    initialized_at           TIMESTAMPTZ,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    is_active                BOOLEAN NOT NULL DEFAULT TRUE,

    description              TEXT,

    created_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_watermark_dataset
        FOREIGN KEY (dataset_id)
        REFERENCES control.dataset (dataset_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_watermark_batch
        FOREIGN KEY (last_batch_id)
        REFERENCES control.batch (batch_id),

    CONSTRAINT uq_watermark_dataset
        UNIQUE (dataset_id),

    CONSTRAINT ck_watermark_type
        CHECK (
            watermark_type IN (
                'TIMESTAMP',
                'NUMERIC',
                'TEXT',
                'COMPOSITE'
            )
        ),

    CONSTRAINT ck_watermark_column
        CHECK (
            watermark_type = 'COMPOSITE'
            OR watermark_column IS NOT NULL
        ),

    CONSTRAINT ck_watermark_value
        CHECK (
            (
                watermark_type = 'TIMESTAMP'
                AND last_value_timestamp IS NOT NULL
                AND last_value_numeric IS NULL
                AND last_value_text IS NULL
            )
            OR
            (
                watermark_type = 'NUMERIC'
                AND last_value_numeric IS NOT NULL
                AND last_value_timestamp IS NULL
                AND last_value_text IS NULL
            )
            OR
            (
                watermark_type = 'TEXT'
                AND last_value_text IS NOT NULL
                AND last_value_timestamp IS NULL
                AND last_value_numeric IS NULL
            )
            OR
            (
                watermark_type = 'COMPOSITE'
            )
            OR
            (
                last_value_text IS NULL
                AND last_value_timestamp IS NULL
                AND last_value_numeric IS NULL
            )
        )
);

COMMENT ON TABLE control.watermark IS
    'Current incremental extraction state for a logical dataset. Apache Hop uses this state during incremental ingestion; detailed execution state remains in Hop.';

COMMENT ON COLUMN control.watermark.dataset_id IS
    'Logical dataset whose incremental extraction state is maintained.';

COMMENT ON COLUMN control.watermark.watermark_type IS
    'Type of incremental cursor: TIMESTAMP, NUMERIC, TEXT or COMPOSITE.';

COMMENT ON COLUMN control.watermark.watermark_column IS
    'Source column or logical cursor expression used for the watermark.';

COMMENT ON COLUMN control.watermark.last_value_text IS
    'Last processed textual watermark value when watermark_type is TEXT.';

COMMENT ON COLUMN control.watermark.last_value_timestamp IS
    'Last processed timestamp watermark value when watermark_type is TIMESTAMP.';

COMMENT ON COLUMN control.watermark.last_value_numeric IS
    'Last processed numeric watermark value when watermark_type is NUMERIC.';

COMMENT ON COLUMN control.watermark.last_batch_id IS
    'ODS batch that most recently advanced this watermark.';

COMMENT ON COLUMN control.watermark.initialized_at IS
    'Timestamp when the watermark was first initialized.';

CREATE INDEX ix_watermark_active
    ON control.watermark (is_active);

CREATE INDEX ix_watermark_batch
    ON control.watermark (last_batch_id);

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.watermark
TO hospital_ods_etl;

GRANT SELECT
ON control.watermark
TO hospital_ods_app;

COMMIT;

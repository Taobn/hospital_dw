BEGIN;

CREATE TABLE control.dataset (
    dataset_id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_instance_id          BIGINT NOT NULL,

    dataset_code                VARCHAR(100) NOT NULL,
    dataset_name                VARCHAR(200) NOT NULL,

    description                 TEXT,

    resource_type               VARCHAR(30) NOT NULL,

    source_schema               VARCHAR(128),
    source_object               VARCHAR(256),

    refresh_mode                VARCHAR(20) NOT NULL,

    ingestion_config            JSONB,

    source_schema_version       VARCHAR(50),

    expected_latency_minutes    INTEGER,

    is_active                   BOOLEAN NOT NULL DEFAULT TRUE,

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dataset_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance (source_instance_id),

    CONSTRAINT uq_dataset_code
        UNIQUE (dataset_code),

    CONSTRAINT ck_dataset_resource_type
        CHECK (
            resource_type IN (
                'TABLE',
                'VIEW',
                'SQL',
                'STORED_PROC',
                'API',
                'FILE',
                'STREAM'
            )
        ),

    CONSTRAINT ck_dataset_refresh_mode
        CHECK (
            refresh_mode IN (
                'FULL',
                'INCREMENTAL',
                'CDC',
                'SNAPSHOT',
                'APPEND'
            )
        ),

    CONSTRAINT ck_dataset_expected_latency
        CHECK (
            expected_latency_minutes IS NULL
            OR expected_latency_minutes >= 0
        )
);

COMMENT ON TABLE control.dataset IS
    'Logical ODS dataset/data asset. Describes what data is ingested; Apache Hop owns physical connections, pipelines, workflows and schedules.';

COMMENT ON COLUMN control.dataset.source_instance_id IS
    'Logical source system providing this dataset.';

COMMENT ON COLUMN control.dataset.dataset_code IS
    'Stable logical identifier of the dataset, e.g. HIS_EXAM, HIS_ADMISSION, HIS_SERVICE.';

COMMENT ON COLUMN control.dataset.resource_type IS
    'Logical source resource type. Physical connection details are managed by Apache Hop.';

COMMENT ON COLUMN control.dataset.source_schema IS
    'Source-side schema/owner when applicable, for example an Oracle schema.';

COMMENT ON COLUMN control.dataset.source_object IS
    'Source-side table, view, procedure or logical object when applicable.';

COMMENT ON COLUMN control.dataset.refresh_mode IS
    'Expected ingestion semantics for this dataset.';

COMMENT ON COLUMN control.dataset.ingestion_config IS
    'Dataset-specific ingestion configuration that is not part of the common relational contract.';

COMMENT ON COLUMN control.dataset.source_schema_version IS
    'Business/source structure version when explicitly known. This is not a pipeline version.';

COMMENT ON COLUMN control.dataset.expected_latency_minutes IS
    'Expected maximum freshness latency in minutes for operational monitoring.';

CREATE INDEX ix_dataset_source_instance
    ON control.dataset (source_instance_id);

CREATE INDEX ix_dataset_active
    ON control.dataset (is_active);

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.dataset
TO hospital_ods_etl;

GRANT SELECT
ON control.dataset
TO hospital_ods_app;

COMMIT;

BEGIN;

-- ============================================================
-- 1. Controlled vocabularies
-- ============================================================

CREATE TYPE control.dataset_type_enum AS ENUM (
    'MASTER',
    'REFERENCE',
    'EVENT',
    'TRANSACTION',
    'SNAPSHOT',
    'DOCUMENT',
    'BRIDGE'
);

CREATE TYPE control.resource_type_enum AS ENUM (
    'TABLE',
    'VIEW',
    'SQL',
    'STORED_PROC',
    'API',
    'FILE',
    'STREAM'
);

CREATE TYPE control.refresh_mode_enum AS ENUM (
    'FULL',
    'INCREMENTAL',
    'CDC',
    'SNAPSHOT',
    'APPEND'
);


-- ============================================================
-- 2. Dataset
-- ============================================================

CREATE TABLE control.dataset (
    dataset_id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_instance_id          BIGINT NOT NULL,

    dataset_code                VARCHAR(100) NOT NULL,
    dataset_name                VARCHAR(200) NOT NULL,

    description                 TEXT,

    dataset_type                control.dataset_type_enum NOT NULL,

    resource_type               control.resource_type_enum NOT NULL,

    source_schema               VARCHAR(128),
    source_object               VARCHAR(256),

    refresh_mode                control.refresh_mode_enum NOT NULL,

    ingestion_config            JSONB,

    source_schema_version       VARCHAR(50),

    expected_latency_minutes    INTEGER,

    execution_order             INTEGER NOT NULL DEFAULT 100,

    parallel_group              VARCHAR(50),

    is_active                   BOOLEAN NOT NULL DEFAULT TRUE,

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,


    -- ========================================================
    -- Foreign key
    -- ========================================================

    CONSTRAINT fk_dataset_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance (source_instance_id),


    -- ========================================================
    -- Business key
    -- ========================================================

    CONSTRAINT uq_dataset_source_code
        UNIQUE (
            source_instance_id,
            dataset_code
        ),


    -- ========================================================
    -- Dataset code
    -- ========================================================

    CONSTRAINT ck_dataset_code
        CHECK (
            dataset_code = UPPER(dataset_code)
            AND BTRIM(dataset_code) <> ''
        ),


    -- ========================================================
    -- Expected latency
    -- ========================================================

    CONSTRAINT ck_dataset_expected_latency
        CHECK (
            expected_latency_minutes IS NULL
            OR expected_latency_minutes >= 0
        ),


    -- ========================================================
    -- Execution order
    -- ========================================================

    CONSTRAINT ck_dataset_execution_order
        CHECK (
            execution_order > 0
        ),


    -- ========================================================
    -- Parallel group
    -- ========================================================

    CONSTRAINT ck_dataset_parallel_group
        CHECK (
            parallel_group IS NULL
            OR BTRIM(parallel_group) <> ''
        ),


    -- ========================================================
    -- Source location
    -- ========================================================

    CONSTRAINT ck_dataset_source_location
        CHECK (
            (
                resource_type IN (
                    'TABLE',
                    'VIEW',
                    'SQL',
                    'STORED_PROC'
                )
                AND source_object IS NOT NULL
            )
            OR
            (
                resource_type IN (
                    'API',
                    'FILE',
                    'STREAM'
                )
            )
        )
);


-- ============================================================
-- 3. Comments
-- ============================================================

COMMENT ON TABLE control.dataset IS
    'Logical ODS dataset/data asset. Describes what data is ingested, its source resource, ingestion semantics and execution hints. Apache Hop owns physical connections, pipelines, workflows and schedules.';

COMMENT ON COLUMN control.dataset.source_instance_id IS
    'Source database or system instance providing this dataset.';

COMMENT ON COLUMN control.dataset.dataset_code IS
    'Stable logical identifier of the dataset, for example HIS_PATIENT, HIS_EXAM or HIS_SERVICE.';

COMMENT ON COLUMN control.dataset.dataset_type IS
    'Semantic dataset classification: MASTER, REFERENCE, EVENT, TRANSACTION, SNAPSHOT, DOCUMENT or BRIDGE.';

COMMENT ON COLUMN control.dataset.resource_type IS
    'Source resource type: TABLE, VIEW, SQL, STORED_PROC, API, FILE or STREAM.';

COMMENT ON COLUMN control.dataset.source_schema IS
    'Source-side schema or owner when applicable, for example an Oracle schema.';

COMMENT ON COLUMN control.dataset.source_object IS
    'Source-side table, view, procedure or logical object when applicable.';

COMMENT ON COLUMN control.dataset.refresh_mode IS
    'High-level ingestion semantics: FULL, INCREMENTAL, CDC, SNAPSHOT or APPEND. Technical ingestion strategy is defined in ingestion_config.';

COMMENT ON COLUMN control.dataset.ingestion_config IS
    'Dataset-specific ingestion configuration that is not part of the common relational contract.';

COMMENT ON COLUMN control.dataset.source_schema_version IS
    'Source structure version when explicitly known. This is not an Apache Hop pipeline or workflow version.';

COMMENT ON COLUMN control.dataset.expected_latency_minutes IS
    'Expected maximum freshness latency in minutes for operational monitoring.';

COMMENT ON COLUMN control.dataset.execution_order IS
    'Execution priority hint for dataset orchestration. Lower values indicate earlier processing. This does not replace dependency resolution and duplicate values are allowed.';

COMMENT ON COLUMN control.dataset.parallel_group IS
    'Execution grouping hint for datasets that may be considered for parallel execution. It does not create a dependency or guarantee parallel execution.';


-- ============================================================
-- 4. Indexes
-- ============================================================

CREATE INDEX ix_dataset_source_instance
    ON control.dataset (
        source_instance_id
    );

CREATE INDEX ix_dataset_execution
    ON control.dataset (
        is_active,
        execution_order,
        parallel_group
    );

CREATE INDEX ix_dataset_active_source
    ON control.dataset (
        source_instance_id,
        dataset_code
    )
    WHERE is_active = TRUE;


-- ============================================================
-- 5. Grants
-- ============================================================

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.dataset
TO hospital_ods_etl;

GRANT SELECT
ON control.dataset
TO hospital_ods_app;

COMMIT;

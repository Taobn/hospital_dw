BEGIN;

CREATE TABLE control.dataset_column_mapping (
    dataset_column_mapping_id
        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    dataset_id
        BIGINT NOT NULL,

    source_field_name
        VARCHAR(128) NOT NULL,

    target_layer
        VARCHAR(20) NOT NULL,

    target_schema
        VARCHAR(128) NOT NULL,

    target_object
        VARCHAR(256) NOT NULL,

    target_field_name
        VARCHAR(128) NOT NULL,

    source_data_type
        VARCHAR(128),

    target_data_type
        VARCHAR(128),

    mapping_expression
        TEXT,

    mapping_role
        VARCHAR(30) NOT NULL DEFAULT 'DIRECT',

    ordinal_position
        INTEGER,

    is_nullable
        BOOLEAN,

    is_active
        BOOLEAN NOT NULL DEFAULT TRUE,

    description
        TEXT,

    created_at
        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at
        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dataset_column_mapping_dataset
        FOREIGN KEY (dataset_id)
        REFERENCES control.dataset (dataset_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_dataset_column_mapping
        UNIQUE (
            dataset_id,
            target_layer,
            target_schema,
            target_object,
            source_field_name,
            target_field_name
        ),

    CONSTRAINT ck_dataset_column_mapping_layer
        CHECK (
            target_layer IN (
                'RAW',
                'IDENTITY',
                'CANONICAL',
                'DORIS'
            )
        ),

    CONSTRAINT ck_dataset_column_mapping_role
        CHECK (
            mapping_role IN (
                'DIRECT',
                'CAST',
                'TRANSFORM',
                'DERIVED',
                'CONSTANT'
            )
        ),

    CONSTRAINT ck_dataset_column_mapping_ordinal
        CHECK (
            ordinal_position IS NULL
            OR ordinal_position > 0
        )
);

COMMENT ON TABLE control.dataset_column_mapping IS
    'Column-level metadata mapping source dataset fields to target physical fields. Stores source-to-target lineage and transformation metadata; it is not Apache Hop orchestration metadata.';

COMMENT ON COLUMN control.dataset_column_mapping.source_field_name IS
    'Original source column name as defined by the source system.';

COMMENT ON COLUMN control.dataset_column_mapping.target_field_name IS
    'Target physical column name in the ODS/DWH layer.';

COMMENT ON COLUMN control.dataset_column_mapping.mapping_expression IS
    'Optional transformation expression or rule applied during ingestion.';

COMMENT ON COLUMN control.dataset_column_mapping.mapping_role IS
    'Column mapping behavior: DIRECT, CAST, TRANSFORM, DERIVED, or CONSTANT.';

COMMENT ON COLUMN control.dataset_column_mapping.ordinal_position IS
    'Source/target column ordinal position used for deterministic mapping documentation.';

CREATE INDEX ix_dataset_column_mapping_dataset
    ON control.dataset_column_mapping (
        dataset_id
    );

CREATE INDEX ix_dataset_column_mapping_target
    ON control.dataset_column_mapping (
        target_layer,
        target_schema,
        target_object
    );

CREATE INDEX ix_dataset_column_mapping_source
    ON control.dataset_column_mapping (
        dataset_id,
        source_field_name
    );

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.dataset_column_mapping
TO hospital_ods_etl;

GRANT SELECT
ON control.dataset_column_mapping
TO hospital_ods_app;

COMMIT;

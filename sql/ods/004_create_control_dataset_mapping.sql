BEGIN;

CREATE TABLE control.dataset_mapping (
    dataset_mapping_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    dataset_id              BIGINT NOT NULL,

    target_layer            VARCHAR(20) NOT NULL,

    storage_group           VARCHAR(30) NOT NULL,

    target_schema           VARCHAR(128) NOT NULL,
    target_object           VARCHAR(256) NOT NULL,

    is_active               BOOLEAN NOT NULL DEFAULT TRUE,

    description             TEXT,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dataset_mapping_dataset
        FOREIGN KEY (dataset_id)
        REFERENCES control.dataset (dataset_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_dataset_mapping_group
        UNIQUE (
            dataset_id,
            target_layer,
            storage_group
        ),

    CONSTRAINT ck_dataset_mapping_layer
        CHECK (
            target_layer IN (
                'RAW',
                'IDENTITY',
                'CANONICAL',
                'DORIS'
            )
        ),

    CONSTRAINT ck_dataset_mapping_storage_group
        CHECK (
            BTRIM(storage_group) <> ''
        )
);

COMMENT ON TABLE control.dataset_mapping IS
    'Maps a logical dataset to a physical representation in an ODS or analytical layer. Each mapping represents one storage group of the dataset. Orchestration and physical connection details remain under Apache Hop.';

COMMENT ON COLUMN control.dataset_mapping.dataset_mapping_id IS
    'Technical identifier of the physical dataset representation.';

COMMENT ON COLUMN control.dataset_mapping.dataset_id IS
    'Logical dataset represented by this physical mapping.';

COMMENT ON COLUMN control.dataset_mapping.target_layer IS
    'Physical target layer: RAW, IDENTITY, CANONICAL or DORIS. FACT/DIM/MART are analytical model types and are not target layers here.';

COMMENT ON COLUMN control.dataset_mapping.storage_group IS
    'Physical storage group within the target layer, for example CORE or EXTENDED. It identifies a distinct physical representation of the logical dataset.';

COMMENT ON COLUMN control.dataset_mapping.target_schema IS
    'Physical target schema, for example raw, identity, canonical or a Doris database/schema.';

COMMENT ON COLUMN control.dataset_mapping.target_object IS
    'Physical target table, view or object name for this storage group.';

COMMENT ON COLUMN control.dataset_mapping.is_active IS
    'Indicates whether this dataset mapping is currently active for ingestion or downstream processing.';

CREATE INDEX ix_dataset_mapping_dataset
    ON control.dataset_mapping (dataset_id);

CREATE INDEX ix_dataset_mapping_layer
    ON control.dataset_mapping (target_layer);

CREATE INDEX ix_dataset_mapping_active
    ON control.dataset_mapping (is_active);

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.dataset_mapping
TO hospital_ods_etl;

GRANT SELECT
ON control.dataset_mapping
TO hospital_ods_app;

COMMIT;

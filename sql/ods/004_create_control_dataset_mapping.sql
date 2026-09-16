BEGIN;

CREATE TABLE control.dataset_mapping (
    dataset_mapping_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    dataset_id              BIGINT NOT NULL,

    target_layer            VARCHAR(20) NOT NULL,

    target_schema            VARCHAR(128) NOT NULL,
    target_object            VARCHAR(256) NOT NULL,

    mapping_role             VARCHAR(30) NOT NULL DEFAULT 'PRIMARY',

    is_active                BOOLEAN NOT NULL DEFAULT TRUE,

    description              TEXT,

    created_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dataset_mapping_dataset
        FOREIGN KEY (dataset_id)
        REFERENCES control.dataset (dataset_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_dataset_mapping_target
        UNIQUE (
            dataset_id,
            target_layer,
            target_schema,
            target_object
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

    CONSTRAINT ck_dataset_mapping_role
        CHECK (
            mapping_role IN (
                'PRIMARY',
                'AUXILIARY'
            )
        )
);

COMMENT ON TABLE control.dataset_mapping IS
    'Maps a logical dataset to a physical ODS/warehouse object. Orchestration and physical connection details remain under Apache Hop.';

COMMENT ON COLUMN control.dataset_mapping.dataset_id IS
    'Logical dataset represented by this mapping.';

COMMENT ON COLUMN control.dataset_mapping.target_layer IS
    'Physical target layer: RAW, IDENTITY, CANONICAL or DORIS. FACT/DIM/MART are analytical model types and are not target layers here.';

COMMENT ON COLUMN control.dataset_mapping.target_schema IS
    'Physical target schema, for example raw, canonical or a Doris database/schema.';

COMMENT ON COLUMN control.dataset_mapping.target_object IS
    'Physical target table/view/object name.';

COMMENT ON COLUMN control.dataset_mapping.mapping_role IS
    'PRIMARY is the authoritative target for the dataset at this layer; AUXILIARY is an additional physical representation.';

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

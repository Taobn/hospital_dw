BEGIN;

CREATE TYPE control.dataset_dependency_type_enum AS ENUM (
    'LOAD',
    'REFERENCE',
    'PROCESSING'
);

CREATE TABLE control.dataset_dependency (
    dataset_dependency_id
        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    dataset_id
        BIGINT NOT NULL,

    depends_on_dataset_id
        BIGINT NOT NULL,

    dependency_type
        control.dataset_dependency_type_enum NOT NULL DEFAULT 'LOAD',

    is_active
        BOOLEAN NOT NULL DEFAULT TRUE,

    description
        TEXT,

    created_at
        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at
        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dataset_dependency_dataset
        FOREIGN KEY (dataset_id)
        REFERENCES control.dataset (dataset_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_dataset_dependency_parent
        FOREIGN KEY (depends_on_dataset_id)
        REFERENCES control.dataset (dataset_id)
        ON DELETE CASCADE,

    CONSTRAINT ck_dataset_dependency_no_self
        CHECK (
            dataset_id <> depends_on_dataset_id
        ),

    CONSTRAINT uq_dataset_dependency
        UNIQUE (
            dataset_id,
            depends_on_dataset_id
        )
);

COMMENT ON TYPE control.dataset_dependency_type_enum IS
    'Dependency semantics between logical datasets.';

COMMENT ON TABLE control.dataset_dependency IS
    'Defines the dependency graph between logical datasets. The dependent dataset must wait for or rely on the referenced dataset according to dependency_type.';

COMMENT ON COLUMN control.dataset_dependency.dataset_dependency_id IS
    'Technical identifier of the dataset dependency relationship.';

COMMENT ON COLUMN control.dataset_dependency.dataset_id IS
    'Dependent dataset that requires the referenced dataset.';

COMMENT ON COLUMN control.dataset_dependency.depends_on_dataset_id IS
    'Dataset that the dependent dataset relies on.';

COMMENT ON COLUMN control.dataset_dependency.dependency_type IS
    'Dependency semantics: LOAD for load sequencing, REFERENCE for master/reference availability, PROCESSING for downstream processing dependency.';

COMMENT ON COLUMN control.dataset_dependency.is_active IS
    'Indicates whether this dependency is currently active in the dataset dependency graph.';

COMMENT ON COLUMN control.dataset_dependency.description IS
    'Business or technical description of why the dependency exists.';

COMMENT ON COLUMN control.dataset_dependency.created_at IS
    'Timestamp when the dependency relationship was created.';

COMMENT ON COLUMN control.dataset_dependency.updated_at IS
    'Timestamp when the dependency relationship was last updated.';

CREATE INDEX ix_dataset_dependency_parent
    ON control.dataset_dependency (
        depends_on_dataset_id
    );

CREATE INDEX ix_dataset_dependency_active
    ON control.dataset_dependency (
        is_active
    );

CREATE INDEX ix_dataset_dependency_active_parent
    ON control.dataset_dependency (
        depends_on_dataset_id,
        dataset_id
    )
    WHERE is_active = TRUE;

GRANT USAGE
ON TYPE control.dataset_dependency_type_enum
TO hospital_ods_etl,
   hospital_ods_app;

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.dataset_dependency
TO hospital_ods_etl;

GRANT SELECT
ON control.dataset_dependency
TO hospital_ods_app;

COMMIT;

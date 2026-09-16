BEGIN;

CREATE TABLE identity.entity (
    entity_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    entity_type     VARCHAR(30) NOT NULL,

    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_identity_entity_type
        CHECK (
            entity_type IN (
                'PATIENT',
                'DEPARTMENT',
                'EMPLOYEE'
            )
        ),

    CONSTRAINT ck_identity_entity_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE',
                'MERGED'
            )
        )
);

COMMENT ON TABLE identity.entity IS
    'Cross-system master identity registry. Each row represents one stable internal identity shared across source systems. Business/transactional entities such as encounter, exam, admission, service and invoice are not stored here.';

COMMENT ON COLUMN identity.entity.entity_id IS
    'Stable internal identity identifier. It is independent of source-system identifiers.';

COMMENT ON COLUMN identity.entity.entity_type IS
    'Master identity domain. Phase 1 supports PATIENT only; additional cross-system master domains may be added later.';

COMMENT ON COLUMN identity.entity.status IS
    'Lifecycle state of the internal master identity. MERGED indicates that this identity has been consolidated into another identity; merge linkage is handled separately.';

CREATE INDEX ix_identity_entity_type
    ON identity.entity (entity_type);

CREATE INDEX ix_identity_entity_status
    ON identity.entity (status);

GRANT SELECT, INSERT, UPDATE, DELETE
ON identity.entity
TO hospital_ods_etl;

GRANT SELECT
ON identity.entity
TO hospital_ods_app;

COMMIT;

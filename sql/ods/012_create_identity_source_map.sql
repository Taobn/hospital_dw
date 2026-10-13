BEGIN;

DROP TABLE IF EXISTS identity.source_map CASCADE;

CREATE TABLE identity.source_map (
    source_map_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    entity_id               BIGINT NOT NULL,

    source_instance_id      BIGINT NOT NULL,

    source_entity_type      VARCHAR(30) NOT NULL,

    source_entity_id        VARCHAR(200) NOT NULL,

    is_current              BOOLEAN NOT NULL DEFAULT TRUE,

    confidence_level        VARCHAR(20),

    source_created_at       TIMESTAMPTZ,
    source_updated_at       TIMESTAMPTZ,

    first_seen_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen_at            TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_identity_source_map_entity
        FOREIGN KEY (entity_id)
        REFERENCES identity.entity (entity_id),

    CONSTRAINT fk_identity_source_map_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance (source_instance_id),

    CONSTRAINT uq_identity_source_map_source
        UNIQUE (
            source_instance_id,
            source_entity_type,
            source_entity_id
        ),

    CONSTRAINT ck_identity_source_map_entity_type
        CHECK (
            source_entity_type IN (
                'PATIENT',
            )
        ),

    CONSTRAINT ck_identity_source_map_confidence
        CHECK (
            confidence_level IS NULL
            OR confidence_level IN (
                'HIGH',
                'MEDIUM',
                'LOW'
            )
        )
);

COMMENT ON TABLE identity.source_map IS
    'Maps source-instance master identities to stable internal identity.entity records. Source identifiers remain source-specific and are never used as internal identity keys.';

COMMENT ON COLUMN identity.source_map.entity_id IS
    'Stable internal identity referenced from identity.entity.';

COMMENT ON COLUMN identity.source_map.source_instance_id IS
    'Concrete source-system instance or database generation. This is intentionally different from the logical data source system.';

COMMENT ON COLUMN identity.source_map.source_entity_type IS
    'Master identity domain represented by the source identifier.';

COMMENT ON COLUMN identity.source_map.source_entity_id IS
    'Authoritative identifier from the source instance.';

COMMENT ON COLUMN identity.source_map.is_current IS
    'Indicates whether this source mapping is currently valid. Historical mappings may be retained for traceability.';

COMMENT ON COLUMN identity.source_map.confidence_level IS
    'Confidence assigned to cross-system identity matching.';

COMMENT ON COLUMN identity.source_map.source_created_at IS
    'Creation timestamp of the entity in the source system, when available.';

COMMENT ON COLUMN identity.source_map.source_updated_at IS
    'Last update timestamp of the entity in the source system, when available.';

COMMENT ON COLUMN identity.source_map.first_seen_at IS
    'Timestamp when this source identity was first observed by ODS.';

COMMENT ON COLUMN identity.source_map.last_seen_at IS
    'Timestamp when this source identity was most recently observed by ODS.';


CREATE INDEX ix_identity_source_map_entity
    ON identity.source_map (entity_id);

CREATE INDEX ix_identity_source_map_source_instance
    ON identity.source_map (source_instance_id);

CREATE INDEX ix_identity_source_map_entity_type
    ON identity.source_map (
        source_instance_id,
        source_entity_type
    );

CREATE INDEX ix_identity_source_map_current
    ON identity.source_map (is_current);


GRANT SELECT, INSERT, UPDATE, DELETE
ON identity.source_map
TO hospital_ods_etl;

GRANT SELECT
ON identity.source_map
TO hospital_ods_app;

COMMIT;

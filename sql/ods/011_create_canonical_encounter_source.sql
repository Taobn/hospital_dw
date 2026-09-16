BEGIN;

DROP TABLE IF EXISTS canonical.encounter_source CASCADE;

CREATE TABLE canonical.encounter_source (
    encounter_source_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    encounter_id              BIGINT NOT NULL,

    source_instance_id        BIGINT NOT NULL,

    source_entity_type        VARCHAR(30) NOT NULL,

    source_entity_id          VARCHAR(200) NOT NULL,

    patient_source_id         VARCHAR(200),

    document_no               VARCHAR(200),

    treattime                 TIMESTAMPTZ,

    relationship_type         VARCHAR(20) NOT NULL,

    is_current                BOOLEAN NOT NULL DEFAULT TRUE,

    created_at                TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at                TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_encounter_source_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES canonical.encounter (encounter_id),

    CONSTRAINT fk_encounter_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance (source_instance_id),

    CONSTRAINT uq_encounter_source_identity
        UNIQUE (
            source_instance_id,
            source_entity_type,
            source_entity_id
        ),

    CONSTRAINT ck_encounter_source_entity_type
        CHECK (
            source_entity_type IN (
                'EXAM',
                'ADMISSION'
            )
        ),

    CONSTRAINT ck_encounter_source_relationship
        CHECK (
            relationship_type IN (
                'ROOT_EXAM',
                'EXAM',
                'ADMISSION'
            )
        )
);

COMMENT ON TABLE canonical.encounter_source IS
    'Links canonical encounters to authoritative source events such as EXAM and ADMISSION. Source event identities are scoped by source instance and are not encounter identities themselves.';

COMMENT ON COLUMN canonical.encounter_source.encounter_id IS
    'Canonical treatment episode associated with the source event.';

COMMENT ON COLUMN canonical.encounter_source.source_instance_id IS
    'Concrete source-system instance or database generation that owns the source event.';

COMMENT ON COLUMN canonical.encounter_source.source_entity_type IS
    'Source event type. Phase 1 supports EXAM and ADMISSION.';

COMMENT ON COLUMN canonical.encounter_source.source_entity_id IS
    'Authoritative source event identifier, such as EXAM_ID or ADMISSION_ID.';

COMMENT ON COLUMN canonical.encounter_source.patient_source_id IS
    'Patient identifier as represented in the source instance. This is retained for traceability and reconciliation only.';

COMMENT ON COLUMN canonical.encounter_source.document_no IS
    'Source document grouping reference. It is not an encounter identity.';

COMMENT ON COLUMN canonical.encounter_source.treattime IS
    'Source treatment/event timestamp used for traceability and encounter resolution.';

COMMENT ON COLUMN canonical.encounter_source.relationship_type IS
    'Relationship between the source event and the canonical encounter. ROOT_EXAM identifies the source EXAM that seeded the episode; EXAM and ADMISSION represent associated source events.';

COMMENT ON COLUMN canonical.encounter_source.is_current IS
    'Indicates whether the source relationship is currently valid.';

CREATE INDEX ix_encounter_source_encounter
    ON canonical.encounter_source (
        encounter_id
    );

CREATE INDEX ix_encounter_source_instance
    ON canonical.encounter_source (
        source_instance_id
    );

CREATE INDEX ix_encounter_source_entity_type
    ON canonical.encounter_source (
        source_instance_id,
        source_entity_type
    );

CREATE INDEX ix_encounter_source_document
    ON canonical.encounter_source (
        source_instance_id,
        document_no
    );

CREATE INDEX ix_encounter_source_patient
    ON canonical.encounter_source (
        source_instance_id,
        patient_source_id
    );

CREATE INDEX ix_encounter_source_treattime
    ON canonical.encounter_source (
        treattime
    );

CREATE INDEX ix_encounter_source_current
    ON canonical.encounter_source (
        is_current
    );

CREATE UNIQUE INDEX uq_encounter_source_root_exam
    ON canonical.encounter_source (
        encounter_id
    )
    WHERE relationship_type = 'ROOT_EXAM';

GRANT SELECT, INSERT, UPDATE, DELETE
ON canonical.encounter_source
TO hospital_ods_etl;

GRANT SELECT
ON canonical.encounter_source
TO hospital_ods_app;

COMMIT;

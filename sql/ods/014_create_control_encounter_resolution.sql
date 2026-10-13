BEGIN;

CREATE TABLE control.encounter_resolution (
    resolution_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_system              VARCHAR(50) NOT NULL,

    source_entity_type         VARCHAR(30) NOT NULL,
    source_entity_id           VARCHAR(200) NOT NULL,

    patient_source_id          VARCHAR(200),

    document_no                VARCHAR(200),

    treattime                  TIMESTAMPTZ,

    candidate_encounter_id     BIGINT,
    resolved_encounter_id      BIGINT,

    resolution_rule            VARCHAR(40) NOT NULL,

    resolution_status          VARCHAR(30) NOT NULL DEFAULT 'RESOLVED',

    confidence_level           VARCHAR(20),

    batch_id                   BIGINT NOT NULL,

    created_at                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_encounter_resolution_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch (batch_id),

    CONSTRAINT uq_encounter_resolution_source
        UNIQUE (
            source_system,
            source_entity_type,
            source_entity_id
        ),

    CONSTRAINT ck_encounter_resolution_entity_type
        CHECK (
            source_entity_type IN (
                'EXAM',
                'ADMISSION'
            )
        ),

    CONSTRAINT ck_encounter_resolution_rule
        CHECK (
            resolution_rule IN (
                'EXISTING_SOURCE_MAP',
                'ADMISSION_TO_EXAM',
                'EXAM_EXISTING_ENCOUNTER',
                'ACTIVE_DOCUMENT',
                'TREATMENT_BOUNDARY',
                'INVOICE_BOUNDARY',
                'MANUAL_REVIEW',
                'UNRESOLVED'
            )
        ),

    CONSTRAINT ck_encounter_resolution_status
        CHECK (
            resolution_status IN (
                'RESOLVED',
                'UNRESOLVED',
                'REVIEW',
                'REJECTED'
            )
        ),

    CONSTRAINT ck_encounter_resolution_confidence
        CHECK (
            confidence_level IS NULL
            OR confidence_level IN (
                'HIGH',
                'MEDIUM',
                'LOW'
            )
        )
);

COMMENT ON TABLE control.encounter_resolution IS
    'ODS resolution state mapping source clinical entities such as EXAM and ADMISSION to a canonical treatment episode. It records resolution rationale and confidence; canonical encounter data is stored separately.';

COMMENT ON COLUMN control.encounter_resolution.source_system IS
    'Logical source system code, for example HIS.';

COMMENT ON COLUMN control.encounter_resolution.source_entity_type IS
    'Source clinical entity being resolved. Phase 1 supports EXAM and ADMISSION.';

COMMENT ON COLUMN control.encounter_resolution.source_entity_id IS
    'Authoritative source identity, for example EXAM_ID or ADMISSION_ID.';

COMMENT ON COLUMN control.encounter_resolution.patient_source_id IS
    'Source patient identifier retained for traceability.';

COMMENT ON COLUMN control.encounter_resolution.document_no IS
    'Source grouping key. DOCUMENT_NO is not itself an encounter identity.';

COMMENT ON COLUMN control.encounter_resolution.treattime IS
    'Treatment timestamp used as supporting evidence for episode resolution.';

COMMENT ON COLUMN control.encounter_resolution.candidate_encounter_id IS
    'Candidate canonical encounter considered during resolution.';

COMMENT ON COLUMN control.encounter_resolution.resolved_encounter_id IS
    'Canonical encounter selected by the resolution process. Phase 1A does not enforce a FK because canonical.encounter is created in Phase 1B.';

COMMENT ON COLUMN control.encounter_resolution.resolution_rule IS
    'Rule that produced the resolution decision.';

COMMENT ON COLUMN control.encounter_resolution.resolution_status IS
    'Current state of the resolution decision.';

COMMENT ON COLUMN control.encounter_resolution.confidence_level IS
    'Confidence assigned by the resolution algorithm.';

COMMENT ON COLUMN control.encounter_resolution.batch_id IS
    'ODS batch that produced or last updated this resolution record.';

CREATE INDEX ix_encounter_resolution_batch
    ON control.encounter_resolution (batch_id);

CREATE INDEX ix_encounter_resolution_resolved
    ON control.encounter_resolution (resolved_encounter_id);

CREATE INDEX ix_encounter_resolution_document
    ON control.encounter_resolution (
        source_system,
        document_no
    );

CREATE INDEX ix_encounter_resolution_patient
    ON control.encounter_resolution (
        source_system,
        patient_source_id
    );

CREATE INDEX ix_encounter_resolution_status
    ON control.encounter_resolution (resolution_status);

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.encounter_resolution
TO hospital_ods_etl;

GRANT SELECT
ON control.encounter_resolution
TO hospital_ods_app;

COMMIT;

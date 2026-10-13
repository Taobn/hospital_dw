BEGIN;

CREATE TABLE canonical.encounter (
    encounter_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    encounter_code          VARCHAR(50) NOT NULL,

    patient_entity_id       BIGINT NOT NULL,

    encounter_type          VARCHAR(20) NOT NULL DEFAULT 'CLINICAL',

    start_at                TIMESTAMPTZ NOT NULL,

    end_at                  TIMESTAMPTZ,

    status                  VARCHAR(20) NOT NULL DEFAULT 'OPEN',

    primary_document_no     VARCHAR(200),

    invoice_status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_encounter_patient_entity
        FOREIGN KEY (patient_entity_id)
        REFERENCES identity.entity (entity_id),

    CONSTRAINT uq_encounter_code
        UNIQUE (encounter_code),

    CONSTRAINT ck_encounter_type
        CHECK (
            encounter_type IN (
                'CLINICAL',
                'NON_CLINICAL'
            )
        ),

    CONSTRAINT ck_encounter_status
        CHECK (
            status IN (
                'OPEN',
                'CLOSED',
                'CANCELLED',
                'REVIEW'
            )
        ),

    CONSTRAINT ck_encounter_time_range
        CHECK (
            end_at IS NULL
            OR end_at >= start_at
        ),

    CONSTRAINT ck_encounter_invoice_status
        CHECK (
            invoice_status IN (
                'PENDING',
                'PARTIAL',
                'INVOICED',
                'PAID',
                'CANCELLED'
            )
        )
);

COMMENT ON TABLE canonical.encounter IS
    'Canonical treatment episode representing one continuous clinical treatment and billing lifecycle. An encounter is not equivalent to an EXAM, ADMISSION, DOCUMENT_NO or invoice.';

COMMENT ON COLUMN canonical.encounter.encounter_id IS
    'Technical internal identifier for the canonical treatment episode.';

COMMENT ON COLUMN canonical.encounter.encounter_code IS
    'Stable human-readable encounter reference. It must not encode patient ID, document number, date or source-system identity.';

COMMENT ON COLUMN canonical.encounter.patient_entity_id IS
    'Stable cross-system patient identity referenced from identity.entity.';

COMMENT ON COLUMN canonical.encounter.encounter_type IS
    'Business context of the episode. CLINICAL represents a treatment episode; NON_CLINICAL is reserved for future non-clinical encounter semantics and is not inferred from individual service rows.';

COMMENT ON COLUMN canonical.encounter.start_at IS
    'Start timestamp of the treatment episode.';

COMMENT ON COLUMN canonical.encounter.end_at IS
    'End timestamp of the treatment episode. NULL while the episode remains open or its end is not yet known.';

COMMENT ON COLUMN canonical.encounter.status IS
    'Lifecycle state of the canonical treatment episode.';

COMMENT ON COLUMN canonical.encounter.primary_document_no IS
    'Primary source document grouping reference for traceability. It is not an encounter identity and is not unique.';

COMMENT ON COLUMN canonical.encounter.invoice_status IS
    'Billing lifecycle summary for the treatment episode. It does not replace canonical.invoice records.';

CREATE INDEX ix_encounter_patient
    ON canonical.encounter (patient_entity_id);

CREATE INDEX ix_encounter_status
    ON canonical.encounter (status);

CREATE INDEX ix_encounter_start_at
    ON canonical.encounter (start_at);

CREATE INDEX ix_encounter_document
    ON canonical.encounter (
        primary_document_no
    );

CREATE INDEX ix_encounter_patient_start
    ON canonical.encounter (
        patient_entity_id,
        start_at DESC
    );

GRANT SELECT, INSERT, UPDATE, DELETE
ON canonical.encounter
TO hospital_ods_etl;

GRANT SELECT
ON canonical.encounter
TO hospital_ods_app;

COMMIT;

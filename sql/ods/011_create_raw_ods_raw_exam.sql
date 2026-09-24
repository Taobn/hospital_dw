BEGIN;

DROP TABLE IF EXISTS raw.ods_raw_exam CASCADE;

CREATE TABLE raw.ods_raw_exam (
    raw_exam_id
        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_instance_id
        BIGINT NOT NULL,

    batch_id
        BIGINT NOT NULL,

    ingested_at
        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    is_deleted
        BOOLEAN NOT NULL DEFAULT FALSE,

    deleted_at
        TIMESTAMPTZ,

    -- =========================================================
    -- SOURCE IDENTITY / LINKAGE
    -- =========================================================

    exam_id
        BIGINT NOT NULL,

    reception_no
        BIGINT,

    patient_id
        BIGINT,

    document_no
        BIGINT,

    -- =========================================================
    -- SOURCE AUDIT / CHANGE TRACKING
    -- =========================================================

    created_by
        VARCHAR(15),

    created_date
        TIMESTAMP(6) WITHOUT TIME ZONE,

    updated_by
        VARCHAR(15),

    updated_date
        TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,

    -- =========================================================
    -- ORGANIZATION / LOCATION
    -- =========================================================

    department_code
        VARCHAR(7),

    room_id
        BIGINT,

    -- =========================================================
    -- EXAMINATION
    -- =========================================================

    exam_type
        VARCHAR(13),

    exam_status
        CHAR(1),

    exam_date
        TIMESTAMP(6) WITHOUT TIME ZONE,

    doctor_code
        VARCHAR(15),

    -- =========================================================
    -- STRUCTURED CLINICAL MEASUREMENTS
    -- =========================================================

    pulse
        NUMERIC,

    temperature
        NUMERIC,

    blood_pressure
        INTEGER,

    blood_pressure_x
        INTEGER,

    breath_interval
        NUMERIC,

    weight
        NUMERIC,

    height
        NUMERIC,

    -- =========================================================
    -- STRUCTURED DIAGNOSIS / CLASSIFICATION
    -- =========================================================

    icd10_code
        VARCHAR(15),

    type_id
        BIGINT,

    -- =========================================================
    -- BILLING / PAYMENT
    -- =========================================================

    has_fee
        CHAR(1),

    payment_status
        CHAR(1),

    is_emergency
        CHAR(1),

    priority
        INTEGER,

    fee_ref_row_id
        BIGINT,

    fee_ref_status
        CHAR(1),

    fee_idx
        BIGINT,

    exam_move_flag
        CHAR(1),

    hatd_flag
        CHAR(1),

    isjo_flag
        CHAR(1),

    isreq_flag
        CHAR(1),

    -- =========================================================
    -- FORWARD / REFERRAL LINKAGE
    -- =========================================================

    forward_department_code
        VARCHAR(10),

    forward_room_id
        BIGINT,

    forward_reception_idx
        BIGINT,

    reexam_flag
        CHAR(1),

    -- =========================================================
    -- OTHER STRUCTURED ATTRIBUTES
    -- =========================================================

    zone
        VARCHAR(15),

    cancel_by
        VARCHAR(15),

    treatment_time
        INTEGER,

    has_allergy
        CHAR(1),

    in_out_package
        VARCHAR(3),

    body_parts
        CHAR(1),

    shift_code
        VARCHAR(2),

    room_key
        BIGINT,

    bmi
        NUMERIC,

    exam_type_3
        VARCHAR(2),

    detail_exam_type_3
        VARCHAR(2),

    blood_pressure_measured_at
        TIMESTAMP(6) WITHOUT TIME ZONE,

    paid_for
        CHAR(1),

    -- =========================================================
    -- NURSING / STAFF IDENTIFIERS
    -- =========================================================

    head_nurse_code
        VARCHAR(15),

    nurse_code
        VARCHAR(15),

    -- =========================================================
    -- EXAMINATION CLASSIFICATION
    -- =========================================================

    is_health_exam
        CHAR(1),

    -- =========================================================
    -- CONSTRAINTS
    -- =========================================================

    CONSTRAINT uq_raw_exam_source_identity
        UNIQUE (
            source_instance_id,
            exam_id
        ),

    CONSTRAINT fk_raw_exam_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance (
            source_instance_id
        ),

    CONSTRAINT fk_raw_exam_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch (
            batch_id
        ),

    CONSTRAINT ck_raw_exam_deleted_at
        CHECK (
            (is_deleted = FALSE AND deleted_at IS NULL)
            OR
            (is_deleted = TRUE AND deleted_at IS NOT NULL)
        )
);

-- =============================================================
-- INDEXES
-- =============================================================

CREATE INDEX ix_raw_exam_patient
    ON raw.ods_raw_exam (patient_id);

CREATE INDEX ix_raw_exam_document
    ON raw.ods_raw_exam (document_no);

CREATE INDEX ix_raw_exam_exam_date
    ON raw.ods_raw_exam (exam_date);

CREATE INDEX ix_raw_exam_updated_date
    ON raw.ods_raw_exam (updated_date);

CREATE INDEX ix_raw_exam_batch
    ON raw.ods_raw_exam (batch_id);

CREATE INDEX ix_raw_exam_department
    ON raw.ods_raw_exam (department_code);

CREATE INDEX ix_raw_exam_forward_reception
    ON raw.ods_raw_exam (forward_reception_idx);

CREATE INDEX ix_raw_exam_active_partial
    ON raw.ods_raw_exam (
        source_instance_id,
        exam_id
    )
    WHERE is_deleted = FALSE;

-- =============================================================
-- COMMENTS
-- =============================================================

COMMENT ON TABLE raw.ods_raw_exam IS
    'Structured RAW representation of HIS VIMES.HMS_EXAM. Contains source identity, source linkage, audit/change tracking, structured examination, clinical measurements, billing and operational attributes. Clinical narrative/free-text fields are stored separately in the extended table.';

COMMENT ON COLUMN raw.ods_raw_exam.exam_id IS
    'HIS VIMES.HMS_EXAM.HE_RECEPTIDX. Source examination identity and RAW source key.';

COMMENT ON COLUMN raw.ods_raw_exam.patient_id IS
    'HIS VIMES.HMS_EXAM.HE_PATIENTNO. Source patient identifier and identity linkage field.';

COMMENT ON COLUMN raw.ods_raw_exam.document_no IS
    'HIS VIMES.HMS_EXAM.HE_DOCNO. Source document/grouping identifier. Not treated as an encounter identity.';

COMMENT ON COLUMN raw.ods_raw_exam.updated_date IS
    'HIS VIMES.HMS_EXAM.HE_UPDATEDDATE. Source change timestamp used as the incremental WATERMARK cursor.';

COMMENT ON COLUMN raw.ods_raw_exam.exam_date IS
    'HIS VIMES.HMS_EXAM.HE_EXAMDATE. Configured source business date for the examination dataset.';

COMMENT ON COLUMN raw.ods_raw_exam.ingested_at IS
    'ODS ingestion timestamp. This represents when the record was ingested into ODS and is not the source update timestamp.';

COMMENT ON COLUMN raw.ods_raw_exam.batch_id IS
    'ODS batch that most recently inserted, updated, or changed the lifecycle state of this RAW record.';

COMMENT ON COLUMN raw.ods_raw_exam.is_deleted IS
    'ODS-managed soft-delete lifecycle flag. TRUE when the source record has been detected as deleted by reconciliation or CDC.';

COMMENT ON COLUMN raw.ods_raw_exam.deleted_at IS
    'ODS timestamp when deletion of the source record was detected. NULL while the source record is active.';

-- =============================================================
-- GRANTS
-- =============================================================

GRANT SELECT, INSERT, UPDATE, DELETE
ON raw.ods_raw_exam
TO hospital_ods_etl;

GRANT SELECT
ON raw.ods_raw_exam
TO hospital_ods_app;

GRANT USAGE, SELECT
ON SEQUENCE raw.ods_raw_exam_raw_exam_id_seq
TO hospital_ods_etl;

COMMIT;

BEGIN;

DROP TABLE IF EXISTS raw.ods_raw_exam_stage CASCADE;

CREATE TABLE raw.ods_raw_exam_stage (
    raw_exam_stage_id
        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_instance_id
        BIGINT NOT NULL,

    batch_id
        BIGINT NOT NULL,

    loaded_at
        TIMESTAMP(6) WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    is_deleted
        BOOLEAN NOT NULL DEFAULT FALSE,

    deleted_at
        TIMESTAMP(6),

    -- =========================================================
    -- SOURCE IDENTITY / LINKAGE
    -- =========================================================

    exam_id
        BIGINT NOT NULL,

    reception_no
        INTEGER,

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
        TIMESTAMP(6),

    updated_by
        VARCHAR(15),

    updated_date
        TIMESTAMP(6) NOT NULL,

    -- =========================================================
    -- ORGANIZATION / LOCATION
    -- =========================================================

    department_code
        VARCHAR(10),

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
        TIMESTAMP(6),

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

    bmi
        NUMERIC,

    blood_pressure_measured_at
        TIMESTAMP(6),

    -- =========================================================
    -- STRUCTURED DIAGNOSIS / CLASSIFICATION
    -- =========================================================

    icd10_code
        VARCHAR(15),

    type_id
        INTEGER,

    exam_type_3
        VARCHAR(2),

    detail_exam_type_3
        VARCHAR(2),

    -- =========================================================
    -- BILLING / PAYMENT FLAGS
    -- =========================================================

    has_fee
        CHAR(1),

    payment_status
        CHAR(1),

    fee_ref_row_id
        BIGINT,

    fee_ref_status
        CHAR(1),

    fee_idx
        BIGINT,

    paid_for
        CHAR(1),

    -- =========================================================
    -- EXAMINATION / WORKFLOW FLAGS
    -- =========================================================

    is_emergency
        CHAR(1),

    priority
        INTEGER,

    exam_move_flag
        CHAR(1),

    hatd_flag
        CHAR(1),

    isjo_flag
        CHAR(1),

    isreq_flag
        CHAR(1),

    reexam_flag
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

    CONSTRAINT fk_raw_exam_stage_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance (
            source_instance_id
        ),

    CONSTRAINT fk_raw_exam_stage_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch (
            batch_id
        ),

    CONSTRAINT ck_raw_exam_stage_deleted_at
        CHECK (
            (is_deleted = FALSE AND deleted_at IS NULL)
            OR
            (is_deleted = TRUE AND deleted_at IS NOT NULL)
        )
);

-- =============================================================
-- INDEXES
-- =============================================================

CREATE INDEX ix_raw_exam_stage_batch
    ON raw.ods_raw_exam_stage (batch_id);

CREATE INDEX ix_raw_exam_stage_source_exam
    ON raw.ods_raw_exam_stage (
        source_instance_id,
        exam_id
    );

CREATE INDEX ix_raw_exam_stage_patient
    ON raw.ods_raw_exam_stage (patient_id);

CREATE INDEX ix_raw_exam_stage_document
    ON raw.ods_raw_exam_stage (document_no);

CREATE INDEX ix_raw_exam_stage_exam_date
    ON raw.ods_raw_exam_stage (exam_date);

CREATE INDEX ix_raw_exam_stage_updated_date
    ON raw.ods_raw_exam_stage (updated_date);

CREATE INDEX ix_raw_exam_stage_department
    ON raw.ods_raw_exam_stage (department_code);

CREATE INDEX ix_raw_exam_stage_forward_reception
    ON raw.ods_raw_exam_stage (forward_reception_idx);

-- =============================================================
-- COMMENTS
-- =============================================================

COMMENT ON TABLE raw.ods_raw_exam_stage IS
    'Batch-scoped staging table for structured HIS HMS_EXAM data before validation and upsert into raw.ods_raw_exam. Duplicate source identities are intentionally allowed for batch-level validation.';

COMMENT ON COLUMN raw.ods_raw_exam_stage.exam_id IS
    'HIS HE_RECEPTIDX. Source examination identity. Duplicate values within the same batch are validated before RAW upsert.';

COMMENT ON COLUMN raw.ods_raw_exam_stage.updated_date IS
    'HIS HE_UPDATEDDATE. Source change timestamp used as incremental extraction cursor.';

COMMENT ON COLUMN raw.ods_raw_exam_stage.loaded_at IS
    'ODS timestamp when the source row was loaded into staging. This is not the source update timestamp.';

COMMENT ON COLUMN raw.ods_raw_exam_stage.batch_id IS
    'ODS processing batch that loaded this staging row.';

COMMENT ON COLUMN raw.ods_raw_exam_stage.is_deleted IS
    'ODS-managed lifecycle flag carried through staging. TRUE indicates a source deletion event when deletion detection is implemented.';

COMMENT ON COLUMN raw.ods_raw_exam_stage.deleted_at IS
    'ODS timestamp when the source deletion was detected.';

-- =============================================================
-- GRANTS
-- =============================================================

GRANT SELECT, INSERT, UPDATE, DELETE
ON raw.ods_raw_exam_stage
TO hospital_ods_etl;

GRANT SELECT
ON raw.ods_raw_exam_stage
TO hospital_ods_app;

COMMIT;

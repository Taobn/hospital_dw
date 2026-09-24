BEGIN;

CREATE TABLE raw.ods_raw_exam_extended (
    raw_exam_extended_id
        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_instance_id
        BIGINT NOT NULL,

    batch_id
        BIGINT NOT NULL,
    
    is_deleted
        BOOLEAN NOT NULL DEFAULT FALSE,
    
    deleted_at
    	TIMESTAMPTZ,

    exam_id
        BIGINT NOT NULL,
    
    updated_date
        TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
        
    medical_note
        TEXT,

    examination_note
        TEXT,

    prediagnostic
        TEXT,

    diagnostic
        TEXT,

    reason_for_admission
        TEXT,

    general_condition
        TEXT,

    circulation
        TEXT,

    respiratory
        TEXT,

    digestive
        TEXT,

    urinary
        TEXT,

    neurological
        TEXT,

    musculoskeletal
        TEXT,

    other_organs
        TEXT,

    test_plan
        TEXT,

    treatment_plan
        TEXT,

    prognosis
        TEXT,

    nutrition
        TEXT,

    patient_instructions
        TEXT,

    ingested_at
        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_raw_exam_extended_source_identity
        UNIQUE (source_instance_id, exam_id),

    CONSTRAINT fk_raw_exam_extended_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance (source_instance_id),

    CONSTRAINT fk_raw_exam_extended_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch (batch_id)
);

CREATE INDEX ix_raw_exam_extended_batch
    ON raw.ods_raw_exam_extended (batch_id);

CREATE INDEX ix_raw_exam_extended_exam
    ON raw.ods_raw_exam_extended (source_instance_id, exam_id);

GRANT SELECT, INSERT, UPDATE, DELETE
ON raw.ods_raw_exam_extended
TO hospital_ods_etl;

GRANT SELECT
ON raw.ods_raw_exam_extended
TO hospital_ods_app;

GRANT USAGE, SELECT
ON SEQUENCE raw.ods_raw_exam_extended_raw_exam_extended_id_seq
TO hospital_ods_etl;

COMMENT ON TABLE raw.ods_raw_exam_extended IS
    'RAW extended representation of HIS HMS_EXAM clinical free-text fields. Source identity is (source_instance_id, exam_id).';

COMMENT ON COLUMN raw.ods_raw_exam_extended.exam_id IS
    'HIS HE_RECEPTIDX. Source examination identity shared with raw.ods_raw_exam.';

COMMENT ON COLUMN raw.ods_raw_exam_extended.batch_id IS
    'ODS batch that most recently inserted or updated this RAW extended record.';

COMMIT;

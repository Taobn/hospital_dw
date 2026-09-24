BEGIN;

CREATE TABLE raw.ods_raw_exam_extended_stage (
    raw_exam_extended_stage_id
        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_instance_id
        BIGINT NOT NULL,

    batch_id
        BIGINT NOT NULL,

    loaded_at
        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    exam_id
        BIGINT NOT NULL,

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

    CONSTRAINT fk_raw_exam_extended_stage_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance (source_instance_id),

    CONSTRAINT fk_raw_exam_extended_stage_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch (batch_id)
);

CREATE INDEX ix_raw_exam_extended_stage_batch
    ON raw.ods_raw_exam_extended_stage (batch_id);

CREATE INDEX ix_raw_exam_extended_stage_exam
    ON raw.ods_raw_exam_extended_stage
       (source_instance_id, exam_id);

GRANT SELECT, INSERT, UPDATE, DELETE
ON raw.ods_raw_exam_extended_stage
TO hospital_ods_etl;

GRANT SELECT
ON raw.ods_raw_exam_extended_stage
TO hospital_ods_app;

GRANT USAGE, SELECT
ON SEQUENCE raw.ods_raw_exam_extended_stage_raw_exam_extended_stage_id_seq
TO hospital_ods_etl;

COMMENT ON TABLE raw.ods_raw_exam_extended_stage IS
    'Stage table for HIS HMS_EXAM extended/free-text fields. Data is retained by batch for validation and reconciliation.';

COMMENT ON COLUMN raw.ods_raw_exam_extended_stage.exam_id IS
    'HIS HE_RECEPTIDX. Source examination identity shared with the structured examination stage.';

COMMIT;

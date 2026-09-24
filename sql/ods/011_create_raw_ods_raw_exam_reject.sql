BEGIN;

CREATE TABLE IF NOT EXISTS raw.ods_raw_exam_reject (
    raw_exam_reject_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_instance_id      BIGINT NOT NULL,
    batch_id                BIGINT NOT NULL,
    rejected_at             TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL
                            DEFAULT CURRENT_TIMESTAMP,

    -- Source business identity / tracing
    exam_id                 BIGINT,
    patient_id              BIGINT,
    exam_date               TIMESTAMP(6),
    updated_date            TIMESTAMP(6),

    -- Semantic error classification
    error_code              VARCHAR(100) NOT NULL,
    error_field             VARCHAR(100),
    error_message           TEXT NOT NULL,

    -- Validation stage that produced the rejection
    rejection_stage         VARCHAR(50) NOT NULL,

    -- Optional structured diagnostic context
    details                 JSONB,

    CONSTRAINT fk_raw_exam_reject_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance(source_instance_id),

    CONSTRAINT fk_raw_exam_reject_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch(batch_id),

    CONSTRAINT ck_raw_exam_reject_error_code
        CHECK (BTRIM(error_code) <> ''),

    CONSTRAINT ck_raw_exam_reject_error_message
        CHECK (BTRIM(error_message) <> ''),

    CONSTRAINT ck_raw_exam_reject_rejection_stage
        CHECK (
            rejection_stage IN (
                'SOURCE_VALIDATION',
                'DUPLICATE_VALIDATION',
                'BUSINESS_VALIDATION',
                'REFERENCE_VALIDATION',
                'RECONCILIATION'
            )
        )
);

CREATE INDEX IF NOT EXISTS ix_raw_exam_reject_batch
    ON raw.ods_raw_exam_reject(batch_id);

CREATE INDEX IF NOT EXISTS ix_raw_exam_reject_source_exam
    ON raw.ods_raw_exam_reject(source_instance_id, exam_id);

CREATE INDEX IF NOT EXISTS ix_raw_exam_reject_error_code
    ON raw.ods_raw_exam_reject(error_code);

CREATE INDEX IF NOT EXISTS ix_raw_exam_reject_batch_error
    ON raw.ods_raw_exam_reject(batch_id, error_code);

COMMENT ON TABLE raw.ods_raw_exam_reject IS
    'Rejected HIS HMS_EXAM source records and their semantic validation errors. This table preserves row-level rejection evidence by ODS batch.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.source_instance_id IS
    'ODS source instance that produced the rejected source record.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.batch_id IS
    'ODS processing batch in which the source record was rejected.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.exam_id IS
    'HIS HE_RECEPTIDX. Source examination identity when available.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.patient_id IS
    'HIS HE_PATIENTNO. Source patient identity when available.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.exam_date IS
    'HIS HE_EXAMDATE. Source examination timestamp when available.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.updated_date IS
    'HIS HE_UPDATEDDATE. Source change timestamp when available.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.error_code IS
    'Semantic error code describing the reason the source record was rejected.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.error_field IS
    'Source or ODS field associated with the validation error when applicable. NULL when the error is not field-specific.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.error_message IS
    'Human-readable description of the rejection reason.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.rejection_stage IS
    'Processing stage at which the source record was rejected.';

COMMENT ON COLUMN raw.ods_raw_exam_reject.details IS
    'Optional structured diagnostic context for the rejection, stored as JSONB.';

GRANT SELECT, INSERT, UPDATE, DELETE
ON raw.ods_raw_exam_reject
TO hospital_ods_etl;

GRANT SELECT
ON raw.ods_raw_exam_reject
TO hospital_ods_app;

GRANT USAGE, SELECT
ON SEQUENCE raw.ods_raw_exam_reject_raw_exam_reject_id_seq
TO hospital_ods_etl;

COMMIT;

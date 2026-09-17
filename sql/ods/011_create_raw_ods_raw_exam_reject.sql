BEGIN;

CREATE TABLE IF NOT EXISTS raw.ods_raw_exam_reject (
    raw_exam_reject_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_instance_id      BIGINT NOT NULL,
    batch_id                BIGINT NOT NULL,
    rejected_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    exam_id                 BIGINT,
    patient_id              BIGINT,
    document_no             BIGINT,
    updated_date            TIMESTAMP(6),

    rejection_code          VARCHAR(50) NOT NULL,
    rejection_reason        TEXT NOT NULL,
    rejection_field	    VARCHAR(50) NOT NULL,
    rejection_nummer	    Integer, 

    CONSTRAINT fk_raw_exam_reject_source_instance
        FOREIGN KEY (source_instance_id)
        REFERENCES control.data_source_instance(source_instance_id),

    CONSTRAINT fk_raw_exam_reject_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch(batch_id)
);

CREATE INDEX IF NOT EXISTS ix_raw_exam_reject_batch
    ON raw.ods_raw_exam_reject(batch_id);

CREATE INDEX IF NOT EXISTS ix_raw_exam_reject_exam
    ON raw.ods_raw_exam_reject(source_instance_id, exam_id);

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

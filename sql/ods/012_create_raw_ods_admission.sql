CREATE TABLE raw.ods_raw_admission (
    raw_admission_id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    admission_id                      BIGINT NOT NULL,

    admit_date                        TIMESTAMP WITHOUT TIME ZONE,
    updated_date                      TIMESTAMP WITHOUT TIME ZONE,

    patient_id                        BIGINT NOT NULL,

    document_no                       BIGINT,

    prev_admit_date                   TIMESTAMP WITHOUT TIME ZONE,
    discharge_date                    TIMESTAMP WITHOUT TIME ZONE,

    exam_department_code              VARCHAR(50),
    transfer_out_department_code      VARCHAR(50),
    admit_department_code             VARCHAR(50),
    transfer_in_department_code       VARCHAR(50),
    discharge_department_code         VARCHAR(50),

    doctor_code                       VARCHAR(100),

    is_outpatient_treatment           VARCHAR(1),
    is_emergency                      VARCHAR(1),

    icd_code                          VARCHAR(30),

    treatment_status                  VARCHAR(30),

    treattime                         TIMESTAMP WITHOUT TIME ZONE,

    suggestion_code                   VARCHAR(30),

    object_id                         BIGINT,

    invoice_no                        BIGINT,

    batch_id                          BIGINT,

    ingested_at                       TIMESTAMP WITHOUT TIME ZONE
                                      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_raw_admission_admission_id
        UNIQUE (admission_id),

    CONSTRAINT fk_raw_admission_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch (batch_id)
);

CREATE INDEX ix_raw_admission_patient
    ON raw.ods_raw_admission (patient_id);

CREATE INDEX ix_raw_admission_document
    ON raw.ods_raw_admission (document_no);

CREATE INDEX ix_raw_admission_admit_date
    ON raw.ods_raw_admission (admit_date);

CREATE INDEX ix_raw_admission_treattime
    ON raw.ods_raw_admission (treattime);

CREATE INDEX ix_raw_admission_discharge_date
    ON raw.ods_raw_admission (discharge_date);

CREATE INDEX ix_raw_admission_updated_date
    ON raw.ods_raw_admission (updated_date);

CREATE INDEX ix_raw_admission_admit_department
    ON raw.ods_raw_admission (admit_department_code);

CREATE INDEX ix_raw_admission_transfer_in_department
    ON raw.ods_raw_admission (transfer_in_department_code);

CREATE INDEX ix_raw_admission_transfer_out_department
    ON raw.ods_raw_admission (transfer_out_department_code);

CREATE INDEX ix_raw_admission_discharge_department
    ON raw.ods_raw_admission (discharge_department_code);

CREATE INDEX ix_raw_admission_invoice
    ON raw.ods_raw_admission (invoice_no);

CREATE INDEX ix_raw_admission_batch
    ON raw.ods_raw_admission (batch_id);

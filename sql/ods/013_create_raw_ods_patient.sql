CREATE TABLE raw.ods_raw_patient (
    raw_patient_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    patient_id              BIGINT NOT NULL,

    gender_code             VARCHAR(20),
    birth_date              DATE,

    province_id             BIGINT,
    district_id             BIGINT,

    nationality_code        VARCHAR(20),

    batch_id                BIGINT,

    ingested_at             TIMESTAMP WITHOUT TIME ZONE
                            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at              TIMESTAMP WITHOUT TIME ZONE
                            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_raw_patient_patient_id
        UNIQUE (patient_id),

    CONSTRAINT fk_raw_patient_batch
        FOREIGN KEY (batch_id)
        REFERENCES control.batch (batch_id)
);

CREATE INDEX ix_raw_patient_gender
    ON raw.ods_raw_patient (gender_code);

CREATE INDEX ix_raw_patient_birth_date
    ON raw.ods_raw_patient (birth_date);

CREATE INDEX ix_raw_patient_province
    ON raw.ods_raw_patient (province_id);

CREATE INDEX ix_raw_patient_district
    ON raw.ods_raw_patient (district_id);

CREATE INDEX ix_raw_patient_nationality
    ON raw.ods_raw_patient (nationality_code);

CREATE INDEX ix_raw_patient_batch
    ON raw.ods_raw_patient (batch_id);

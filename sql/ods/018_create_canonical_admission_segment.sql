CREATE TABLE canonical.admission_segment (
    admission_segment_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_system                 VARCHAR(50) NOT NULL,
    source_admission_id           BIGINT NOT NULL,

    patient_entity_id             BIGINT NOT NULL,
    encounter_id                  BIGINT,

    document_no                   BIGINT,

    object_id                     BIGINT,

    admit_at                      TIMESTAMP WITHOUT TIME ZONE,
    previous_admit_at             TIMESTAMP WITHOUT TIME ZONE,
    discharge_at                  TIMESTAMP WITHOUT TIME ZONE,
    treattime                     TIMESTAMP WITHOUT TIME ZONE,

    exam_department_code          VARCHAR(50),
    exam_department_id            BIGINT,

    admit_department_code         VARCHAR(50),
    admit_department_id           BIGINT,

    transfer_in_department_code   VARCHAR(50),
    transfer_in_department_id     BIGINT,

    transfer_out_department_code  VARCHAR(50),
    transfer_out_department_id    BIGINT,

    discharge_department_code     VARCHAR(50),
    discharge_department_id       BIGINT,

    doctor_code                   VARCHAR(100),
    doctor_id                     BIGINT,

    treatment_status              VARCHAR(30),
    suggestion_code               VARCHAR(30),

    is_outpatient_treatment       VARCHAR(1),
    is_emergency                  VARCHAR(1),

    source_invoice_no             BIGINT,

    created_at                    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_admission_segment_source
        UNIQUE (source_system, source_admission_id),

    CONSTRAINT fk_admission_segment_patient_entity
        FOREIGN KEY (patient_entity_id)
        REFERENCES identity.entity (entity_id),

    CONSTRAINT fk_admission_segment_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES canonical.encounter (encounter_id),

    CONSTRAINT fk_admission_segment_object
        FOREIGN KEY (object_id)
        REFERENCES reference.object (object_id),

    CONSTRAINT fk_admission_segment_exam_department
        FOREIGN KEY (exam_department_id)
        REFERENCES reference.department (department_id),

    CONSTRAINT fk_admission_segment_admit_department
        FOREIGN KEY (admit_department_id)
        REFERENCES reference.department (department_id),

    CONSTRAINT fk_admission_segment_transfer_in_department
        FOREIGN KEY (transfer_in_department_id)
        REFERENCES reference.department (department_id),

    CONSTRAINT fk_admission_segment_transfer_out_department
        FOREIGN KEY (transfer_out_department_id)
        REFERENCES reference.department (department_id),

    CONSTRAINT fk_admission_segment_discharge_department
        FOREIGN KEY (discharge_department_id)
        REFERENCES reference.department (department_id),

    CONSTRAINT fk_admission_segment_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES reference.employee (employee_id)
);

CREATE INDEX ix_admission_segment_patient_entity
    ON canonical.admission_segment (patient_entity_id);

CREATE INDEX ix_admission_segment_encounter
    ON canonical.admission_segment (encounter_id);

CREATE INDEX ix_admission_segment_document
    ON canonical.admission_segment (source_system, document_no);

CREATE INDEX ix_admission_segment_admit_at
    ON canonical.admission_segment (admit_at);

CREATE INDEX ix_admission_segment_discharge_at
    ON canonical.admission_segment (discharge_at);

CREATE INDEX ix_admission_segment_treattime
    ON canonical.admission_segment (treattime);

CREATE INDEX ix_admission_segment_exam_department
    ON canonical.admission_segment (exam_department_id);

CREATE INDEX ix_admission_segment_admit_department
    ON canonical.admission_segment (admit_department_id);

CREATE INDEX ix_admission_segment_transfer_in_department
    ON canonical.admission_segment (transfer_in_department_id);

CREATE INDEX ix_admission_segment_transfer_out_department
    ON canonical.admission_segment (transfer_out_department_id);

CREATE INDEX ix_admission_segment_discharge_department
    ON canonical.admission_segment (discharge_department_id);

CREATE INDEX ix_admission_segment_doctor
    ON canonical.admission_segment (doctor_id);

CREATE INDEX ix_admission_segment_source_invoice
    ON canonical.admission_segment (source_system, source_invoice_no);

CREATE INDEX ix_admission_segment_treatment_status
    ON canonical.admission_segment (treatment_status);

CREATE INDEX ix_admission_segment_object
    ON canonical.admission_segment (object_id);

GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE canonical.admission_segment
    TO hospital_ods_etl;

GRANT SELECT
    ON TABLE canonical.admission_segment
    TO hospital_ods_app;

GRANT USAGE, SELECT
    ON SEQUENCE canonical.admission_segment_admission_segment_id_seq
    TO hospital_ods_etl;

ALTER TABLE canonical.admission_segment
    OWNER TO postgres;

COMMENT ON TABLE canonical.admission_segment IS
'Canonical inpatient treatment segment. Grain: one ADMISSION_ID per source system. Source identity is (source_system, source_admission_id); admission_segment_id is the DW technical surrogate key.';

COMMENT ON COLUMN canonical.admission_segment.admission_segment_id IS
'Technical surrogate key for the canonical admission segment.';

COMMENT ON COLUMN canonical.admission_segment.source_system IS
'Source system owning the admission segment.';

COMMENT ON COLUMN canonical.admission_segment.source_admission_id IS
'Original ADMISSION_ID from the source system.';

COMMENT ON COLUMN canonical.admission_segment.patient_entity_id IS
'Canonical patient identity resolved through identity.entity and identity.source_map.';

COMMENT ON COLUMN canonical.admission_segment.encounter_id IS
'Canonical treatment episode to which this admission segment belongs. May remain NULL until encounter resolution is completed.';

COMMENT ON COLUMN canonical.admission_segment.exam_department_id IS
'Canonical department identity corresponding to the source EXAM_DEPARTMENT_CODE.';

COMMENT ON COLUMN canonical.admission_segment.admit_department_id IS
'Canonical department identity corresponding to the source ADMIT_DEPARTMENT_CODE.';

COMMENT ON COLUMN canonical.admission_segment.transfer_in_department_id IS
'Canonical department identity corresponding to the source TRANSFER_IN_DEPARTMENT_CODE.';

COMMENT ON COLUMN canonical.admission_segment.transfer_out_department_id IS
'Canonical department identity corresponding to the source TRANSFER_OUT_DEPARTMENT_CODE.';

COMMENT ON COLUMN canonical.admission_segment.discharge_department_id IS
'Canonical department identity corresponding to the source DISCHARGE_DEPARTMENT_CODE.';

COMMENT ON COLUMN canonical.admission_segment.doctor_id IS
'Canonical employee identity resolved from the source DOCTOR_CODE.';

COMMENT ON COLUMN canonical.admission_segment.object_id IS
'Canonical reference.object identity corresponding to the source OBJECT_ID.';

COMMENT ON COLUMN canonical.admission_segment.source_invoice_no IS
'Original invoice number supplied by the source admission record. It is retained for lineage and reconciliation and does not define the canonical invoice identity.';

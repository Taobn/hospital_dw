CREATE TABLE canonical.exam (
    exam_record_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_system               VARCHAR(50) NOT NULL,
    exam_id                     BIGINT NOT NULL,

    patient_entity_id           BIGINT NOT NULL,
    encounter_id               BIGINT,

    reception_by                VARCHAR(100),
    reception_at                TIMESTAMP WITHOUT TIME ZONE,

    document_no                 BIGINT,

    exam_at                     TIMESTAMP WITHOUT TIME ZONE,
    previous_exam_at            TIMESTAMP WITHOUT TIME ZONE,

    exam_type                   VARCHAR(50),
    status                      VARCHAR(30),
    document_status             VARCHAR(30),
    document_closed_at          TIMESTAMP WITHOUT TIME ZONE,

    reception_department_code   VARCHAR(50),
    reception_department_id     BIGINT,

    executing_department_code   VARCHAR(50),
    executing_department_id     BIGINT,

    room_id                     BIGINT,

    doctor_code                 VARCHAR(100),
    doctor_id                   BIGINT,

    object_id                   BIGINT,

    is_emergency                VARCHAR(1),

    suggestion_code             VARCHAR(30),

    treatment_accepted_at       TIMESTAMP WITHOUT TIME ZONE,

    admit_doctor_code           VARCHAR(100),
    admit_doctor_id             BIGINT,

    admit_department_code       VARCHAR(50),
    admit_department_id         BIGINT,

    document_created_at         TIMESTAMP WITHOUT TIME ZONE,
    previous_document_created_at TIMESTAMP WITHOUT TIME ZONE,

    created_at                  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_exam_source
        UNIQUE (source_system, exam_id),

    CONSTRAINT fk_exam_patient_entity
        FOREIGN KEY (patient_entity_id)
        REFERENCES identity.entity (entity_id),

    CONSTRAINT fk_exam_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES canonical.encounter (encounter_id),

    CONSTRAINT fk_exam_reception_department
        FOREIGN KEY (reception_department_id)
        REFERENCES reference.department (department_id),

    CONSTRAINT fk_exam_executing_department
        FOREIGN KEY (executing_department_id)
        REFERENCES reference.department (department_id),

    CONSTRAINT fk_exam_room
        FOREIGN KEY (room_id)
        REFERENCES reference.room (room_id),

    CONSTRAINT fk_exam_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES reference.employee (employee_id),

    CONSTRAINT fk_exam_object
        FOREIGN KEY (object_id)
        REFERENCES reference.object (object_id),

    CONSTRAINT fk_exam_admit_doctor
        FOREIGN KEY (admit_doctor_id)
        REFERENCES reference.employee (employee_id),

    CONSTRAINT fk_exam_admit_department
        FOREIGN KEY (admit_department_id)
        REFERENCES reference.department (department_id)
);

CREATE INDEX ix_exam_patient_entity
    ON canonical.exam (patient_entity_id);

CREATE INDEX ix_exam_encounter
    ON canonical.exam (encounter_id);

CREATE INDEX ix_exam_document
    ON canonical.exam (source_system, document_no);

CREATE INDEX ix_exam_exam_at
    ON canonical.exam (exam_at);

CREATE INDEX ix_exam_status
    ON canonical.exam (status);

CREATE INDEX ix_exam_document_status
    ON canonical.exam (document_status);

CREATE INDEX ix_exam_reception_department
    ON canonical.exam (reception_department_id);

CREATE INDEX ix_exam_executing_department
    ON canonical.exam (executing_department_id);

CREATE INDEX ix_exam_room
    ON canonical.exam (room_id);

CREATE INDEX ix_exam_doctor
    ON canonical.exam (doctor_id);

CREATE INDEX ix_exam_object
    ON canonical.exam (object_id);

CREATE INDEX ix_exam_admit_doctor
    ON canonical.exam (admit_doctor_id);

CREATE INDEX ix_exam_admit_department
    ON canonical.exam (admit_department_id);

CREATE INDEX ix_exam_treatment_accepted
    ON canonical.exam (treatment_accepted_at);

GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE canonical.exam
    TO hospital_ods_etl;

GRANT SELECT
    ON TABLE canonical.exam
    TO hospital_ods_app;

GRANT USAGE, SELECT
    ON SEQUENCE canonical.exam_exam_record_id_seq
    TO hospital_ods_etl;

ALTER TABLE canonical.exam
    OWNER TO postgres;

COMMENT ON TABLE canonical.exam IS
'Canonical examination record. Grain: one EXAM_ID per source system. Source identity is (source_system, exam_id); exam_record_id is the DW technical surrogate key.';

COMMENT ON COLUMN canonical.exam.exam_record_id IS
'Technical surrogate key for the canonical exam record.';

COMMENT ON COLUMN canonical.exam.source_system IS
'Source system owning the examination record.';

COMMENT ON COLUMN canonical.exam.exam_id IS
'Original EXAM_ID from the source system.';

COMMENT ON COLUMN canonical.exam.patient_entity_id IS
'Canonical patient identity resolved through identity.entity and identity.source_map.';

COMMENT ON COLUMN canonical.exam.encounter_id IS
'Canonical treatment episode to which this examination belongs. May remain NULL until encounter resolution is completed.';

COMMENT ON COLUMN canonical.exam.reception_department_id IS
'Canonical reference.department identity for the reception department.';

COMMENT ON COLUMN canonical.exam.executing_department_id IS
'Canonical reference.department identity for the department executing the examination.';

COMMENT ON COLUMN canonical.exam.doctor_id IS
'Canonical reference.employee identity resolved from the source doctor code.';

COMMENT ON COLUMN canonical.exam.room_id IS
'Canonical reference.room identity corresponding to the source ROOM_ID.';

COMMENT ON COLUMN canonical.exam.object_id IS
'Canonical reference.object identity corresponding to the source OBJECT_ID.';

COMMENT ON COLUMN canonical.exam.admit_doctor_id IS
'Canonical employee identity for the doctor responsible for admission, when available.';

COMMENT ON COLUMN canonical.exam.admit_department_id IS
'Canonical department identity for the admission department, when available.';

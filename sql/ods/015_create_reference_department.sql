CREATE TABLE reference.department (
    department_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_system              VARCHAR(50) NOT NULL,

    source_department_code     VARCHAR(100) NOT NULL,

    department_name            VARCHAR(200) NOT NULL,

    department_type            VARCHAR(30),

    parent_department_id       BIGINT,

    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,

    effective_from             DATE,

    effective_to               DATE,

    created_at                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_department_source
        UNIQUE (
            source_system,
            source_department_code
        ),

    CONSTRAINT fk_department_parent
        FOREIGN KEY (parent_department_id)
        REFERENCES reference.department (department_id),

    CONSTRAINT ck_department_effective_range
        CHECK (
            effective_to IS NULL
            OR effective_from IS NULL
            OR effective_to >= effective_from
        )
);

CREATE INDEX ix_department_source_system
    ON reference.department (source_system);

CREATE INDEX ix_department_active
    ON reference.department (is_active);

CREATE INDEX ix_department_parent
    ON reference.department (parent_department_id);

CREATE INDEX ix_department_type
    ON reference.department (department_type);

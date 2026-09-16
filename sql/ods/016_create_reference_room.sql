CREATE TABLE reference.room (
    room_id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_system            VARCHAR(50) NOT NULL,

    source_room_id           BIGINT NOT NULL,

    room_name                VARCHAR(200) NOT NULL,

    department_id            BIGINT,

    room_type                VARCHAR(30),

    is_active                BOOLEAN NOT NULL DEFAULT TRUE,

    effective_from           DATE,

    effective_to             DATE,

    created_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_room_source
        UNIQUE (
            source_system,
            source_room_id
        ),

    CONSTRAINT fk_room_department
        FOREIGN KEY (department_id)
        REFERENCES reference.department (department_id),

    CONSTRAINT ck_room_effective_range
        CHECK (
            effective_to IS NULL
            OR effective_from IS NULL
            OR effective_to >= effective_from
        )
);

CREATE INDEX ix_room_source_system
    ON reference.room (source_system);

CREATE INDEX ix_room_source_room_id
    ON reference.room (source_room_id);

CREATE INDEX ix_room_department
    ON reference.room (department_id);

CREATE INDEX ix_room_active
    ON reference.room (is_active);

CREATE INDEX ix_room_type
    ON reference.room (room_type);

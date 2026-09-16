BEGIN;

CREATE TABLE IF NOT EXISTS control.data_source_instance (
    source_instance_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    data_source_id           BIGINT NOT NULL,

    instance_code             VARCHAR(100) NOT NULL,
    instance_name             VARCHAR(200) NOT NULL,

    description               TEXT,

    -- Source connection / lineage metadata.
    -- Không lưu password/secret ở đây.
    database_type             VARCHAR(30),
    database_host             VARCHAR(255),
    database_port             INTEGER,
    database_name             VARCHAR(128),

    environment               VARCHAR(30) NOT NULL DEFAULT 'PROD',

    active_from               TIMESTAMPTZ,
    active_to                 TIMESTAMPTZ,

    is_active                 BOOLEAN NOT NULL DEFAULT TRUE,

    created_at                TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_data_source_instance_source
        FOREIGN KEY (data_source_id)
        REFERENCES control.data_source (data_source_id),

    CONSTRAINT uq_data_source_instance_code
        UNIQUE (data_source_id, instance_code),

    CONSTRAINT ck_data_source_instance_environment
        CHECK (
            environment IN (
                'DEV',
                'TEST',
                'UAT',
                'PROD',
                'OTHER'
            )
        ),

    CONSTRAINT ck_data_source_instance_port
        CHECK (
            database_port IS NULL
            OR database_port BETWEEN 1 AND 65535
        ),

    CONSTRAINT ck_data_source_instance_active_period
        CHECK (
            active_to IS NULL
            OR active_from IS NULL
            OR active_to >= active_from
        )
);

CREATE INDEX IF NOT EXISTS ix_data_source_instance_source
    ON control.data_source_instance (data_source_id);

CREATE INDEX IF NOT EXISTS ix_data_source_instance_active
    ON control.data_source_instance (is_active);

CREATE INDEX IF NOT EXISTS ix_data_source_instance_period
    ON control.data_source_instance (active_from, active_to);

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.data_source_instance
TO hospital_ods_etl;

GRANT SELECT
ON control.data_source_instance
TO hospital_ods_app;

COMMIT;

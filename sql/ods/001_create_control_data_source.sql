BEGIN;

DROP TABLE IF EXISTS control.data_source CASCADE;

CREATE TABLE control.data_source (
    data_source_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    source_code         VARCHAR(50)  NOT NULL,
    source_name         VARCHAR(200) NOT NULL,

    source_type         VARCHAR(30)  NOT NULL,

    description         TEXT,

    is_active           BOOLEAN NOT NULL DEFAULT TRUE,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_data_source_source_code
        UNIQUE (source_code),

    CONSTRAINT ck_data_source_source_type
        CHECK (
            source_type IN (
                'HIS',
                'ACCOUNTING',
                'HRM',
                'CRM',
                'OTHER'
            )
        )
);

COMMENT ON TABLE control.data_source IS
    'Logical business source system providing data to the Hospital ODS. Physical connections are managed by Apache Hop.';

COMMENT ON COLUMN control.data_source.source_code IS
    'Stable logical code of the source system, e.g. HIS, ACCOUNTING, HRM.';

COMMENT ON COLUMN control.data_source.source_type IS
    'Business source system type, not physical database/connection type. Physical connectivity is managed by Apache Hop.';

COMMENT ON COLUMN control.data_source.is_active IS
    'Whether this source system is currently active for ODS ingestion.';

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.data_source
TO hospital_ods_etl;

GRANT SELECT
ON control.data_source
TO hospital_ods_app;

COMMIT;

BEGIN;

INSERT INTO control.data_source_instance (
    data_source_id,
    instance_code,
    instance_name,
    description,
    database_type,
    database_host,
    database_port,
    database_name,
    environment,
    active_from,
    is_active
)
SELECT
    ds.data_source_id,
    'VIMES',
    'HMS HIS Current',
    'Current production HIS database instance used as source for ODS ingestion.',
    'ORACLE',
    '10.0.1.194',
    '1521',
    'DB108',
    'PROD',
    CURRENT_TIMESTAMP,
    TRUE
FROM control.data_source ds
WHERE ds.source_code = 'HIS'
ON CONFLICT (data_source_id, instance_code)
DO UPDATE SET
    instance_name = EXCLUDED.instance_name,
    description = EXCLUDED.description,
    database_type = EXCLUDED.database_type,
    database_host = EXCLUDED.database_host,
    database_port = EXCLUDED.database_port,
    database_name = EXCLUDED.database_name,
    environment = EXCLUDED.environment,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

COMMIT;

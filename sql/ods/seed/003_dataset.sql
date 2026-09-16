BEGIN;

INSERT INTO control.dataset (
    source_instance_id,
    dataset_code,
    dataset_name,
    description,
    resource_type,
    source_schema,
    source_object,
    refresh_mode,
    ingestion_config,
    source_schema_version,
    expected_latency_minutes,
    is_active
)
SELECT
    dsi.source_instance_id,
    'HIS_EXAM',
    'HIS Examination',
    'Source-aligned examination records extracted from HMS_EXAM. Business transformations and cross-entity enrichment are performed downstream in ODS.',
    'SQL',
    'VIMES',
    'HMS_EXAM',
    'INCREMENTAL',
    jsonb_build_object(
        'source_key', jsonb_build_array('HE_RECEPTIDX'),
        'target_key', jsonb_build_array('exam_id'),
        'incremental', jsonb_build_object(
            'strategy', 'WATERMARK',
            'cursor_column', 'HE_UPDATEDDATE',
            'cursor_data_type', 'TIMESTAMP'
        ),
        'schedule', jsonb_build_object(
            'frequency_minutes', 15
        ),
        'delete_strategy', 'NONE'
    ),
    NULL,
    15,
    TRUE
FROM control.data_source_instance dsi
JOIN control.data_source ds
    ON ds.data_source_id = dsi.data_source_id
WHERE ds.source_code = 'HIS'
  AND dsi.instance_code = 'VIMES'
ON CONFLICT (dataset_code)
DO UPDATE SET
    source_instance_id = EXCLUDED.source_instance_id,
    dataset_name = EXCLUDED.dataset_name,
    description = EXCLUDED.description,
    resource_type = EXCLUDED.resource_type,
    source_schema = EXCLUDED.source_schema,
    source_object = EXCLUDED.source_object,
    refresh_mode = EXCLUDED.refresh_mode,
    ingestion_config = EXCLUDED.ingestion_config,
    expected_latency_minutes = EXCLUDED.expected_latency_minutes,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

COMMIT;

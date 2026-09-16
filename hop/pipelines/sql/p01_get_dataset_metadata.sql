SELECT
    d.dataset_id,
    d.dataset_code,
    d.dataset_name,
    d.source_instance_id,
    d.source_schema,
    d.source_object,
    d.refresh_mode,
    d.ingestion_config,
    d.expected_latency_minutes
FROM control.dataset d
WHERE d.dataset_code = '${PRM_DATASET_CODE}'
  AND d.is_active = TRUE;

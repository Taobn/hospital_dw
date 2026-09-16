SELECT
    d.dataset_id,
    d.dataset_code,
    d.dataset_name,
    d.refresh_mode,
    d.resource_type,
    d.source_schema,
    d.source_object,
    d.ingestion_config,

    dsi.source_instance_id,
    dsi.instance_code,
    dsi.instance_name,
    dsi.database_type,
    dsi.database_host,
    dsi.database_port,
    dsi.database_name,

    ds.source_code,
    ds.source_name,

    dm.target_layer,
    dm.target_schema,
    dm.target_object,
    dm.mapping_role
FROM control.dataset d
JOIN control.data_source_instance dsi
    ON d.source_instance_id = dsi.source_instance_id
JOIN control.data_source ds
    ON dsi.data_source_id = ds.data_source_id
JOIN control.dataset_mapping dm
    ON d.dataset_id = dm.dataset_id
WHERE d.dataset_code = '${DATASET_CODE}'
  AND d.is_active = TRUE
  AND dsi.is_active = TRUE
  AND dm.is_active = TRUE;

SELECT
    dsi.source_instance_id,
    dsi.instance_code,
    dsi.instance_name,
    dsi.database_type,
    dsi.database_host,
    dsi.database_port,
    dsi.database_name,
    dsi.environment,
    dsi.is_active
FROM control.data_source_instance dsi
WHERE dsi.source_instance_id = ?
  AND dsi.is_active = TRUE;

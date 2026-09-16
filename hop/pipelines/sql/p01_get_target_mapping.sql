SELECT
    dataset_mapping_id,
    dataset_id,
    target_layer,
    target_schema,
    target_object,
    mapping_role
FROM control.dataset_mapping
WHERE dataset_id = ?
  AND target_layer = 'RAW'
  AND is_active = TRUE
ORDER BY mapping_role, dataset_mapping_id;

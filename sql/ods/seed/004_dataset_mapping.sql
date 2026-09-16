BEGIN;

INSERT INTO control.dataset_mapping (
    dataset_id,
    target_layer,
    target_schema,
    target_object,
    mapping_role,
    is_active,
    description
)
SELECT
    d.dataset_id,
    'RAW',
    'raw',
    'ods_raw_exam',
    'PRIMARY',
    TRUE,
    'Primary RAW ODS target for HIS examination dataset.'
FROM control.dataset d
WHERE d.dataset_code = 'HIS_EXAM'
ON CONFLICT (
    dataset_id,
    target_layer,
    target_schema,
    target_object
)
DO UPDATE SET
    mapping_role = EXCLUDED.mapping_role,
    is_active = EXCLUDED.is_active,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

COMMIT;

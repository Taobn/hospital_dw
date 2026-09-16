BEGIN;

INSERT INTO control.watermark (
    dataset_id,
    watermark_type,
    watermark_column,
    last_value_text,
    last_value_timestamp,
    last_value_numeric,
    last_batch_id,
    initialized_at,
    is_active,
    description
)
SELECT
    d.dataset_id,
    'TIMESTAMP',
    'HE_UPDATEDDATE',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    TRUE,
    'Incremental extraction watermark for HIS_EXAM. Initial state is uninitialized; the first successful ingestion batch establishes the watermark.'
FROM control.dataset d
WHERE d.dataset_code = 'HIS_EXAM'
  AND d.refresh_mode = 'INCREMENTAL'
ON CONFLICT (dataset_id)
DO UPDATE SET
    watermark_type = EXCLUDED.watermark_type,
    watermark_column = EXCLUDED.watermark_column,
    is_active = EXCLUDED.is_active,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

COMMIT;

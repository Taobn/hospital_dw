SELECT
    watermark_id,
    dataset_id,
    watermark_type,
    watermark_column,
    last_value_timestamp,
    last_value_numeric,
    last_value_text,
    last_batch_id,
    initialized_at
FROM control.watermark
WHERE dataset_id = ?
  AND is_active = TRUE;

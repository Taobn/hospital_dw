UPDATE control.batch b
SET status = 'FAILED',
    completed_at = CURRENT_TIMESTAMP,
	error_message = 'Timeout'
FROM control.dataset d
WHERE d.dataset_id = b.dataset_id
  AND d.dataset_code = '${PRM_DATASET_CODE}'
  AND b.status = 'RUNNING'
  AND b.started_at < CURRENT_TIMESTAMP - INTERVAL '60 minutes';

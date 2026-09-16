BEGIN;

INSERT INTO control.data_source (
    source_code,
    source_name,
    source_type,
    description,
    is_active
)
VALUES
(
    'HIS',
    'Hospital Information System',
    'HIS',
    'Primary hospital operational source system providing patient, examination, admission, clinical and related hospital transaction data.',
    TRUE
),
(
    'ACCOUNTING',
    'Accounting System',
    'ACCOUNTING',
    'Logical accounting source system providing financial and accounting data for future ODS integration.',
    TRUE
),
(
    'HRM',
    'Human Resource Management',
    'HRM',
    'Logical human resource management source system providing employee and organizational data for future ODS integration.',
    TRUE
),
(
    'CRM',
    'Customer Relationship Management',
    'CRM',
    'Logical customer relationship management source system for future ODS integration.',
    TRUE
)
ON CONFLICT (source_code)
DO UPDATE SET
    source_name = EXCLUDED.source_name,
    source_type = EXCLUDED.source_type,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

COMMIT;

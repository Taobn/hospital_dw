BEGIN;

WITH dataset AS (
    SELECT dataset_id
    FROM control.dataset
    WHERE dataset_code = 'HIS_EXAM'
),
mapping (
    ordinal_position,
    source_field_name,
    target_field_name,
    source_data_type,
    target_data_type,
    mapping_role,
    description
) AS (
    VALUES

    -- =========================================================
    -- IDENTITY / LINKAGE
    -- =========================================================

    ( 1, 'HE_RECEPTNO',
        'reception_no',
        'INTEGER', 'INTEGER', 'DIRECT',
        'HIS reception number.'),

    ( 2, 'HE_RECEPTIDX',
        'exam_id',
        'INTEGER', 'BIGINT', 'CAST',
        'Primary HIS examination identity.'),

    ( 3, 'HE_PATIENTNO',
        'patient_id',
        'INTEGER', 'BIGINT', 'CAST',
        'HIS patient identifier.'),

    ( 4, 'HE_DOCNO',
        'document_no',
        'INTEGER', 'BIGINT', 'CAST',
        'HIS document/grouping identifier; not encounter identity.'),

    -- =========================================================
    -- SOURCE AUDIT / CHANGE TRACKING
    -- =========================================================

    ( 5, 'HE_CREATEDBY',
        'created_by',
        'VARCHAR2(15)', 'VARCHAR(15)', 'DIRECT',
        'Source creator identifier.'),

    ( 6, 'HE_CREATEDDATE',
        'created_date',
        'TIMESTAMP', 'TIMESTAMP(6)', 'DIRECT',
        'Source creation timestamp.'),

    ( 7, 'HE_UPDATEDBY',
        'updated_by',
        'VARCHAR2(15)', 'VARCHAR(15)', 'DIRECT',
        'Source last updater identifier.'),

    ( 8, 'HE_UPDATEDDATE',
        'updated_date',
        'TIMESTAMP', 'TIMESTAMP(6)', 'DIRECT',
        'Source update timestamp and incremental cursor.'),

    -- =========================================================
    -- ORGANIZATION / LOCATION
    -- =========================================================

    ( 9, 'HE_DEPTID',
        'department_code',
        'VARCHAR2(7)', 'VARCHAR(10)', 'DIRECT',
        'Source department identifier.'),

    (10, 'HE_ROOMID',
        'room_id',
        'INTEGER', 'BIGINT', 'CAST',
        'Source room identifier.'),

    -- =========================================================
    -- EXAMINATION
    -- =========================================================

    (11, 'HE_EXAMTYPE',
        'exam_type',
        'VARCHAR2(13)', 'VARCHAR(13)', 'DIRECT',
        'Source examination type.'),

    (12, 'HE_STATUS',
        'exam_status',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source examination status.'),

    (13, 'HE_EXAMDATE',
        'exam_date',
        'TIMESTAMP', 'TIMESTAMP(6)', 'DIRECT',
        'Source examination timestamp.'),

    (14, 'HE_DOCTOR',
        'doctor_code',
        'VARCHAR2(15)', 'VARCHAR(15)', 'DIRECT',
        'Source doctor identifier.'),

    -- =========================================================
    -- STRUCTURED CLINICAL MEASUREMENTS
    -- =========================================================

    (15, 'HE_PULSE',
        'pulse',
        'NUMBER', 'NUMERIC', 'CAST',
        'Pulse measurement.'),

    (16, 'HE_TEMPERATURE',
        'temperature',
        'NUMBER', 'NUMERIC', 'CAST',
        'Temperature measurement.'),

    (17, 'HE_BLOODPRESSURE',
        'blood_pressure',
        'INTEGER', 'INTEGER', 'DIRECT',
        'Blood pressure value.'),

    (18, 'HE_BLOODPRESSUREX',
        'blood_pressure_x',
        'INTEGER', 'INTEGER', 'DIRECT',
        'Secondary blood pressure value.'),

    (19, 'HE_BREATHINTERVAL',
        'breath_interval',
        'NUMBER', 'NUMERIC', 'CAST',
        'Breathing interval measurement.'),

    (20, 'HE_WEIGHT',
        'weight',
        'NUMBER', 'NUMERIC', 'CAST',
        'Patient weight measurement.'),

    (21, 'HE_HEIGHT',
        'height',
        'NUMBER', 'NUMERIC', 'CAST',
        'Patient height measurement.'),

    (22, 'HE_BMI',
        'bmi',
        'NUMBER', 'NUMERIC', 'CAST',
        'Body mass index.'),

    (23, 'HE_THOI_GIAN_DO_HUYETAP',
        'blood_pressure_measured_at',
        'TIMESTAMP', 'TIMESTAMP(6)', 'DIRECT',
        'Blood pressure measurement timestamp.'),

    -- =========================================================
    -- DIAGNOSIS / CLASSIFICATION
    -- =========================================================

    (24, 'HE_ICD10',
        'icd10_code',
        'VARCHAR2(15)', 'VARCHAR(15)', 'DIRECT',
        'Source ICD-10 code.'),

    (25, 'HE_TYPEID',
        'type_id',
        'INTEGER', 'INTEGER', 'DIRECT',
        'Source examination type identifier.'),

    (26, 'HE_EXAMTYPE3',
        'exam_type_3',
        'VARCHAR2(2)', 'VARCHAR(2)', 'DIRECT',
        'Source examination type level 3.'),

    (27, 'HE_DETAIL_EXAMTYPE3',
        'detail_exam_type_3',
        'VARCHAR2(2)', 'VARCHAR(2)', 'DIRECT',
        'Source detailed examination type level 3.'),

    -- =========================================================
    -- BILLING / PAYMENT
    -- =========================================================

    (28, 'HE_HASFEE',
        'has_fee',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source fee existence flag.'),

    (29, 'HE_PAYMENT',
        'payment_status',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source payment status.'),

    (30, 'HFE_REFROWID',
        'fee_ref_row_id',
        'INTEGER', 'BIGINT', 'CAST',
        'Source fee reference row identifier.'),

    (31, 'HFE_REFSTATUS',
        'fee_ref_status',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source fee reference status.'),

    (32, 'HE_FEEIDX',
        'fee_idx',
        'INTEGER', 'BIGINT', 'CAST',
        'Source fee identifier.'),

    (33, 'HE_PAIDFOR',
        'paid_for',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source paid-for indicator.'),

    -- =========================================================
    -- WORKFLOW / FLAGS
    -- =========================================================

    (34, 'HE_EMERGENCY',
        'is_emergency',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Emergency examination flag.'),

    (35, 'HE_PRIORITY',
        'priority',
        'INTEGER', 'INTEGER', 'DIRECT',
        'Source examination priority.'),

    (36, 'HE_EXAMMOVE',
        'exam_move_flag',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source examination movement flag.'),

    (37, 'HE_HATD',
        'hatd_flag',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source HATD flag; semantics intentionally not inferred.'),

    (38, 'HE_ISJO',
        'isjo_flag',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source ISJO flag; semantics intentionally not inferred.'),

    (39, 'HE_ISREQ',
        'isreq_flag',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source ISREQ flag; semantics intentionally not inferred.'),

    (40, 'HE_REEXAM',
        'reexam_flag',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Re-examination flag.'),

    -- =========================================================
    -- FORWARD / REFERRAL
    -- =========================================================

    (41, 'HE_FDEPTID',
        'forward_department_code',
        'VARCHAR2(10)', 'VARCHAR(10)', 'DIRECT',
        'Forward/referred department identifier.'),

    (42, 'HE_FROOMID',
        'forward_room_id',
        'INTEGER', 'BIGINT', 'CAST',
        'Forward/referred room identifier.'),

    (43, 'HE_FRECEPTIDX',
        'forward_reception_idx',
        'INTEGER', 'BIGINT', 'CAST',
        'Forward/referred reception/examination identifier.'),

    -- =========================================================
    -- OTHER STRUCTURED ATTRIBUTES
    -- =========================================================

    (44, 'HE_ZONE',
        'zone',
        'VARCHAR2(15)', 'VARCHAR(15)', 'DIRECT',
        'Source zone value.'),

    (45, 'HE_CANCELBY',
        'cancel_by',
        'VARCHAR2(15)', 'VARCHAR(15)', 'DIRECT',
        'Source cancellation user.'),

    (46, 'HE_TREATTIME',
        'treatment_time',
        'INTEGER', 'INTEGER', 'DIRECT',
        'Source treatment time.'),

    (47, 'HE_HASALLERGY',
        'has_allergy',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Allergy indicator.'),

    (48, 'HE_IN_OUT_PKG',
        'in_out_package',
        'VARCHAR2(3)', 'VARCHAR(3)', 'DIRECT',
        'Source inpatient/outpatient package indicator.'),

    (49, 'HE_PARTS',
        'body_parts',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Source body parts indicator.'),

    (50, 'SANG_CHIEU',
        'shift_code',
        'VARCHAR2(2)', 'VARCHAR(2)', 'DIRECT',
        'Source shift code.'),

    (51, 'HE_ROOMKEY',
        'room_key',
        'INTEGER', 'BIGINT', 'CAST',
        'Source room technical key.'),

    -- =========================================================
    -- NURSING / STAFF
    -- =========================================================

    (52, 'HE_HEAD_NURSE',
        'head_nurse_code',
        'VARCHAR2(15)', 'VARCHAR(15)', 'DIRECT',
        'Source head nurse identifier.'),

    (53, 'HE_NURSE',
        'nurse_code',
        'VARCHAR2(15)', 'VARCHAR(15)', 'DIRECT',
        'Source nurse identifier.'),

    -- =========================================================
    -- EXAMINATION CLASSIFICATION
    -- =========================================================

    (54, 'HE_IS_HEALTH_EXAM',
        'is_health_exam',
        'CHAR(1)', 'CHAR(1)', 'DIRECT',
        'Health examination indicator.')
)

INSERT INTO control.dataset_column_mapping (
    dataset_id,
    source_field_name,
    target_layer,
    target_schema,
    target_object,
    target_field_name,
    source_data_type,
    target_data_type,
    mapping_expression,
    mapping_role,
    ordinal_position,
    is_nullable,
    is_active,
    description
)
SELECT
    d.dataset_id,
    m.source_field_name,
    'RAW',
    'raw',
    'ods_raw_exam',
    m.target_field_name,
    m.source_data_type,
    m.target_data_type,
    NULL,
    m.mapping_role,
    m.ordinal_position,
    TRUE,
    TRUE,
    m.description
FROM dataset d
CROSS JOIN mapping m

ON CONFLICT (
    dataset_id,
    target_layer,
    target_schema,
    target_object,
    source_field_name,
    target_field_name
)
DO UPDATE SET
    source_data_type = EXCLUDED.source_data_type,
    target_data_type = EXCLUDED.target_data_type,
    mapping_expression = EXCLUDED.mapping_expression,
    mapping_role = EXCLUDED.mapping_role,
    ordinal_position = EXCLUDED.ordinal_position,
    is_nullable = EXCLUDED.is_nullable,
    is_active = EXCLUDED.is_active,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

COMMIT;

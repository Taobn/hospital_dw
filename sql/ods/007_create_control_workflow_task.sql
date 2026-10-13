BEGIN;

CREATE TABLE control.workflow_task (
    workflow_task_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    workflow_code          VARCHAR(50) NOT NULL,
    task_code              VARCHAR(50) NOT NULL,

    execution_order        INTEGER NOT NULL,
    execution_type         VARCHAR(30) NOT NULL DEFAULT 'PIPELINE',
    execution_ref          VARCHAR(256) NOT NULL,

    is_enabled             BOOLEAN NOT NULL DEFAULT TRUE,

    created_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_workflow_task_task
        FOREIGN KEY (task_code)
        REFERENCES control.task_definition (task_code)
        ON DELETE RESTRICT,

    CONSTRAINT uq_workflow_task_code
        UNIQUE (
            workflow_code,
            task_code
        ),

    CONSTRAINT uq_workflow_task_order
        UNIQUE (
            workflow_code,
            execution_order
        ),

    CONSTRAINT ck_workflow_task_execution_order
        CHECK (
            execution_order > 0
        ),
        
    CONSTRAINT ck_workflow_task_execution_type
        CHECK (
            execution_type IN (
                'PIPELINE',
                'WORKFLOW'
            )
        ),

    CONSTRAINT ck_workflow_task_execution_ref
        CHECK (BTRIM(execution_ref) <> '')
);

COMMENT ON TABLE control.workflow_task IS
    'Configuration of logical tasks belonging to a workflow. Defines which tasks participate in a workflow and their execution order.';

COMMENT ON COLUMN control.workflow_task.workflow_code IS
    'Logical workflow identifier. The workflow definition itself may be maintained by Apache Hop or the control metadata layer.';

COMMENT ON COLUMN control.workflow_task.task_code IS
    'Logical task referenced from control.task_definition.';

COMMENT ON COLUMN control.workflow_task.execution_order IS
    'Execution order of the task within the workflow.';

COMMENT ON COLUMN control.workflow_task.is_enabled IS
    'Whether this task is currently enabled in the workflow configuration.';

CREATE INDEX ix_workflow_task_task
    ON control.workflow_task (task_code);

CREATE INDEX ix_workflow_task_workflow
    ON control.workflow_task (workflow_code, execution_order);

GRANT SELECT, INSERT, UPDATE, DELETE
ON control.workflow_task
TO hospital_ods_etl;

GRANT SELECT
ON control.workflow_task
TO hospital_ods_app;

COMMIT;

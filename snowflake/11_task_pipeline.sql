-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Precision Agriculture & Yield Forecasting
-- ============================================================================
USE DATABASE PALM_OIL_PRECISION_AG;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_INGEST_SENSORS
  WAREHOUSE = PRECISION_AG_WH
  SCHEDULE = 'USING CRON */15 * * * * UTC'
  COMMENT = 'Ingest latest IoT sensor readings'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_RETRAIN_MODELS
  WAREHOUSE = PRECISION_AG_WH
  SCHEDULE = 'USING CRON 0 0 * * 0 UTC'
  COMMENT = 'Retrain ML models weekly'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_ANALYZE_IMAGERY
  WAREHOUSE = PRECISION_AG_WH
  AFTER APP.TASK_RETRAIN_MODELS
  COMMENT = 'Run multimodal analysis on new drone imagery'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_ANALYZE_IMAGERY RESUME;
ALTER TASK APP.TASK_RETRAIN_MODELS RESUME;
ALTER TASK APP.TASK_INGEST_SENSORS RESUME;

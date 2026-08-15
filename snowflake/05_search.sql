-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Precision Agriculture & Yield Forecasting
-- ============================================================================
USE DATABASE PALM_OIL_PRECISION_AG;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.AGRONOMY_KNOWLEDGE_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, CROP_STAGE, TOPIC
  WAREHOUSE = PRECISION_AG_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.AGRONOMY_DOCS
);

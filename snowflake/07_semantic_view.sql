-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Precision Agriculture & Yield Forecasting
-- ============================================================================
USE DATABASE PALM_OIL_PRECISION_AG;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.PRECISION_AG_ANALYTICS
  COMMENT = 'Palm oil yield, soil health, and agronomy analytics'
AS
  TABLES (
    CURATED.ESTATE_YIELD_SUMMARY AS estate_yield_summary,CURATED.YIELD_TIMESERIES AS yield_timeseries,CURATED.SOIL_HEALTH_INDEX AS soil_health_index,CURATED.PEST_DISEASE_ALERTS AS pest_disease_alerts
  );

-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Precision Agriculture & Yield Forecasting
-- ============================================================================
USE DATABASE PALM_OIL_PRECISION_AG;
USE SCHEMA CURATED;

-- ESTATE_YIELD_SUMMARY: Estate-level FFB yield performance vs MPOB targets
-- Source: ESTATES, HARVEST_RECORDS
CREATE OR REPLACE DYNAMIC TABLE CURATED.ESTATE_YIELD_SUMMARY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PRECISION_AG_WH
AS
SELECT * FROM RAW.ESTATES;
-- TODO: Replace with actual join/aggregation logic per demo

-- YIELD_TIMESERIES: Monthly FFB yield by estate for ML.FORECAST input
-- Source: HARVEST_RECORDS
CREATE OR REPLACE DYNAMIC TABLE CURATED.YIELD_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PRECISION_AG_WH
AS
SELECT * FROM RAW.HARVEST_RECORDS;
-- TODO: Replace with actual join/aggregation logic per demo

-- SOIL_HEALTH_INDEX: Soil nutrient status and irrigation recommendations per block
-- Source: SENSOR_READINGS, ESTATES
CREATE OR REPLACE DYNAMIC TABLE CURATED.SOIL_HEALTH_INDEX
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PRECISION_AG_WH
AS
SELECT * FROM RAW.SENSOR_READINGS;
-- TODO: Replace with actual join/aggregation logic per demo

-- PEST_DISEASE_ALERTS: Anomalous sensor patterns indicating pest or disease
-- Source: SENSOR_READINGS, DRONE_IMAGERY
CREATE OR REPLACE DYNAMIC TABLE CURATED.PEST_DISEASE_ALERTS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = PRECISION_AG_WH
AS
SELECT * FROM RAW.SENSOR_READINGS;
-- TODO: Replace with actual join/aggregation logic per demo


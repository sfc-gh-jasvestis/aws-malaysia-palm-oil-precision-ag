-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Precision Agriculture & Yield Forecasting
-- Country: MALAYSIA | Currency: MYR
-- ============================================================================
USE DATABASE PALM_OIL_PRECISION_AG;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- ESTATES: 50 rows — Oil palm estates with location, planted area, and palm age profile
-- SENSOR_READINGS: 200,000 rows — IoT soil sensors (moisture, pH, NPK, temperature) at 15-min intervals
-- HARVEST_RECORDS: 100,000 rows — Fresh Fruit Bunch (FFB) harvest records by block and round
-- WEATHER_DATA: 365 rows — Daily weather (rainfall, temperature, humidity) per estate region
-- AGRONOMY_DOCS: 80 rows — MPOB best practice guides, fertilizer recommendations, pest management SOPs
-- DRONE_IMAGERY: 2,000 rows — Drone and satellite NDVI imagery metadata with stage file references
-- FELDA_BENCHMARKS: 20 rows — FELDA and MPOB national yield benchmarks by palm age

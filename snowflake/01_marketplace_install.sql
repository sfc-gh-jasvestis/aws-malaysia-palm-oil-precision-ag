-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Precision Agriculture & Yield Forecasting
-- ============================================================================
USE DATABASE PALM_OIL_PRECISION_AG;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): OnPoint Historical Weather
--   Real data: https://app.snowflake.com/marketplace/listing/GZSOZBT22EH
--   Using mock table: WEATHER_DATA
CREATE TABLE IF NOT EXISTS RAW.WEATHER_DATA (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Paid listing (mock): CEIC ASEAN Macro
--   Real data: https://app.snowflake.com/marketplace/listing/GZTSZRC7HPI
--   Using mock table: FELDA_BENCHMARKS
CREATE TABLE IF NOT EXISTS RAW.FELDA_BENCHMARKS (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);


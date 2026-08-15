-- ============================================================================
-- Precision Agriculture & Yield Forecasting
-- IoT-powered precision farming for Malaysian palm oil estates — soil sensors stream to Snowflake, ML.FORECAST predicts Fresh Fruit Bunch yields, and Cortex Complete analyzes drone imagery for nutrient deficiency.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS PALM_OIL_PRECISION_AG;
CREATE WAREHOUSE IF NOT EXISTS PRECISION_AG_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE PALM_OIL_PRECISION_AG;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE PRECISION_AG_WH;

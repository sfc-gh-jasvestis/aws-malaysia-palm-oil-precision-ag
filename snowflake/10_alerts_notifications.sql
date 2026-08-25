-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Precision Agriculture & Yield Forecasting
-- ============================================================================
USE DATABASE PALM_OIL_PRECISION_AG;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_malaysia_palm_oil_precision_ag_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: YIELD_BELOW_TARGET_ALERT
CREATE OR REPLACE ALERT APP.YIELD_BELOW_TARGET_ALERT
  WAREHOUSE = PRECISION_AG_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Estate FFB yield below MPOB minimum threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.ESTATE_YIELD_SUMMARY
  WHERE 1=1 -- Condition: FFB_YIELD_TONNES_HA < 20 for any estate
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_palm_oil_precision_ag_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Precision Agriculture & Yield Forecasting: Estate FFB yield below MPOB minimum threshold',
    'Estate FFB yield below MPOB minimum threshold'
  );

ALTER ALERT APP.YIELD_BELOW_TARGET_ALERT RESUME;

-- Alert: SOIL_ANOMALY_ALERT
CREATE OR REPLACE ALERT APP.SOIL_ANOMALY_ALERT
  WAREHOUSE = PRECISION_AG_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Soil sensor anomaly detected — possible pest/disease'
IF (EXISTS (
  SELECT 1 FROM CURATED.ESTATE_YIELD_SUMMARY
  WHERE 1=1 -- Condition: ANOMALY_SCORE > 0.9 for any block
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_palm_oil_precision_ag_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Precision Agriculture & Yield Forecasting: Soil sensor anomaly detected — possible pest/disease',
    'Soil sensor anomaly detected — possible pest/disease'
  );

ALTER ALERT APP.SOIL_ANOMALY_ALERT RESUME;


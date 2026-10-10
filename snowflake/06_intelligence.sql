-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TELEMETRY.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic agronomy knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.AGRONOMY_SOP_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, s.CATEGORY
  FROM RAW.BLOCK_DAILY r JOIN RAW.BLOCKS s ON s.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.CROP_LOSS_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' crop-loss response' AS TITLE,
  'Synthetic demo SOP. Block category: ' || CATEGORY || '. Crop-loss cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: tell the estate agronomist on duty, record the event in the block log and have the field supervisor confirm it on the ground. '
  || 'Step 2: ' || CASE
       WHEN ROOT_CAUSE ILIKE '%rat%' THEN 'set bait stations along the harvest paths, check barn owl nest boxes and re-census fresh damage after 7 days.'
       WHEN ROOT_CAUSE ILIKE '%beetle%' THEN 'remove breeding sites in chipped trunks and empty fruit bunch heaps, and set pheromone traps across the block.'
       WHEN ROOT_CAUSE ILIKE '%weed%' THEN 'bring the circle and path weeding round forward and clear weeds around young palms.'
       WHEN ROOT_CAUSE ILIKE '%potassium%' THEN 'take leaf and soil samples, and schedule a corrective fertilizer round once the samples are back.'
       WHEN ROOT_CAUSE ILIKE '%harvest round%' THEN 'add a harvesting team to the block until the round interval is back on schedule and collect loose fruit.'
       WHEN ROOT_CAUSE ILIKE '%stem rot%' THEN 'mark affected palms, census neighbouring palms for early symptoms and flag the block for the replanting review.'
       WHEN ROOT_CAUSE ILIKE '%tall palm%' THEN 'assign long-pole harvesters and check that loose fruit is collected after each round.'
       WHEN ROOT_CAUSE ILIKE '%water table%' OR ROOT_CAUSE ILIKE '%leaning%' THEN 'close or raise the block drain weirs to lift the water table and check the drain level sensors daily.'
       WHEN ROOT_CAUSE ILIKE '%dry spell%' THEN 'prioritise mulching with empty fruit bunches, delay fertilizer until rain returns and watch soil moisture sensors.'
       WHEN ROOT_CAUSE ILIKE '%waterlogging%' OR ROOT_CAUSE ILIKE '%flood%' THEN 'open the outlet drains in sequence, pause harvesting on flooded paths and recheck the drain level after 48 hours.'
       WHEN ROOT_CAUSE ILIKE '%bagworm%' THEN 'run a census of larvae per frond, mark the infested area and agree targeted control with the estate agronomist.'
       ELSE 'document the issue, isolate the source and raise it with the regional agronomy manager.'
     END
  || ' Step 3: if the soil moisture deficit stays above 80 mm or the drain level above 90% after the response, keep the block on the watch list. '
  || 'Step 4: confirm that the ripe bunch rate has recovered and record the root cause in the block register.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.AGRONOMY_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.AGRONOMY_SOP_DOCS);

-- ---------- Soil moisture deficit anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.MOISTURE_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, MOISTURE_DEFICIT_MM::FLOAT AS MOISTURE_DEFICIT
FROM RAW.BLOCK_DAILY;
CREATE OR REPLACE VIEW ML.MOISTURE_TRAIN AS
SELECT * FROM ML.MOISTURE_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.MOISTURE_SERIES);
CREATE OR REPLACE VIEW ML.MOISTURE_DETECT AS
SELECT * FROM ML.MOISTURE_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.MOISTURE_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.MOISTURE_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.MOISTURE_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'MOISTURE_DEFICIT',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.MOISTURE_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS MOISTURE_DEFICIT, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.MOISTURE_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.MOISTURE_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'MOISTURE_DEFICIT'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.AGRONOMY_ANALYTICS
  TABLES (
    blocks AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'blocks', 'fields', 'plantation blocks')
      COMMENT = 'One row per oil palm block (entity), 90-day totals',
    risk AS ML.CROP_LOSS_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day crop-loss event probability per block',
    causes AS CURATED.CROP_LOSS_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'Crop-loss events by root cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Grower-wide totals per day'
  )
  RELATIONSHIPS (risk_block AS risk (ENTITY_ID) REFERENCES blocks)
  FACTS (
    blocks.ripe_bunches_f AS RIPE_BUNCHES,
    blocks.bunches_graded_f AS BUNCHES_GRADED,
    blocks.ffb_tonnes_f AS FFB_TONNES,
    blocks.fertilizer_kg_f AS FERTILIZER_KG,
    blocks.pest_alerts_f AS PEST_ALERTS,
    blocks.crop_losses_f AS CROP_LOSS_COUNT,
    blocks.downtime_hours_f AS DOWNTIME_HOURS,
    blocks.operating_hours_f AS OPERATING_HOURS,
    blocks.planned_hours_f AS PLANNED_HOURS,
    risk.crop_loss_prob_f AS CROP_LOSS_PROB_7D,
    causes.cause_crop_losses_f AS CROP_LOSS_COUNT,
    causes.cause_unripe_f AS UNRIPE_BUNCHES,
    causes.cause_hours_f AS DOWNTIME_HOURS,
    daily.day_ripe_f AS RIPE_BUNCHES,
    daily.day_graded_f AS BUNCHES_GRADED,
    daily.day_ffb_f AS FFB_TONNES,
    daily.day_crop_losses_f AS CROP_LOSS_COUNT
  )
  DIMENSIONS (
    blocks.block_id AS ENTITY_ID WITH SYNONYMS = ('block', 'entity', 'entity id', 'block id'),
    blocks.block_name AS ENTITY_NAME,
    blocks.estate_region AS REGION WITH SYNONYMS = ('region', 'city', 'estate region') COMMENT = 'Malaysian city the estate is near',
    blocks.block_category AS CATEGORY WITH SYNONYMS = ('block category', 'palm age class', 'category'),
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    blocks.block_count AS COUNT(blocks.block_id) WITH SYNONYMS = ('number of entities', 'entity count', 'number of blocks'),
    blocks.ripe_bunch_rate_pct AS 100 * SUM(blocks.ripe_bunches_f) / NULLIF(SUM(blocks.bunches_graded_f), 0)
      WITH SYNONYMS = ('ripe bunch rate', 'ripeness', 'bunches graded ripe') COMMENT = 'Bunches graded ripe / bunches graded',
    blocks.total_crop_losses AS SUM(blocks.crop_losses_f) WITH SYNONYMS = ('crop losses', 'crop-loss events'),
    blocks.fertilizer_intensity_kg_per_t AS SUM(blocks.fertilizer_kg_f) / NULLIF(SUM(blocks.ffb_tonnes_f), 0)
      WITH SYNONYMS = ('fertilizer intensity', 'fertilizer per tonne') COMMENT = 'kg fertilizer per tonne of FFB harvested',
    blocks.total_fertilizer_kg AS SUM(blocks.fertilizer_kg_f) WITH SYNONYMS = ('fertilizer applied', 'total fertilizer'),
    blocks.total_ffb_tonnes AS SUM(blocks.ffb_tonnes_f) WITH SYNONYMS = ('FFB harvested', 'harvest tonnes', 'yield'),
    blocks.total_pest_alerts AS SUM(blocks.pest_alerts_f) WITH SYNONYMS = ('pest alerts', 'scouting alerts'),
    blocks.sensor_network_uptime_pct AS 100 * SUM(blocks.operating_hours_f) / NULLIF(SUM(blocks.planned_hours_f), 0),
    blocks.total_downtime_hours AS SUM(blocks.downtime_hours_f),
    risk.avg_crop_loss_prob AS AVG(risk.crop_loss_prob_f),
    causes.cause_crop_losses AS SUM(causes.cause_crop_losses_f),
    causes.cause_unripe_bunches AS SUM(causes.cause_unripe_f),
    causes.cause_downtime_hours AS SUM(causes.cause_hours_f),
    daily.daily_ripe_bunch_rate_pct AS 100 * SUM(daily.day_ripe_f) / NULLIF(SUM(daily.day_graded_f), 0),
    daily.daily_ffb_tonnes AS SUM(daily.day_ffb_f),
    daily.daily_crop_losses AS SUM(daily.day_crop_losses_f)
  )
  COMMENT = 'Synthetic Malaysia oil palm precision agriculture analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.AGRONOMY_AGENT
  COMMENT = 'Agronomy assistant over a synthetic Malaysian oil palm grower'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Use only what the tools return. Say that the data is synthetic and that thresholds are demo settings, not agronomic standards. Quote block IDs, and give every number with its unit."
  orchestration: "Use agronomy_analyst for ripe bunch rate, crop-loss events, FFB harvested, fertilizer intensity, pest alerts, sensor network uptime, blocks, regions, risk and root causes. Use sop_search for crop-loss response procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: agronomy_analyst
      description: "Ripe bunch rate, crop-loss events, FFB harvested, fertilizer applied and intensity, pest alerts, sensor network uptime, root causes and crop-loss risk scores per block"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic crop-loss response SOPs by block category and cause"
tool_resources:
  agronomy_analyst:
    semantic_view: __DEMO_DB__.APP.AGRONOMY_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.AGRONOMY_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), BLOCK_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, MOISTURE_DEFICIT_MM FLOAT, DRAIN_LEVEL_PCT FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION MY_PALM_OIL_PRECISION_AG_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (BLOCK_ID, EVENT_TS, MOISTURE_DEFICIT_MM, DRAIN_LEVEL_PCT, SOP_HINT)
    SELECT t.BLOCK_ID, t.EVENT_TS, t.MOISTURE_DEFICIT_MM, t.DRAIN_LEVEL_PCT,
           'Check ' || s.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.BLOCKS s ON s.ID = t.BLOCK_ID
    LEFT JOIN ML.CROP_LOSS_RISK_SCORES r ON r.ENTITY_ID = t.BLOCK_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.BLOCK_ID = t.BLOCK_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('MY_PALM_OIL_PRECISION_AG_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Malaysia oil palm field-sensor alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.BLOCK_ID = t.BLOCK_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.CROP_LOSS_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.CROP_LOSS_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.CROP_LOSS_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.CROP_LOSS_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'MOISTURE_DEFICIT_MM', MOISTURE_DEFICIT_MM,
             'DRAIN_LEVEL_PCT', DRAIN_LEVEL_PCT, 'MOISTURE_DEFICIT_7D', MOISTURE_DEFICIT_7D, 'CROP_LOSSES_30D', CROP_LOSSES_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:CROP_LOSS::FLOAT, 4) AS CROP_LOSS_PROB_7D,
         CASE WHEN PRED:probability:CROP_LOSS::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:CROP_LOSS::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;

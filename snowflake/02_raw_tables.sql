-- Synthetic block-day agronomy observations for a fictional oil palm grower
-- with estates near four Malaysian cities. Nothing is seeded as a
-- prediction. Randomness is HASH-seeded, so every rebuild is reproducible:
-- per-block area, palm age and crop-loss propensity, weekly harvest
-- seasonality and a peak-crop day, field stress between scouting rounds,
-- category-weighted crop-loss causes, and two regional weather events.
-- Thresholds are internal demo thresholds, not agronomic standards.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.BLOCKS AS
WITH blocks AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS BLOCK_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 30))
), draws AS (
  SELECT BLOCK_INDEX,
         MOD(ABS(HASH(BLOCK_INDEX, 'my_age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(BLOCK_INDEX, 'my_rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(BLOCK_INDEX, 'my_insp')), 1000000) / 1e6 AS U_INSP,
         MOD(ABS(HASH(BLOCK_INDEX, 'my_discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(BLOCK_INDEX, 'my_capacity')), 1000000) / 1e6 AS U_CAPACITY
  FROM blocks
)
SELECT 'BLK-' || LPAD(BLOCK_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic block ' || LPAD(BLOCK_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (7 and 5 are coprime): every region and block
       -- category is present, with Kluang and Kuantan largest.
       CASE MOD(BLOCK_INDEX, 7) WHEN 0 THEN 'Kluang' WHEN 1 THEN 'Kluang'
            WHEN 2 THEN 'Kuantan' WHEN 3 THEN 'Kuantan'
            WHEN 4 THEN 'Sandakan' ELSE 'Bintulu' END AS REGION,
       CASE MOD(BLOCK_INDEX, 5) WHEN 0 THEN 'Young Mature' WHEN 1 THEN 'Prime Mature'
            WHEN 2 THEN 'Old Mature' WHEN 3 THEN 'Peat Block'
            ELSE 'Lowland Block' END AS CATEGORY,
       BLOCK_INDEX,
       -- Palm age in years, by category.
       ROUND(CASE MOD(BLOCK_INDEX, 5) WHEN 0 THEN 4 + U_AGE * 3 WHEN 1 THEN 8 + U_AGE * 7
                  WHEN 2 THEN 18 + U_AGE * 7 ELSE 6 + U_AGE * 12 END, 1) AS AGE_YEARS,
       ROUND(25 + U_CAPACITY * 30, 1) AS AREA_HA,
       -- Base daily crop-loss probability 0.5%-3.5%; ~15% of blocks are chronic (x3).
       (0.005 + U_RATE * 0.03) * IFF(U_RATE > 0.85, 3, 1) AS BASE_CROP_LOSS_RATE,
       7 * (1 + FLOOR(U_INSP * 3)) AS SCOUTING_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS SCOUTING_COMPLETION_PROB,
       -- Potential FFB per day (tonnes): area x synthetic yield potential by category.
       ROUND((25 + U_CAPACITY * 30) * 26 / 365
             * CASE MOD(BLOCK_INDEX, 5) WHEN 0 THEN 0.70 WHEN 1 THEN 1.00 WHEN 2 THEN 0.75
                    WHEN 3 THEN 0.80 ELSE 0.85 END, 3) AS DAILY_CAPACITY,
       -- Fertilizer applied (kg per tonne of FFB), synthetic and by category.
       CASE MOD(BLOCK_INDEX, 5) WHEN 0 THEN 75 WHEN 1 THEN 55 WHEN 2 THEN 60
            WHEN 3 THEN 70 ELSE 62 END * (0.9 + U_AGE * 0.2) AS FERT_RATE,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.BLOCK_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), regional_events AS (
  -- Two region-wide weather events in the window.
  SELECT * FROM VALUES (27, 'Kluang', 'Prolonged dry spell', 6.0),
                       (64, 'Bintulu', 'Flash flood waterlogging', 9.0)
    AS o(DAY_INDEX, REGION, EVENT_CAUSE, HOURS)
), base AS (
  SELECT s.ID AS ENTITY_ID, s.BLOCK_INDEX, s.CATEGORY, s.REGION, s.AGE_YEARS,
         s.BASE_CROP_LOSS_RATE, s.SCOUTING_INTERVAL_DAYS, s.SCOUTING_COMPLETION_PROB,
         s.DAILY_CAPACITY, s.FERT_RATE, d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         24.0 AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + s.BLOCK_INDEX * 5, s.SCOUTING_INTERVAL_DAYS) AS DAYS_SINCE_SCOUTING,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'my_exc')), 1000000) / 1e6 AS U_EXC,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'my_down')), 1000000) / 1e6 + 1e-6 AS U_DOWN,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'my_cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'my_inspdone')), 1000000) / 1e6 AS U_INSPDONE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'my_volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'my_noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'my_hit')), 1000000) / 1e6 AS U_HIT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'my_grv')), 1000000) / 1e6 AS U_GRV,
         e.EVENT_CAUSE, e.HOURS AS EVENT_HOURS
  FROM RAW.BLOCKS s CROSS JOIN days d
  LEFT JOIN regional_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = s.REGION
), loaded AS (
  SELECT *,
         IFF(DAYS_SINCE_SCOUTING = 0, 1, 0) AS SCOUTING_DUE,
         IFF(DAYS_SINCE_SCOUTING = 0 AND U_INSPDONE < SCOUTING_COMPLETION_PROB, 1, 0) AS SCOUTING_DONE,
         -- Field stress builds between scouting rounds; skipped rounds carry it over.
         DAYS_SINCE_SCOUTING / SCOUTING_INTERVAL_DAYS + (1 - SCOUTING_COMPLETION_PROB) AS WEAR,
         -- Dry-spell stress episode: 9 of every 28 days per block (staggered).
         IFF(MOD(DAY_INDEX + BLOCK_INDEX * 11, 28) < 9, 1, 0) AS STRESS,
         -- Harvest: weekly low day and a peak-crop push on day 45 (+60%) easing over 3 days.
         ROUND(DAILY_CAPACITY * (0.70 + 0.25 * U_VOLUME)
               * IFF(MOD(DAY_INDEX, 7) = 6, 0.75, 1.0)
               * CASE DAY_INDEX - 45 WHEN 0 THEN 1.6 WHEN 1 THEN 1.4 WHEN 2 THEN 1.2 ELSE 1.0 END, 3) AS FFB_TONNES
  FROM base
), crop_losses AS (
  SELECT *, FFB_TONNES / DAILY_CAPACITY AS LOAD_RATIO,
         LEAST(0.5, BASE_CROP_LOSS_RATE * (0.4 + 1.6 * WEAR) * (0.3 + FFB_TONNES / DAILY_CAPACITY)
                    * (1 + AGE_YEARS / 20) * (1 + 2.5 * STRESS)) AS P_EXC
  FROM loaded
), counted AS (
  SELECT *,
         CASE WHEN EVENT_HOURS IS NOT NULL THEN 1
              WHEN U_EXC < P_EXC / 4 THEN 2
              WHEN U_EXC < P_EXC THEN 1
              ELSE 0 END AS CROP_LOSS_COUNT
  FROM crop_losses
)
, timed AS (
  SELECT *,
         -- Field sensor network offline hours: exponential, mean depends on block category.
         CASE WHEN CROP_LOSS_COUNT = 0 THEN 0.0
              WHEN EVENT_HOURS IS NOT NULL THEN EVENT_HOURS
              ELSE LEAST(20.0, ROUND(CROP_LOSS_COUNT * (0.5 - LN(U_DOWN) *
                   CASE CATEGORY WHEN 'Young Mature' THEN 3.0 WHEN 'Prime Mature' THEN 2.0
                                 WHEN 'Old Mature' THEN 4.0 WHEN 'Peat Block' THEN 2.5 ELSE 3.5 END), 1))
         END AS DOWNTIME_HOURS,
         -- Share of sampled bunches graded ripe at harvest.
         LEAST(0.995, GREATEST(0.50,
           CASE CATEGORY WHEN 'Young Mature' THEN 0.955 WHEN 'Prime Mature' THEN 0.960
                         WHEN 'Old Mature' THEN 0.940 WHEN 'Peat Block' THEN 0.935 ELSE 0.950 END
           - 0.025 * WEAR - 0.04 * GREATEST(0, LOAD_RATIO - 0.9) - 0.006 * U_NOISE
           - CROP_LOSS_COUNT * (0.08 + 0.12 * U_HIT))) AS RIPE_RATE,
         12 + FLOOR(U_VOLUME * 13) AS BUNCHES_GRADED
  FROM counted
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS,
       PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
       CROP_LOSS_COUNT,
       CASE WHEN CROP_LOSS_COUNT = 0 THEN 'None'
            WHEN EVENT_CAUSE IS NOT NULL THEN EVENT_CAUSE
            WHEN CATEGORY = 'Young Mature' THEN IFF(U_CAUSE < 0.5, 'Rat damage', IFF(U_CAUSE < 0.8, 'Rhinoceros beetle', 'Weed competition'))
            WHEN CATEGORY = 'Prime Mature' THEN IFF(U_CAUSE < 0.55, 'Potassium deficiency', 'Harvest round delay')
            WHEN CATEGORY = 'Old Mature' THEN IFF(U_CAUSE < 0.6, 'Basal stem rot', 'Tall palm harvest loss')
            WHEN CATEGORY = 'Peat Block' THEN IFF(U_CAUSE < 0.6, 'Water table drawdown', 'Palm leaning')
            ELSE IFF(U_CAUSE < 0.6, 'Waterlogging', 'Bagworm outbreak') END AS ROOT_CAUSE,
       SCOUTING_DUE, SCOUTING_DONE,
       BUNCHES_GRADED,
       FLOOR(BUNCHES_GRADED * RIPE_RATE) AS RIPE_BUNCHES,
       FFB_TONNES,
       ROUND(FFB_TONNES * FERT_RATE * (1 + 0.05 * U_NOISE + 0.03 * WEAR), 1) AS FERTILIZER_KG,
       IFF(U_GRV < 0.02 + 0.04 * CROP_LOSS_COUNT + 0.01 * STRESS, 1, 0) AS PEST_ALERTS,
       ROUND(12 + 18 * WEAR + 25 * GREATEST(0, LOAD_RATIO - 0.8) + 10 * STRESS + 30 * CROP_LOSS_COUNT + U_NOISE * 5, 1) AS MOISTURE_DEFICIT_MM,
       ROUND(LEAST(100, 100 * LOAD_RATIO * (0.75 + 0.1 * U_NOISE) + 7 * STRESS + 4 * CROP_LOSS_COUNT), 1) AS DRAIN_LEVEL_PCT,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM timed;

-- Sensor and drone mapping coverage per block (snapshot): block hectares versus mapped hectares.
CREATE TABLE RAW.SENSOR_COVERAGE AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Young Mature' THEN 'Young planting' WHEN 'Prime Mature' THEN 'Mineral soil'
                     WHEN 'Old Mature' THEN 'Old stand' WHEN 'Peat Block' THEN 'Peat'
                     ELSE 'Riverine lowland' END AS TERRAIN,
       AREA_HA AS BLOCK_HA,
       FLOOR(AREA_HA * (0.30 + MOD(ABS(HASH(ID, 'my_avail')), 1000) / 1000 * 0.45)) AS MAPPED_HA,
       MOD(ABS(HASH(ID, 'my_order')), 8) AS PLANNED_HA,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.BLOCKS;

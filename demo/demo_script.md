# Demo Script: Precision Agriculture & Yield Forecasting
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake streams IoT sensor data from 50 estates, forecasts FFB yields with ML, analyzes drone imagery for nutrient deficiency, and alerts agronomists — all native SQL, no external ML platform needed"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Encik Azman bin Yusof** | Estate Director | React App (SPCS) | FFB yield targets, estate performance, labour costs, replanting schedule |
| **Kavitha a/p Subramaniam** | Agronomist | Amazon QuickSight | Soil nutrient levels, pest/disease detection, irrigation efficiency, drone imagery analysis |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 7 tables | ESTATES (50), SENSOR_READINGS (200000), HARVEST_RECORDS (100000), WEATHER_DATA (365), AGRONOMY_DOCS (80), DRONE_IMAGERY (2000), FELDA_BENCHMARKS (20) |
| **CURATED** | 4 Dynamic Tables | ESTATE_YIELD_SUMMARY, YIELD_TIMESERIES, SOIL_HEALTH_INDEX, PEST_DISEASE_ALERTS |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | COMPLETE_MULTIMODAL, SUMMARIZE, AI_CLASSIFY | Classification + extraction |
| **Search** | Cortex Search | 80 documents indexed |
| **Agent** | PRECISION_AG_AGENT | Semantic View + Search tools |


---

## The Story

A Malaysian palm oil group manages 50 estates across 120,000 hectares in Johor, Pahang, and Sabah. Average FFB yield is 22.4 tonnes per hectare — well below the MPOB target of 25 tonnes. Three estates have dropped below the critical 20-tonne threshold. IoT soil sensors reveal nutrient deficiencies, drone imagery confirms the diagnosis, and ML forecasts predict continued decline without intervention.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "Fifty estates across 120,000 hectares — averaging 22.4 tonnes FFB per hectare against a 25-tonne target."

**Action**: Point at the 22.4 t/ha yield KPI vs 25 target

### [0:45–1:30] YIELD ANALYTICS

**Show**: Yield Analytics tab

> "Estate Kluang at 18.7 tonnes/ha — 6.3 tonnes below MPOB target for mature palms."

**Action**: Click Estate Kluang in the list

### [1:30–2:15] SOIL & SENSOR DATA

**Show**: Soil & Sensor Data tab

> "Two hundred thousand sensor readings across 50 estates. Kluang showing severe boron deficiency."

**Action**: Show soil sensor dashboard for Kluang

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Encik Azman asks: 'What's the forecasted FFB production for next quarter across all estates?'"

**Action**: Type: 'What is the forecasted FFB yield for Q1?'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Seven Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.FORECAST on FFB yield timeseries** — Only demo forecasting palm oil Fresh Fruit Bunch yield — not revenue or demand
2. **Cortex Complete (multimodal) for drone imagery** — Only demo analyzing agricultural drone imagery natively in Snowflake
3. **IoT soil sensor streaming to Snowpipe** — Connects physical soil sensors to yield analytics in one platform
4. **Malaysian palm oil precision agriculture context** — MPOB targets, FELDA benchmarks, realistic estate names and hectarage
5. **80 agronomy documents searchable** — Cortex Search on MPOB best practice guides and fertilizer recommendations
6. **AWS IoT Core + SageMaker satellite/NDVI** — Only demo combining IoT sensor ingestion with satellite vegetation analysis


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM PALM_OIL_PRECISION_AG.RAW.ESTATES` → 50
- [ ] `SELECT COUNT(*) FROM PALM_OIL_PRECISION_AG.RAW.SENSOR_READINGS` → 200000
- [ ] `SELECT COUNT(*) FROM PALM_OIL_PRECISION_AG.RAW.HARVEST_RECORDS` → 100000

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM PALM_OIL_PRECISION_AG.ML.FFB_YIELD_FORECAST_RESULTS` → >0
- [ ] `SELECT SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) FROM PALM_OIL_PRECISION_AG.ML.PEST_DISEASE_ANOMALY_RESULTS WHERE SERIES = 'KLUANG'` → >=5

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM PALM_OIL_PRECISION_AG.AI.DRONE_IMAGERY_ANALYSIS` → >=2000


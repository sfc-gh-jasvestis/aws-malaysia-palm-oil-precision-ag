# Precision Agriculture & Yield Forecasting

**Malaysia - Palm Oil & Agriculture**
Use case: Precision Agriculture

> IoT-powered precision farming for Malaysian palm oil estates — soil sensors stream to Snowflake, ML.FORECAST predicts Fresh Fruit Bunch yields, and Cortex Complete analyzes drone imagery for nutrient deficiency.

## Why Snowflake

Snowflake streams IoT sensor data from 50 estates, forecasts FFB yields with ML, analyzes drone imagery for nutrient deficiency, and alerts agronomists — all native SQL, no external ML platform needed

- **ML.FORECAST on FFB yield timeseries** - Only demo forecasting palm oil Fresh Fruit Bunch yield — not revenue or demand
- **Cortex Complete (multimodal) for drone imagery** - Only demo analyzing agricultural drone imagery natively in Snowflake
- **IoT soil sensor streaming to Snowpipe** - Connects physical soil sensors to yield analytics in one platform
- **Malaysian palm oil precision agriculture context** - MPOB targets, FELDA benchmarks, realistic estate names and hectarage
- **80 agronomy documents searchable** - Cortex Search on MPOB best practice guides and fertilizer recommendations
- **AWS IoT Core + SageMaker satellite/NDVI** - Only demo combining IoT sensor ingestion with satellite vegetation analysis

## What is deployed

| | |
|---|---|
| Database | `MY_PALM_OIL_PRECISION_AG` |
| Service | `MY_PALM_OIL_PRECISION_AG_APP` |
| Compute pool | `SEA_DEMOS_MALAYSIA_POOL` |
| Dimension table | `RAW.FELDA_BENCHMARKS` (20 rows) |
| Fact table | `RAW.SENSOR_READINGS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | MYR (RM) |

Regions in play: Selangor, Johor, Penang, Sabah, Sarawak
Segments: Immature Palm, Prime Mature, Late Mature, Replanting Due

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh MY_PALM_OIL_PRECISION_AG
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| FFB Yield (Avg) | `22.8 T/ha` | average per event |
| OER Rate | `21.4%` | average per event |
| Replanting (YTD) | `4.2K ha` | total across Felda Benchmarks |
| Estates | `412` | total across Felda Benchmarks |
| Harvest Interval | `14 days` | average per event |
| Palm Age (Avg) | `12 yrs` | average per event |
| Fertilizer Cost | `RM 2.4K/ha` | average per event |


## Demo flow

1. Executive Cockpit
2. Yield Analytics
3. Soil & Sensor Data
4. Ask AI
5. Architecture & Data

## Talking points

- **50 estates, 120,000 ha** - total managed area across Johor, Pahang, and Sabah
- **22.4 t FFB/ha** - current average yield (target: 25 t/ha)
- **3 estates** - below critical 20 t/ha threshold
- **RM 1.2B** - annual harvest value
- **200K sensor readings** - IoT soil data streamed to Snowflake
- **2,000 drone images** - analyzed by Cortex Complete (multimodal)
- **5 of 8 weeks** - anomalous for Estate Kluang (ML.ANOMALY_DETECTION)

## Business impact

- Malaysia produced 16.6M tonnes of crude palm oil in 2023 across 5.67M hectares (MPOB)
- Precision agriculture can improve palm oil yields by 15-20% through targeted nutrient management (Journal of Oil Palm Research)
- FELDA estates achieving 25+ t/ha FFB yield demonstrate potential of data-driven agronomy (FELDA)
- IoT-enabled precision farming reduces fertilizer costs by 20-30% while improving yields (McKinsey Agriculture)

---
Generated from `generator/demo_specs/aws-malaysia-palm-oil-precision-ag.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-malaysia-palm-oil-precision-ag` instead.

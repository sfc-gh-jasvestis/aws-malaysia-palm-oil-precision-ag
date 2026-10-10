# Malaysia Oil Palm Precision Agriculture

**Malaysia - Oil Palm Plantations**
Use case: Block agronomy and crop-loss risk

> Block agronomy for a fictional Malaysian oil palm grower: 30 synthetic blocks near Kluang, Kuantan, Sandakan and Bintulu, curated by dynamic tables, ranked by a holdout-tested crop-loss risk model, with an FFB harvest forecast and AI answers that cite their SQL and SOPs. All thresholds are demo settings, not agronomic standards.

## Why Snowflake

- **Dynamic tables** reconcile ripe bunch rate, crop-loss events, fertilizer intensity and sensor uptime from RAW block data, with checks in `run_core.py`
- **Crop-loss risk classification** gives a holdout-evaluated next-7-day crop-loss probability per block
- **FFB harvest forecast** projects 14 days of grower-wide FFB tonnes with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live telemetry**: a native simulator (Snowflake only) or IoT Core, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.BLOCKS` (30 rows) |
| Fact table | `RAW.BLOCK_DAILY` (2,700 block-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `CROP_LOSS_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.CROP_LOSS_RISK_SCORES`, `ML.CROP_LOSS_RISK_HOLDOUT_METRICS`, `ML.FFB_FORECAST`, `ML.MOISTURE_ANOMALIES` |

Regions: Kluang, Kuantan, Sandakan, Bintulu.
Block categories: Young Mature, Prime Mature, Old Mature, Peat Block, Lowland Block.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Ripe Bunch Rate | 87.8% |
| Crop-Loss Events | 393 |
| Fertilizer Intensity | 65.7 kg/t FFB |
| FFB Harvested (t) | 5,286 |
| Sensor Network Uptime | 97.7% |
| Blocks Monitored | 30 |
| Sensor Mapping Coverage | 51.3% |
| Pest Alerts | 63 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily ripe bunch rate, unripe bunches by crop-loss cause, block table
2. Predictive: holdout metrics, risk bands, 14-day FFB harvest forecast, soil moisture deficit anomalies
3. Block Health: sensor network uptime, sensor mapping coverage, scouting completion against ripe bunch rate, then generate the action memo
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake only) or `python aws/publish_telemetry.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Block-level ripe bunch rate spans 83.2% to 90.8%; Kluang trails the other regions at 87.3%.
- Of the 13 crop-loss causes, tall palm harvest loss accounts for the most unripe bunches.
- In the synthetic rates, Young Mature blocks use the most fertilizer per tonne (80.4 kg/t FFB) and Prime Mature blocks the least (55.9 kg/t).
- On a time-based holdout the risk model scores precision 0.61 and recall 0.57 at 0.5, against a 0.53 base rate. Position it as a triage list, not a guarantee.
- The Kluang dry spell and the Bintulu flash flood are regional weather events, so they are left out of the crop-loss labels.
- No figure is a field recommendation; all thresholds are internal to the demo.

## Business impact

Use only the sourced references in `README.md` (Business Impact).

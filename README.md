# Malaysia Oil Palm Precision Agriculture - Block Agronomy

Block-level agronomy for a **fictional Malaysian oil palm grower with 30 synthetic blocks on estates near Kluang, Kuantan, Sandakan and Bintulu**, built on Snowflake with an optional AWS edge. A field sensor alarm becomes a 7-day crop-loss risk score, an email to the agronomist and an AI-drafted action memo. The grower, blocks, people and figures are invented; nothing here describes the yields, practices or compliance of any real company or estate.

## Architecture

The Snowflake core uses Dynamic Tables, Snowflake ML, Cortex Search, a Cortex Agent, Cortex AI_COMPLETE and SPCS; the full build adds **AWS** IoT Core, S3, Bedrock Claude and QuickSight with Amazon Q. Sensor readings land in `RAW.LIVE_TELEMETRY`. Dynamic tables curate 90 days of block-day history into ripe bunch rate, crop-loss events, FFB tonnes, fertilizer intensity, pest alerts, sensor uptime and mapped-area coverage. Snowflake ML ranks blocks by 7-day crop-loss risk, forecasts daily FFB harvest for the whole grower and flags unusual soil moisture deficit days. The Cortex Agent answers with SQL and SOP citations, and an LLM drafts the action memo for the estate team.

Interactive diagrams (hover for object names): [Snowflake only](docs/architecture-snowflake.html) | [AWS + Snowflake](docs/architecture-aws.html). The app shows both on its Architecture & Data tab, the current build first. Regenerate them with `python3 docs/build_architecture.py`.

```mermaid
flowchart LR
    subgraph AWS
      SIM[publish_telemetry.py] --> IOT[AWS IoT Core<br/>topic my/palm-oil-precision-ag/telemetry]
      IOT -->|topic rule| S3[(Amazon S3<br/>iot/ landing)]
      BR[Amazon Bedrock<br/>Claude Sonnet 4.5]
      QS[Amazon QuickSight<br/>dashboard + Q topic]
    end
    subgraph Snowflake
      S3 -->|SQS event| PIPE[Snowpipe AUTO_INGEST] --> LIVE[RAW.LIVE_TELEMETRY]
      GEN[02_raw_tables.sql<br/>seeded generator] --> RAW[RAW.BLOCKS / BLOCK_DAILY /<br/>SENSOR_COVERAGE]
      RAW --> DT[CURATED dynamic tables]
      RAW --> ML[Snowflake ML<br/>CLASSIFICATION risk, FORECAST,<br/>ANOMALY_DETECTION]
      DT --> SV[Semantic view<br/>APP.AGRONOMY_ANALYTICS]
      RAW --> CS[Cortex Search<br/>crop-loss SOPs]
      SV --> AG[Cortex Agent<br/>APP.AGRONOMY_AGENT]
      CS --> AG
      LIVE --> AL[Alert APP.LIVE_ALARM_ALERT<br/>+ email]
      UDF[APP.BEDROCK_GENERATE<br/>external access UDF]
      TK[Task graph: refresh, then rescore]
      APP[Next.js app on SPCS]
    end
    BR <--> UDF
    DT --> APP
    ML --> APP
    LIVE --> APP
    AG --> APP
    UDF --> APP
    DT --> QS
    ML --> QS
    LIVE --> QS
```

The Snowflake-only build drops the AWS subgraph: `APP.SIMULATE_TELEMETRY` writes to `RAW.LIVE_TELEMETRY`, and the app calls Cortex `AI_COMPLETE` instead of the Bedrock UDF.

## Snowflake Capabilities

| Capability | Implementation |
|-----------|---------------|
| Dynamic Tables | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `CROP_LOSS_CAUSES`, `TREND_ANALYSIS` from the RAW tables |
| Snowflake ML | CLASSIFICATION 7-day crop-loss risk (`ML.CROP_LOSS_RISK_SCORES`), 14-day FFB harvest FORECAST, soil moisture deficit ANOMALY_DETECTION |
| Cortex Search | 21 synthetic crop-loss response SOPs (one per block category and cause) in `SEARCH.AGRONOMY_SOP_SEARCH` |
| Semantic View | `APP.AGRONOMY_ANALYTICS` over blocks, crop-loss causes, daily totals and risk |
| Cortex Agent | `APP.AGRONOMY_AGENT`: Cortex Analyst over the semantic view plus Cortex Search for SOP citations |
| Cortex AI | `AI_COMPLETE('claude-sonnet-4-5')` for grounded answers, and for the action memo in the Snowflake-only build |
| Alerts + Tasks | `APP.LIVE_ALARM_ALERT` logs ALARM readings and sends email; task graph `TASK_REFRESH_CURATED`, then `TASK_RESCORE_RISK` |
| Snowpark Container Services | Next.js app `APP.MY_PALM_OIL_PRECISION_AG_APP` with 6 tabs: Executive Cockpit, Predictive, Block Health, Live IoT, Ask AI, Architecture & Data |
| Snowpipe | `RAW.LIVE_TELEMETRY_PIPE` AUTO_INGEST from S3 (AWS build only) |

## AWS Services

Used only in the AWS + Snowflake build.

| Service | Role in Demo |
|---------|-------------|
| AWS IoT Core | Receives simulated field-sensor telemetry (soil moisture deficit, drain water level). A topic rule writes each message to S3 |
| Amazon S3 | Landing bucket. An event notification goes to the Snowpipe SQS queue |
| Amazon Bedrock | Claude Sonnet 4.5 writes the action memo, called from Snowflake through an external-access UDF |
| Amazon QuickSight | DIRECT_QUERY executive dashboard over Snowflake (daily ripe bunch rate, crop-loss events by block, crop-loss risk) |
| Amazon Q | Natural-language questions over the QuickSight topic `my-palm-oil-precision-ag-topic` |
| AWS IAM | Least-privilege roles for S3, IoT and Bedrock |

## Personas

Both personas are fictional.

| Persona | Role | Key Questions |
|---------|------|---------------|
| **Nurul Aisyah Rahman** | VP Plantation Operations | "Which region trails on ripe bunch rate?" "Which crop-loss causes cost us the most unripe bunches?" |
| **Daniel Lim Wei Jie** | Estate Agronomist | "Which blocks carry high crop-loss risk this week, and which SOP do I follow?" |

## Data

Every row is synthetic and HASH-seeded, so a rebuild reproduces it exactly. Grower and block names are invented; Kluang, Kuantan, Sandakan and Bintulu are real Malaysian towns used only as region labels. Thresholds are demo settings rather than agronomic standards, and no figure is a field recommendation.

| Table | Rows | Description |
|-------|------|-------------|
| RAW.BLOCKS | 30 | Blocks across 4 regions and 5 block categories (Young Mature, Prime Mature, Old Mature, Peat Block, Lowland Block), with area and palm age |
| RAW.BLOCK_DAILY | 2,700 | Daily block observations over 90 days: bunches graded and graded ripe, FFB tonnes, fertilizer kg, pest alerts, crop-loss events, root cause, scouting rounds, sensor downtime, soil moisture deficit and drain water level |
| RAW.SENSOR_COVERAGE | 30 | Block hectares and hectares covered by sensor and drone mapping |
| SEARCH.AGRONOMY_SOP_DOCS | 21 | Synthetic crop-loss response SOPs indexed for Cortex Search |
| RAW.LIVE_TELEMETRY | Grows during the demo | Live readings from IoT Core (AWS build) or `APP.SIMULATE_TELEMETRY` (Snowflake-only build) |
| ML.CROP_LOSS_RISK_SCORES | 30 | 7-day crop-loss probability and risk band per block |

## Build Instructions

### Prerequisites
- Snowflake account with ACCOUNTADMIN access, and Cortex AI enabled (AI_COMPLETE, Search, Agent).
- An X-Small warehouse with auto-suspend at or below 120 s, and an existing SPCS compute pool.
- Python 3.11+, `snowflake-connector-python`, Node.js 22+, Docker and the `snow` CLI.
- App image: run `snow spcs image-registry login`, then build and push `my-palm-oil-precision-ag-app:v1` to the database's `APP.IMAGES` repository (see the header of `snowflake/07_deploy_app.sql`).
- AWS build only: `boto3`, AWS credentials for the target account (us-west-2) with Bedrock access, and QuickSight Enterprise.

### SPCS App
```
<DATABASE>.APP.MY_PALM_OIL_PRECISION_AG_APP
```

### Tests
```bash
python -m pytest aws snowflake quicksight
```

For a local run, put `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_AUTHENTICATOR=PROGRAMMATIC_ACCESS_TOKEN`, `SNOWFLAKE_TOKEN` and `DEMO_PLATFORM` in the environment, then run `npm --prefix app run build && npm --prefix app start`.

## Build Modes

Both modes share the same core. They differ in three places, and the app's `DEMO_PLATFORM` setting (in its SPCS spec) switches the memo provider and the Live IoT tab.

| Layer | Snowflake Only | Full AWS + Snowflake |
|---|---|---|
| Live telemetry | `CALL APP.SIMULATE_TELEMETRY(n)` inserts simulated readings into `RAW.LIVE_TELEMETRY`. This simulates a sensor feed; it is not Snowpipe Streaming | `aws/publish_telemetry.py` to AWS IoT Core, then S3, SQS and Snowpipe AUTO_INGEST |
| Action memo | Cortex `AI_COMPLETE('claude-sonnet-4-5')` | Amazon Bedrock Claude Sonnet 4.5 through `APP.BEDROCK_GENERATE` |
| BI and natural-language questions | The SPCS app is the dashboard; questions go to the Cortex Agent | Also a QuickSight dashboard and an Amazon Q topic |
| App setting | `DEMO_PLATFORM: snowflake` | `DEMO_PLATFORM: aws` |

### Snowflake Only

```bash
# 1. Core data and dynamic tables (guarded: new isolated database only)
python snowflake/run_core.py --database MALAYSIA_PALM_OIL_PRECISION_AG_SNOWFLAKE --warehouse <XS_WAREHOUSE> --connection <CONNECTION> --apply
# 2. Native telemetry, ML, search, semantic view, agent, alert and task graph
python snowflake/run_intelligence.py --database MALAYSIA_PALM_OIL_PRECISION_AG_SNOWFLAKE --platform snowflake --warehouse <XS_WAREHOUSE> --connection <CONNECTION> --alert-email you@example.com
# 3. App on SPCS with DEMO_PLATFORM=snowflake (push the image first)
python snowflake/run_intelligence.py --database MALAYSIA_PALM_OIL_PRECISION_AG_SNOWFLAKE --platform snowflake --warehouse <XS_WAREHOUSE> --connection <CONNECTION> --alert-email you@example.com --files 07_deploy_app.sql --compute-pool <COMPUTE_POOL>
```

During the demo:
- Run `CALL APP.SIMULATE_TELEMETRY(20)` to add live readings. For a continuous feed, run `ALTER TASK APP.TASK_SIMULATE_TELEMETRY RESUME`, and `SUSPEND` it afterwards.
- Run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` to raise the alarm email.
- Run `EXECUTE TASK APP.TASK_REFRESH_CURATED` to refresh the curated tables and rescore risk.

Afterwards, drop the database or run `ALTER SERVICE APP.MY_PALM_OIL_PRECISION_AG_APP SUSPEND`.

### Full AWS + Snowflake

```bash
# 1. Core data and dynamic tables (guarded: new isolated database only)
python snowflake/run_core.py --database MALAYSIA_PALM_OIL_PRECISION_AG_AWS --warehouse <XS_WAREHOUSE> --connection <CONNECTION> --apply
# 2. AWS ingestion and Bedrock (dry run first, then --apply)
python aws/setup_aws.py --database MALAYSIA_PALM_OIL_PRECISION_AG_AWS --account <AWS_ACCOUNT_ID> --connection <CONNECTION> --apply
# 3. ML, search, semantic view, agent, alert and task graph
python snowflake/run_intelligence.py --database MALAYSIA_PALM_OIL_PRECISION_AG_AWS --platform aws --warehouse <XS_WAREHOUSE> --connection <CONNECTION> --alert-email you@example.com
# 4. App on SPCS with DEMO_PLATFORM=aws (push the image first)
python snowflake/run_intelligence.py --database MALAYSIA_PALM_OIL_PRECISION_AG_AWS --platform aws --warehouse <XS_WAREHOUSE> --connection <CONNECTION> --alert-email you@example.com --files 07_deploy_app.sql --compute-pool <COMPUTE_POOL>
# 5. QuickSight dashboard and Q topic (needs an existing Snowflake data source)
python quicksight/build_dashboards.py --database MALAYSIA_PALM_OIL_PRECISION_AG_AWS --account <AWS_ACCOUNT_ID> --principal-arn <QUICKSIGHT_USER_ARN> --data-source-arn <DATA_SOURCE_ARN> --prefix my-palm-oil-precision-ag --apply --update --with-topic
```

QuickSight objects must be shared with the QuickSight user who signs in (`--principal-arn`); otherwise the console shows nothing.

During the demo:
- Run `python aws/publish_telemetry.py --count 20` to send live readings.
- Run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` to raise the alarm email.
- Run `EXECUTE TASK APP.TASK_REFRESH_CURATED` to refresh the curated tables and rescore risk.

Afterwards, `python aws/teardown_aws.py --database MALAYSIA_PALM_OIL_PRECISION_AG_AWS --account <AWS_ACCOUNT_ID> --connection <CONNECTION> --apply` removes the AWS resources and the account-level Bedrock external-access and S3 storage integrations. It leaves the email integration `MY_PALM_OIL_PRECISION_AG_EMAIL_INT`, which the Snowflake-only build also uses.

## Business Impact

Industry context:
- **Malaysia is the world's second-largest palm oil producer**: 20.2 million metric tons in marketing year 2025, 24.8% of global production, from about 5.6 million harvested hectares -- [USDA Foreign Agricultural Service, Production - Palm Oil](https://www.fas.usda.gov/data/production/commodity/4243000)

## Key Demo Numbers

These figures are synthetic and come from the seeded demo data. Forecast and anomaly figures can shift slightly with the build day.

- **30 blocks** and 2,700 block-days over 90 days, in 4 regions and 5 block categories (1,247.2 ha); **5,286 t of FFB** harvested from **48,449 bunches graded**
- **Ripe bunch rate 87.8%**; blocks range from 83.2% to 90.8%, and Kluang is the lowest region at 87.3%
- **393 crop-loss events** across 13 root causes; tall palm harvest loss leaves the most bunches unripe
- **Fertilizer intensity 65.7 kg/t FFB** (347,220 kg applied); Young Mature blocks are highest at 80.4 kg/t and Prime Mature blocks lowest at 55.9 kg/t
- **Crop-loss risk model** on an out-of-time holdout: precision 0.61 and recall 0.57 at a 0.5 threshold, against a 0.53 base rate. 17 blocks are high risk; the top block is BLK-0021, at 98.6%
- **14-day FFB harvest forecast** with prediction intervals (54.6 to 64.1 t per day); **34 of 480** block-days flagged as soil moisture deficit anomalies
- **Sensor network uptime 97.7%**, sensor mapping coverage 51.3%, 63 pest alerts
- **21 SOPs** indexed for Cortex Search and cited by ID in agent answers


## License

Apache 2.0 — See [LICENSE](LICENSE) for details.

This is a personal demo project, not an official Snowflake offering, and it carries no support or warranty. The grower, blocks, people and figures are synthetic and do not describe any real company or estate. The cited industry statistic is third-party context, not a promise of results.

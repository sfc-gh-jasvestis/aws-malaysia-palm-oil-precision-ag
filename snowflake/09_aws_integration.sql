-- ============================================================================
-- 09_AWS_INTEGRATION.SQL — AWS services for Precision Agriculture & Yield Forecasting
-- Account: <YOUR_AWS_ACCOUNT_ID> | Region: us-west-2
-- Skip this script for Snowflake-only build
-- ============================================================================
USE DATABASE PALM_OIL_PRECISION_AG;
USE SCHEMA APP;

-- ==================== AMAZON S3 ====================
-- Storage integration for S3 landing zone
CREATE OR REPLACE STORAGE INTEGRATION aws_malaysia_palm_oil_precision_ag_S3_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/snowflake-sea-demos-s3'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://<YOUR_S3_BUCKET>/aws-malaysia-palm-oil-precision-ag/');

-- External stage for data landing
CREATE OR REPLACE STAGE RAW.LANDING_STAGE
  STORAGE_INTEGRATION = aws_malaysia_palm_oil_precision_ag_S3_INT
  URL = 's3://<YOUR_S3_BUCKET>/aws-malaysia-palm-oil-precision-ag/';

-- ==================== KINESIS / IOT CORE INGESTION ====================
-- Snowpipe from Kinesis Data Stream
-- Stream ARN: arn:aws:kinesis:us-west-2:<YOUR_AWS_ACCOUNT_ID>:stream/aws-malaysia-palm-oil-precision-ag-stream

CREATE OR REPLACE PIPE RAW.REALTIME_PIPE
  AUTO_INGEST = TRUE
  INTEGRATION = 'aws_malaysia_palm_oil_precision_ag_S3_INT'
  COMMENT = 'Auto-ingest from Kinesis via S3 delivery stream'
AS
COPY INTO RAW.ESTATES
FROM @RAW.LANDING_STAGE/realtime/
FILE_FORMAT = (TYPE = 'JSON');


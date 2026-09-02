-- Generated from generator/demo_specs/aws-malaysia-palm-oil-precision-ag.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-malaysia-palm-oil-precision-ag
-- This is the schema that is actually deployed for MY_PALM_OIL_PRECISION_AG.

-- MY_PALM_OIL_PRECISION_AG  (Precision Agriculture & Yield Forecasting)
-- generated from generator/demo_specs/aws-malaysia-palm-oil-precision-ag.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS MY_PALM_OIL_PRECISION_AG;
CREATE SCHEMA IF NOT EXISTS MY_PALM_OIL_PRECISION_AG.RAW;
CREATE SCHEMA IF NOT EXISTS MY_PALM_OIL_PRECISION_AG.CURATED;
CREATE SCHEMA IF NOT EXISTS MY_PALM_OIL_PRECISION_AG.APP;
USE DATABASE MY_PALM_OIL_PRECISION_AG;

-- 5 real regions; entity names carry their region so the two always agree

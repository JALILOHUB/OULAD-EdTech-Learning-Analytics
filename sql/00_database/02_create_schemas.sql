-- Purpose:
-- Create separate SQL layers so raw source data, quality checks, staging,
-- analytical logic and marts remain clearly separated.

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS quality;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS mart;

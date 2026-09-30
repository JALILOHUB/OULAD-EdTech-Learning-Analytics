# Project Architecture

## 1. Business-to-technical flow

Official Data Source
→ Python Ingestion
→ SQL RAW Layer
→ Data Quality
→ SQL STAGING Layer
→ SQL Analytical Layer / Data Mart
→ Power BI
→ Python Advanced Analytics when required

## 2. Why SQL is the backbone

The project must demonstrate real relational-data work: joins, aggregation, CTEs, subqueries, CASE expressions, window functions, date logic, quality checks and analytical views.

Python is not used to hide SQL work. It is used where it adds value: ingestion, profiling, statistical analysis, advanced transformations and later machine learning.

Power BI is the communication layer, not the raw-data storage layer.

## 3. Data layers

### RAW
Faithful representation of source tables. No analytical rewriting.

### STAGING
Validated, typed and standardized data prepared for analytical use.

### ANALYTICS / DATA MART
Business-oriented views or tables such as student engagement, academic performance, retention and risk indicators.

### POWER BI
Interactive reporting built from analytical outputs rather than raw CSV files.

## 4. Reproducibility

Every important transformation should have:
1. a business reason;
2. a documented SQL/Python implementation;
3. a validation check;
4. an interpretation of the result;
5. a recorded decision in `docs/analysis_log.md`.

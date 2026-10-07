# Project Architecture

**Project Owner & Lead Analyst:** Abdeljalil El Khyati

## 1. Business-to-technical flow

Official Data Source
→ Python Ingestion / Profiling
→ SQL RAW Layer
→ Data Quality
→ SQL STAGING Layer
→ SQL Analytical Layer / Data Mart
→ Power BI
→ Python Advanced Analytics when justified

## 2. Why SQL is the backbone

The project demonstrates real relational-data work: joins, aggregation, CTEs, subqueries, `CASE` expressions, window functions, date logic, quality checks, and analytical views.

Python is not used to hide SQL work. It is used where it adds value: ingestion, profiling, statistical analysis, advanced transformations, and later machine learning.

Power BI is the communication layer, not the raw-data storage layer.

## 3. Data layers

### RAW

Faithful representation of the seven source tables. Source column names and source values are preserved while PostgreSQL types are assigned from validated observations.

RAW contains no business logic, cleaning, aggregation, duplicate removal, or analytical transformation.

The `student_vle` table intentionally has no primary key because the validated candidate key is not unique in the source. Its duplicate structure will be characterized before any STAGING transformation is chosen.

### STAGING

Validated, typed, standardized data prepared for analytical use. Any transformation must be justified by the observed source structure and documented before implementation.

### ANALYTICS / DATA MART

Business-oriented views or tables such as student engagement, academic performance, retention, and risk indicators.

### POWER BI

Interactive reporting built from analytical outputs rather than raw CSV files.

### PYTHON ADVANCED ANALYTICS

Statistical analysis and machine learning will be introduced only when the analytical question justifies them.

## 4. Reproducibility

Every important transformation should have:

1. a business or technical reason;
2. a documented SQL/Python implementation;
3. a validation check;
4. an interpretation of the result;
5. a recorded decision in `docs/analysis_log.md`.

## 5. Current Implementation State

The project has completed source validation, RAW schema design, RAW table creation, and RAW loading. The next architectural gate is duplicate characterization for `raw.student_vle` before STAGING design begins.

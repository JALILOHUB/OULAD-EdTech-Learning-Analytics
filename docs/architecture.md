# Project Architecture

**Project Owner & Lead Analyst:** Abdeljalil El Khyati  
**Updated:** 2026-10-15

## 1. Business-to-technical flow

Official OULAD source → Python source acquisition and profiling → PostgreSQL `raw` → SQL data-quality checks and `quality.test_results` registry → PostgreSQL `staging` → planned `analytics` views / `mart` tables → Power BI. Python statistical analysis and machine learning are reserved for questions that justify them.

## 2. Responsibilities by layer

### Source acquisition and profiling

Python handles reproducible source acquisition, archive extraction, path resolution, source-header checks, and pre-ingestion profiling. The ingestion workflow resolves paths from the project location and avoids needless downloads or extraction when source files already exist.

### RAW

The seven source tables are loaded into PostgreSQL `raw`. Source values and documented `?` markers are preserved. Data types were selected from observed source values, but RAW does not perform business cleaning, aggregation, deduplication, or analytical rewriting. Six tables have validated primary keys; `raw.student_vle` intentionally has no primary key because the tested five-column candidate key is not unique.

### Data quality

SQL checks cover table volumes, candidate keys, parent/reference consistency, completeness, numeric bounds, categorical domains, temporal diagnostics, and duplicate patterns. Results are recorded in `quality.test_results`. A `REVIEW` status is retained when an observation needs interpretation; it does not automatically mean rows are invalid.

### STAGING

Seven typed tables have been created from RAW. Documented `?` values were converted to SQL `NULL` in the selected fields only. Checks C2 and S1–S4 confirmed the conversions examined, row-count reconciliation, missing-value reconciliation, numeric score bounds, VLE week ranges, and preservation of the `student_vle` repeated-key pattern. STAGING was created with `CREATE TABLE AS SELECT`; constraints and indexes should not be assumed to have been copied from RAW.

### ANALYTICS and DATA MART

These layers are not yet implemented. They will contain documented, business-oriented outputs for student engagement, academic outcomes, retention, and risk indicators. Grain, relationship paths, filters, and metric definitions must be set before building aggregates or views.

### Power BI

Power BI will consume validated analytical outputs, not raw CSV files. Dashboard work should begin after analytical questions and metric definitions are agreed and checked in SQL.

### Python advanced analytics

Statistical tests, segmentation, predictive modelling, and machine learning are optional. They will be introduced only when they answer a defined analytical question and can be validated against an appropriate baseline.

## 3. Reproducibility requirements

Each substantive transformation or metric should have: (1) a stated purpose, (2) a version-controlled implementation, (3) a validation check, (4) an evidence-based interpretation, and (5) a recorded decision in `docs/analysis_log.md`.

## 4. Current implementation state

Source acquisition and profiling, RAW table creation and loading, quality checks and registry setup, STAGING table creation, and the reported C2 / S1–S4 validation tasks are complete. The four recorded `REVIEW` items are documented in `docs/data_engineering_phase_closure.md`. Analytical modelling has not started.

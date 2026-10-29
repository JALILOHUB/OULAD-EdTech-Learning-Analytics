# OULAD — EdTech Learning Analytics

**Project Owner & Lead Analyst:** Abdeljalil El Khyati

## Project purpose

This project uses the Open University Learning Analytics Dataset (OULAD) to build a reproducible, client-style learning analytics workflow. The main business question is:

> **How can an online learning platform identify engagement patterns, academic risk, and factors associated with student success?**

PostgreSQL is the relational and analytical backbone. Python supports source acquisition, profiling, and additional analysis when it adds value. Power BI is reserved for communicating validated analytical outputs.

## Architecture

Official OULAD source → Python source acquisition and profiling → PostgreSQL `raw` → SQL data-quality checks and `quality.test_results` → PostgreSQL `staging` → future `analytics` views / `mart` tables → Power BI. Python statistical analysis and machine learning will be used only when justified by a defined question.

## Analytical principles

- SQL is the backbone for relational data work and analytical transformations; Python is used where it adds value (ingestion, profiling, statistics, advanced analysis); Power BI is the communication and reporting layer, not the data-processing environment.
- Preserve source evidence in RAW; do not apply business cleaning, deduplication, or aggregation there.
- Convert documented source missing tokens only in typed STAGING fields, keeping RAW unchanged.
- Define each analytical table's grain before designing joins or measures.
- Do not delete or aggregate repeated `student_vle` rows solely because a candidate key is non-unique.
- Distinguish observation, association, prediction, and causation. Do not claim causal effects from association alone.
- Document the purpose, implementation, validation, interpretation, and decision for substantive transformations.

## Repository map

- `docs/` — architecture, data dictionary, analysis log, and engineering phase closure.
- `sql/00_database/` — database and schema setup scripts.
- `sql/01_raw/` — RAW table definitions and source loading.
- `sql/02_quality/` — data-quality checks, repeated-record characterization, and results registry.
- `sql/03_staging/` — typed STAGING creation and integrity validation.
- `sql/04_analytics/`, `sql/05_marts/`, `sql/06_kpis/` — planned analytical outputs, marts, and metric definitions.
- `src/` — Python ingestion, profiling, quality support, and justified advanced analytics.
- `notebooks/` — documented workflow and exploratory work.
- `powerbi/` — reporting documentation and deliverables.
- `reports/` — final analytical report, to be completed after findings are validated.
- `tests/` — reusable checks.
- `config/` — non-secret configuration templates.

## Data and security policy

The local PostgreSQL database is the working data store. Raw OULAD CSV files, passwords, `.env` files, private connection settings, and secrets must not be committed. `.env.example` must contain placeholders only.

## Source

Open University Learning Analytics Dataset (OULAD): https://research.stem.open.ac.uk/ouanalyse/dataset/

The UCI Machine Learning Repository Dataset 349 was used for reproducible acquisition of the dataset archive. Data licensing and attribution requirements remain applicable; the repository's code licence does not replace them.

## Current status

**Last updated:** 29 October 2026

The core data-engineering implementation and validation are complete. The analytical phase is in preparation; no analytical findings or recommendations have been validated yet.

- Seven RAW tables are loaded and reconcile to the established row-count baseline.
- Seven typed STAGING tables have been created. STAGING row counts match RAW for all seven tables.
- Checks C2 and S1–S4 confirmed the selected type conversions, missing-token-to-NULL reconciliation, zero remaining `?` tokens in the checked STAGING fields, tested score bounds, and numeric VLE week ranges.
- The data-quality registry contains 29 records and 29 distinct test codes: 25 `PASS` and 4 `REVIEW`. Historical `executed_at` values remain NULL because exact execution timestamps were not captured.
- Four review items remain documented: the `student_vle` candidate key, categorical-domain reference documentation, negative relative VLE days, and submission timing relative to assessment days.
- No `student_vle` rows were deleted, and `sum_click` was not aggregated.

The analytical phase has progressed through saved read-only WO-1 diagnostics covering database/STAGING reconciliation, student and assessment join cardinality, activity coverage, resource matching, presentation profiles, and IMD missingness. The saved notebook contains execution outputs from a prior local PostgreSQL session; it is not evidence of a fresh execution during this documentation update. Focused category-total and NULL/unclassified reconciliation remains open for AN2.02, AN2.04, and AN2.05 before detailed subgroup claims are published. The non-unique `student_vle` candidate key remains unresolved, and no analytical views, validated KPIs, dashboard findings, or recommendations have been produced. The engineering phase is revisited only if a concrete analytical blocker is identified.

See `docs/data_engineering_phase_closure.md` for the detailed handover and remaining interpretation caveats.

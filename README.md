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
- `sql/04_analytics/` — executed and reviewed WO-1, WO-2, and AN5 investigative SQL; future analytical views remain separate from these investigations.
- `sql/05_marts/` and `sql/06_kpis/` — reserved for validated reporting marts and approved KPI definitions; neither layer is implemented yet.
- `src/` — shared Python database execution support and project utilities; source acquisition, profiling, and quality workflows are also documented in notebooks.
- `notebooks/` — documented workflow and exploratory work.
- `powerbi/` — reporting documentation and deliverables.
- `reports/` — final analytical report, to be completed after findings are validated.
- `config/` — non-secret configuration templates.

## Data and security policy

The local PostgreSQL database is the working data store. Raw OULAD CSV files, passwords, `.env` files, private connection settings, and secrets must not be committed. `.env.example` must contain placeholders only.

## Source

Open University Learning Analytics Dataset (OULAD): https://research.stem.open.ac.uk/ouanalyse/dataset/

The UCI Machine Learning Repository Dataset 349 was used for reproducible acquisition of the dataset archive. Data licensing and attribution requirements remain applicable; the repository's code licence does not replace them.

## Current status

**Last updated:** 7 November 2026

The core RAW, QUALITY, and STAGING engineering foundation is complete within its documented scope. WO-1 and WO-2 analytical investigations have also been executed and reviewed from retained local PostgreSQL notebook evidence. The latest reviewed WO-2 notebook contains 21 executed canonical queries, 28 result sets, 857 displayed rows, no saved tracebacks, and no runner row-cap truncation. This documentation review did not reconnect to the local database or rerun SQL.

- Seven RAW and seven typed STAGING tables remain preserved; historical row counts reconcile.
- The quality registry retains its historical 29 tests: 25 PASS, 4 REVIEW, and 0 FAIL. Historical `executed_at` values remain NULL.
- WO-1 analytical-readiness and its 132-group targeted reconciliation scope are complete.
- WO-2 is complete for its 21-query execution and saved-output review. Its results and interpretation boundaries are recorded in `docs/analysis_log.md` and `docs/analysis_progress_ledger.md`.
- The repeated `student_vle` candidate key remains non-unique. No source rows were deleted, deduplicated, or aggregated.
- AN5 — Engagement Sensitivity is closed. Five read-only SQL investigations, quantitative review, and eight notebook visualizations were completed from the owner's retained local PostgreSQL execution. The accepted operational definition of recorded in-course VLE activity is documented in `docs/AN5_engagement_sensitivity_plan.md`. No composite engagement score, causal claim, intervention threshold, or predictive feature is approved.
- AN6 — Recorded VLE Activity Patterns is the next analytical work order. It will validate in-course activity presence/coverage, distinct active days, and resource breadth under the accepted AN5 definition.
- AN7–AN11, validated KPIs, analytical marts, Power BI, and the final analytical report remain downstream work.

The WO-2 implementation, documentation updates, and complete AN5 workstream are integrated into `main` through PRs #9–#13. GitHub Actions and synthetic runner tests are not project acceptance gates; analytical acceptance relies on controlled read-only execution, retained outputs, and grain/denominator reconciliation. The project owner reports that repository Actions were disabled in GitHub settings; this setting was not independently verified through the repository integration. See the progress ledger for current repository state and validation policy.

See `docs/data_engineering_phase_closure.md` for the engineering handover and `docs/AN5_engagement_sensitivity_plan.md` for the AN5 design, query inventory, and execution gates.

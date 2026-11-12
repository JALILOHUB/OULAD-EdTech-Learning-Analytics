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
- `scripts/` — command-line orchestration utilities, including the AN5 read-only execution entry point.
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

**Last updated:** 12 November 2026

The PostgreSQL RAW, QUALITY, and STAGING engineering foundation is complete within its documented scope. WO-1 and WO-2 are complete within their approved investigative scopes. AN5 — Engagement Sensitivity and AN6 — Recorded VLE Activity Patterns are closed; AN6 was merged into `main` by PR #16 at commit `4b707623e5dc0ecf16e93311c2b466d822ad9d35`.

- Seven RAW and seven typed STAGING tables remain preserved. The historical 29-test quality registry records 25 PASS, 4 REVIEW, and 0 FAIL; its historical `executed_at` values remain NULL.
- The repeated `student_vle` candidate key remains non-unique. No source rows were deleted, deduplicated, or aggregated.
- AN5 evaluated R0/R1/R2 metric sensitivity and retained eight result sets and eight visual summaries. Its 89.68% coverage is overall any-window activity coverage.
- AN6 retained six complete result sets. In-course recorded-activity coverage is 28,500 / 32,593 registered student-presentations (87.44%). Its 10,655,280 activity rows reconcile across temporal summaries; 9,966,292 are in-course and 688,988 are pre-course. All activity rows matched resource metadata.
- AN6 describes recorded platform activity, not learning quality, attention, effort, achievement, or causality. Activity-row/click volumes remain sensitive to unresolved repeated-source-row semantics.
- **AN7 — Outcome Associations is prepared but not executed.** Its package is on the separate `work/an7-outcome-associations` branch, 11 commits ahead of `main` and 0 behind at the reviewed repository state. No AN7 SQL has been executed. The branch is not part of this release milestone.
- AN8 predictive readiness, AN9 validated metrics and analytical marts, AN10 Power BI, and AN11 the final analytical report remain outstanding. The separate Data Science / Machine Learning phase is deferred until the analytical phase is complete and its exit criteria are met.

The current AN7 execution contract, safeguards, and work orders are documented in `docs/AN7_outcome_associations_plan.md` on the AN7 branch. The AN6 evidence and closure decision are retained in `notebooks/08_an6_recorded_vle_activity_patterns.ipynb`, `docs/AN6_recorded_vle_activity_patterns_plan.md`, and the analysis records.

The proposed `v1.1.0` release is intended to mark the completed investigative milestone through AN6 only. It does not claim completion of production analytics, KPI approval, Power BI, the final analytical report, predictive modelling, or the full analytical phase.

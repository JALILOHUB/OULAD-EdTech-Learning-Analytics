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
- `sql/04_analytics/` — executed and reviewed WO-1, WO-2, AN5, AN6, and AN7 investigations; AN8.01–AN8.04, AN8.10–AN8.12, AN8.20, and AN8.30–AN8.36 have been executed locally; 17 CSV result sets and integrated diagnostics are retained in Notebook 10. Part 3 semantic validation remains planned and unexecuted.
- `sql/05_marts/` and `sql/06_kpis/` — reserved for validated reporting marts and approved KPI definitions; neither layer is implemented yet.
- `src/` — shared Python database execution support and project utilities; source acquisition, profiling, and quality workflows are also documented in notebooks.
- `scripts/` — command-line orchestration utilities, including the read-only execution entry points retained for completed investigative work.
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

**Last updated:** 22 November 2026

The PostgreSQL RAW, QUALITY, and STAGING engineering foundation is complete within its documented scope. WO-1 and WO-2 are complete within their approved investigative scopes. AN5 — Engagement Sensitivity, AN6 — Recorded VLE Activity Patterns, and AN7 — Outcome Associations are closed within their documented scopes.

- Seven RAW and seven typed STAGING tables remain preserved. The historical 29-test quality registry records 25 PASS, 4 REVIEW, and 0 FAIL; its historical executed_at values remain NULL.
- The repeated student_vle candidate key remains non-unique. No source rows were deleted, deduplicated, or aggregated.
- AN5 evaluated R0/R1/R2 metric sensitivity and retained eight result sets and eight visual summaries. Its 89.68% coverage is overall any-window activity coverage.
- AN6 retained six complete result sets. In-course recorded-activity coverage is 28,500 / 32,593 registered student-presentations (87.44%). Its 10,655,280 activity rows reconcile across temporal summaries; 9,966,292 are in-course and 688,988 are pre-course. All activity rows matched resource metadata.
- AN6 describes recorded platform activity, not learning quality, attention, effort, achievement, or causality. Activity-row/click volumes remain sensitive to unresolved repeated-source-row semantics.
- **AN7 — Outcome Associations is analytically closed.** Five read-only investigations returned seven complete result sets. The retained Notebook 09 contains 33 executed Python code cells, the one-to-one 32,593-row analytical merge, 264 binary effect estimates, 132 ordinal estimates, 660 sensitivity rows, and 24 visualizations (including nine sensitivity figures generated from retained CSV evidence). The final stage report is reports/AN7_final_report.md.
- AN7 found consistent presentation-level associations between post-registration activity and retrospective outcomes. Active-day rate is the primary candidate for the later AN10 predictive-readiness review; resource breadth is secondary because exposure opportunity is not normalized. These are associations, not causal or predictive findings. No production KPI, model feature, threshold, or intervention rule is approved.
- **AN8 — Validated Metrics & Marts is OPEN.** The initial read-only extraction was executed locally: AN8.01–AN8.04, AN8.10–AN8.12, and AN8.20. It established 32,593 validated student-presentations, 10,655,280 source activity rows, 39,605,099 recorded clicks, zero unmatched activity rows, 9,966,292 in-course rows, and 688,988 pre-course rows. These results are descriptive extraction/reconciliation evidence, not an approved metric catalogue. AN8.30–AN8.36 have been executed locally and exported as 17 retained CSV result sets. Notebook 10 Sections 19.01–19.07 contain saved integrated diagnostics, Section 20 records evidence-to-decision links, and Section 21 summarizes educational findings. The current Part 2 interpretation is `reports/AN8_part2_analytical_findings_report.md`; the initial scope report remains historical. Part 3 is planned as source-semantics-first cleaning using an immutable original source, a separate working copy, versioned snapshots, and an isolated `oulad_an8_work` database (not yet created). Negative relative-day values are valid pre-presentation offsets under the official OULAD definition; exact calendar conversion and the `date_submitted=-1` interpretation remain gated on further evidence. AN9 is proposed to compare a source-faithful baseline, a validated working representation, and their educational impact. The former AN8 Predictive Readiness Gate is renumbered AN10 and is deferred until after the analytical dashboard stage. AN11 remains the consolidated final analytical report. The separate Data Science / Machine Learning phase starts only after the analytical phase is complete, its exit criteria are met, and the AN10 readiness decision supports proceeding.

The AN7 execution evidence, analytical interpretation, sensitivity results, limitations, and AN10 predictive-readiness handover are documented in notebooks/09_an7_outcome_associations.ipynb, docs/AN7_outcome_associations_plan.md, reports/AN7_final_report.md, docs/analysis_log.md, and docs/analysis_progress_ledger.md. The overall final analytical report in reports/final_report.md remains a later consolidated deliverable; the AN7 stage report does not replace it.

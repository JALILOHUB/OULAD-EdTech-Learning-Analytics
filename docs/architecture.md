# Project Architecture

**Project Owner & Lead Analyst:** Abdeljalil El Khyati  
**Updated:** 2026-11-14

## 1. Business-to-technical flow

Official OULAD source → Python source acquisition and profiling → PostgreSQL `raw` → SQL data-quality checks and `quality.test_results` registry → PostgreSQL `staging` → planned `analytics` views / `mart` tables → Power BI. Python statistical analysis and machine learning are reserved for questions that justify them.

## 2. Why SQL is the backbone

The project demonstrates real relational-data work: joins, aggregation, CTEs, subqueries, `CASE` expressions, window functions, date logic, quality checks, and analytical views.

Python is not used to hide SQL work. It is used where it adds value: ingestion, profiling, statistical analysis, advanced transformations, and later machine learning when justified.

Power BI is the communication layer, not the raw-data storage layer.

## 3. Responsibilities by layer

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

## 4. Reproducibility requirements

Each substantive transformation or metric should have: (1) a stated purpose, (2) a version-controlled implementation, (3) a validation check, (4) an evidence-based interpretation, and (5) a recorded decision in `docs/analysis_log.md`.

## 5. Current implementation and analytical state

Source acquisition and profiling, RAW table creation and loading, quality checks and registry setup, and STAGING table creation are complete within the documented engineering scope. The four recorded engineering `REVIEW` items remain visible in `docs/data_engineering_phase_closure.md`; analytical consistency checks do not automatically close their source-semantics questions.

WO-1 and WO-2 investigative work is complete within its recorded scope. AN0.07 verified actual RAW primary-key and index metadata; AN1.10 reconciled the 33,407-row naive-join excess; AN2.10 documented IMD missingness; AN3.01–AN3.08 investigated outcomes, registration, withdrawal, and recorded activity; and AN4.01–AN4.10 investigated assessment structure, due dates, scores, banked records, participation, and timing. Retained notebook outputs and interpretation boundaries are recorded in the analysis log and progress ledger. The saved-output review did not rerun database queries.

AN5 — Engagement Sensitivity is **closed**. Five read-only investigations, quantitative scenario review, and eight visualizations are retained in `notebooks/07_an5_engagement_sensitivity.ipynb`. The accepted activity grain is one registered student-presentation, joined on `(code_module, code_presentation, id_student)`. The in-course window is course-relative day 0 through `module_presentation_length`, inclusive. Pre-course and post-course records remain separate diagnostics. The 89.68% AN5.02 coverage figure is overall any-recorded-activity coverage, not in-course-only coverage.

AN6 — Recorded VLE Activity Patterns is **closed and merged into `main`** through PR #16 (merge commit `4b707623e5dc0ecf16e93311c2b466d822ad9d35`). Four read-only investigations returned six complete result sets. The validated registered population contains 32,593 student-presentations, of which 28,500 (87.44%) have in-course recorded activity. The temporal summaries reconcile to 10,655,280 activity rows, including 9,966,292 in-course rows and 688,988 pre-course rows. All activity rows matched resource metadata. These findings remain descriptive and do not establish learning quality or causality.

AN7 — Outcome Associations is **analytically closed** for its approved observational scope. Five canonical read-only investigations returned seven complete result sets, and the retained Notebook 09 records the 32,593-row cohort/one-to-one merge, 264 binary effect estimates, 132 ordinal estimates, 660 sensitivity rows, and 15 visualizations. O1 showed broadly negative Withdrawn contrasts, O2 showed negative Fail contrasts in all 22 module-presentations at all three landmarks, and O3 showed positive ordinal associations in all 22 presentations. Active-day rate is the primary candidate for AN8 readiness review; resource breadth is secondary because it is not exposure-normalized. These are presentation-specific associations, not causal or predictive findings. The 93 undated Withdrawn and nine Fail/date-unregistration cases remain source anomalies; the late-registration sensitivity stratum is sparse. The full interpretation and AN8 handover are documented in the AN7 plan and stage report.

The investigative SQL layer is not the production analytical model. The `analytics` views and `mart` tables have not yet been implemented; validated KPI definitions and curated reporting outputs are not yet approved. AN8 — Validated Metrics & Marts is the next analytical workstream. AN9 — Power BI follows the approval and reconciliation of curated reporting outputs. The former AN8 Predictive Readiness Gate is now AN10 and is deliberately scheduled after the descriptive/diagnostic dashboard stage; it is a decision gate, not model training. AN11 is the consolidated final analytical report. The separate Data Science / Machine Learning phase remains deferred until the analytical phase is complete, its exit criteria are met, and the AN10 readiness decision justifies proceeding.

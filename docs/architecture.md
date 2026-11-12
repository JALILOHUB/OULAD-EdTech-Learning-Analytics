# Project Architecture

**Project Owner & Lead Analyst:** Abdeljalil El Khyati  
**Updated:** 2026-11-12

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

AN7 — Outcome Associations is the **current prepared workstream, not an executed analysis**. Its five read-only SQL investigations, runner, Notebook 09, and plan are held on the separate `work/an7-outcome-associations` branch. The package must pass its documented preflight, outcome/registration reconciliation, assessment-context review, and landmark-cohort approval gate before activity extraction. Preserve student-presentation grain `(code_module, code_presentation, id_student)`, L28/L56/L84 windows, separate course-relative and post-registration time bases, and explicit outcome definitions. Do not use `final_result` as a predictor, assume assessment scores were available at early landmarks, use banked submission date -1 as valid timing, truncate activity at unregistration, or deduplicate source activity. AN7 SQL has not been executed and no AN7 findings are approved.

The investigative SQL layer is not the production analytical model. The `analytics` views and `mart` tables have not yet been implemented; validated KPI definitions and curated reporting outputs are not yet approved. Power BI and the final analytical report remain downstream of AN6–AN9 validation. Predictive/data-science work remains outside the current analytical phase until its evidence-based exit criteria are met.

# Part 3 — Source Semantics and Controlled Cleaning

**Status:** SQL diagnostics authored; not executed. No database, schema, table, index, or source file was created or modified by these scripts.

## Execution contract

The scripts target the isolated `oulad_an8_work` database and the `source_ref` schema. They assume the seven source CSVs have been imported with their original column names and all source fields retained as TEXT. Empty strings are treated as missing for profiling; the literal `?` remains a separate source token. Numeric parsing uses guarded regular-expression checks so unexpected tokens are not silently cast or discarded.

The database and import contract are prerequisites, not part of this read-only SQL package. Do not run these files against `oulad_analytics`, RAW, QUALITY, or STAGING. No Part 3 database setup or import is included here.

## Query inventory

| Query | File | Purpose | Runtime |
|---|---|---|---|
| P3.00 | `P3.00_source_inventory_and_profile.sql` | Relation/column inventory and exact row counts | HIGH |
| P3.01 | `P3.01_student_vle_repeated_event_semantics.sql` | Repeated-key groups, click-value conflicts, R0/R1/R2 sensitivity | HIGH |
| P3.02 | `P3.02_relative_day_semantics.sql` | Negative/zero/positive offsets, boundaries, linked sample rows | HIGH |
| P3.03 | `P3.03_registration_missingness_and_exposure.sql` | Missing registration records with linked learner/activity context | HIGH |
| P3.04 | `P3.04_zero_activity_cohort_semantics.sql` | No-row, pre-course-only, in-course, and other temporal activity states | HIGH |
| P3.05 | `P3.05_assessment_sentinel_and_score_semantics.sql` | `date_submitted=-1`, banked, NULL/zero/nonzero score, key checks | MEDIUM |
| P3.06 | `P3.06_categorical_and_numeric_domain_audit.sql` | Category tokens/domains and numeric ranges across source files | MEDIUM |
| P3.07 | `P3.07_cross_domain_grain_and_join_validation.sql` | Candidate-key uniqueness and join fan-out controls | MEDIUM |
| P3.08 | `P3.08_educational_indicator_baseline.sql` | Source-faithful educational indicator baseline by presentation/outcome | HIGH |

## Required operating rules

1. Execute P3.00 first. Confirm all seven source relations and their column names before running later files.
2. Review actual sample rows before deciding the meaning of any negative/sentinel value.
3. Preserve every source value. These queries are SELECT-only and do not create derived tables.
4. Keep R0 as source-faithful. R1 and R2 are sensitivity scenarios only; neither is approved as source truth.
5. Do not convert relative days into calendar dates until an exact authoritative presentation start date is established.
6. Do not interpret absence of VLE records as absence of learning.
7. Record every later approved transformation in the audit register with rule ID, evidence, affected keys/rows, before/after impact, alternatives, and approval.
8. No persistent DDL, index, data update, or deletion is authorized by this package.

All query files contain the required Question, Expectation, Grain, Source, Safety, Runtime, and Read as headers.

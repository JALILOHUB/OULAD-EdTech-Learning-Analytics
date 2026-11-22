# AN8 Independent Review and Corrected Execution Plan

## Review scope and status

This document consolidates the independent repository review and the subsequent static remediation. The working branch is `feat/an8-preparation-review`, based on `main` at `44af2a2117e524b469e3cf8df9ee77e9f863f250`.

**AN8 initial extraction has been executed locally.** Saved Notebook 10 outputs document AN8.01–AN8.04, AN8.10–AN8.12, and AN8.20. The owner approved an extension; AN8.30–AN8.36 are prepared but not executed. No curated reporting tables exist. The branch is not merged.

## Corrections made after the independent review

| Finding | Disposition |
|---|---|
| AN8.01 full scan risk | Replaced exact activity-table count with catalog-only relation inventory; estimates are explicitly labeled |
| AN8.02 did not enforce a stop/go gate | Added duplicate-key, NULL-key, row/distinct-key, and bidirectional key-set checks; runner now blocks downstream work on failure |
| AN8.03 could run without verified grain | Runner requires AN8.02 gate |
| AN8.04 multiple result sets | Runner validates expected count and checks truncation for every set |
| AN8.20–AN8.23 repeated high-cost scans | Consolidated activity partitions, clicks, active days, resource breadth, and exposure-adjusted rate into one AN8.20 scan; retired AN8.21–AN8.23 |
| AN8.22 numerator was not registration bounded | Corrected by consolidating the registration-bounded numerator into AN8.20 |
| Runner lacked complete extract validation | Added per-result-set truncation checks and AN8.20 row/key validation against AN8.02 cohort denominator |
| No durable visualization source | Added CSV + manifest export; visualization cells consume retained extracts or future curated tables only |
| Notebook was a skeleton | Rebuilt as a staged workflow with pre-query explanations, independent review stages, and a no-Run-All instruction |
| `outputs/an8/` was not ignored | Added to `.gitignore` |
| AN8.05 mentioned but absent | Removed the accidental AN8.05 expectation; AN8.04 is the single course/assessment context query with two result sets |
| AN7 visual count conflict | Notebook README now records 24 figures; analysis log and AN7 final report already describe 24 (15 original plus nine sensitivity figures) |

## Consolidated source extraction design

The owner requires source queries to run once and all subsequent visualizations to be independent of those source queries. The revised workflow therefore retains each complete SQL result as a CSV and non-sensitive manifest under `outputs/an8/extracts/`. Following review, the retained extracts are intended to be loaded into curated PostgreSQL reporting tables under a separately approved DDL/load work order. Charts, tables, and Power BI then read the curated tables or retained exports; they do not rerun the large source scans.

The persistent reporting tables are planned, not created. No DDL or data load is part of this branch.

## Revised execution inventory

- AN8.01: catalog-only relation inventory.
- AN8.02: mandatory key/grain/NULL/key-set gate.
- AN8.03: outcome denominator profile, gated by AN8.02.
- AN8.04: course and assessment context; two result sets.
- AN8.10–AN8.12: lightweight descriptive context.
- AN8.20: sole high-cost activity scan; one row per registered student-presentation.
- AN8.21–AN8.23: retired; do not execute.
- AN8.30–AN8.32: deferred pending reporting-table contract.
- AN8.33: candidate measure register only.
- AN8.40–AN8.41: readiness/validation SELECTs only; no DDL.

## Required first local batch

Only after the owner synchronizes and confirms the branch files:

`AN0.01 → AN8.01 → AN8.02 → AN8.03`

AN8.02 must pass all gates before AN8.03 or any activity extract. AN8.20 is a later standalone query, run once after reviewing the light outputs. Notebook 10 must not be run with Run All.

## Remaining acceptance work

Static code and documentation review does not prove SQL correctness on the user's database. The following remain pending:
- verify the synchronized local files and working tree;
- execute the first batch read-only and inspect actual outputs;
- validate AN8.20 SQL against PostgreSQL, result completeness, row/key grain, temporal partition totals, and AN6 reconciliation;
- review the saved CSVs and manifest;
- approve the curated reporting table design and DDL/load process before any persistent change;
- validate loaded tables against the retained extract manifest;
- confirm all visuals consume only curated tables or retained extracts.

## Explicit non-actions

No database connection or AN8 query was executed during static remediation. No RAW/QUALITY/STAGING changes, deduplication, index, view, table, schema, DDL, data load, PR, or merge was performed. No metric/KPI/threshold/weighted score/predictive feature/causal claim/intervention rule is approved.


## 2026-11-17 — Initial execution review and approved extension

The first local execution established source readiness, student-presentation grain, outcome denominators, course/assessment context, registration timing, withdrawal-date reconciliation, score missingness, and an R0 activity extract. It did not complete the distributional and sensitivity work needed for validated reporting metrics. The detailed values and analytical rationale are recorded in `reports/AN8_initial_results_and_scope_extension.md`.

AN8.30–AN8.36 have been added as read-only SQL and Notebook 10 execution cells. They remain unexecuted. The runner now requires the course-context gate before activity, exposure, and assessment analyses, and high-cost scans must be run individually. Static preparation is not SQL parser validation or database execution evidence.

The owner approved preserving a local source-file copy outside the project before cleanup and moving to purpose-specific derived analytical datasets. Source evidence and RAW remain immutable. Any cleaning must be versioned, reason-coded, reconciled, and sensitivity-tested; no blanket deletion or automatic deduplication is approved. The external backup remains an owner-planned action and is not verified here.

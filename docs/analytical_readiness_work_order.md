# WO-1 — Analytical Readiness and Join Validation

**Status:** Execution pending; no live database findings have been accepted.  
**Work branch:** `work/wo-1-analytical-readiness`  
**Execution notebook:** `notebooks/04_sql_analytics.ipynb`

## Purpose

WO-1 establishes a verified baseline for the analytical phase. It checks database identity and session safety, compares the existing quality registry and STAGING row counts with documented baselines, inspects physical relation sizes and indexes, validates student-presentation keys, and quantifies assessment-join fan-out.

All queries are diagnostic and read-only. WO-1 does not modify source data, create database objects, rerun completed ingestion, or repeat the completed engineering quality suite.

## Scope and execution order

| Query ID | Diagnostic | Historical reference or decision gate |
|---|---|---|
| AN0.01 | Database identity and read-only settings | Expected database: `oulad_analytics`; read-only mode must be enabled |
| AN0.02 | Quality-registry snapshot | 29 records/codes; 25 PASS, 4 REVIEW, 0 FAIL; historical `executed_at` values may be NULL |
| AN0.03 | Exact STAGING row-count reconciliation | `courses`: 22; `assessments`: 206; `student_info`: 32,593; `student_registration`: 32,593; `student_assessment`: 173,912; `vle`: 6,364; `student_vle`: 10,655,280 |
| AN0.04 | STAGING relation sizes and index inventory | Record observed catalog state; do not infer indexes from CTAS-created tables |
| AN1.01 | Student-key completeness and uniqueness | Validate the three-column key in both student tables |
| AN1.02 | Composite-key set and distinct-student reconciliation | Compare key populations in both directions |
| AN1.03 | Assessment join fan-out | Compare student-only joining with the assessment-metadata path |
| AN2.01 | Student counts by presentation | Eligible only when AN1.01 confirms both student-table keys |
| AN2.02 | Final-result distribution | Eligible only when AN1.01 confirms both student-table keys |

## Technical controls

- The query runner reads local connection settings without displaying credentials.
- Each query uses a separate PostgreSQL connection configured with `default_transaction_read_only=on`, `statement_timeout=120000`, and `lock_timeout=5000`.
- These session settings are safeguards, not a substitute for least-privilege database permissions.
- Exact row counts are computed inside PostgreSQL. The full `student_vle` table is not transferred to Pandas.
- Result display is capped at 500 rows; WO-1 queries are designed to return compact diagnostic summaries.
- Historical counts are reference points, not proof of the current database state. Any discrepancy requires investigation before dependent analysis proceeds.
- The notebook uses canonical SQL files by stable query ID. SQL definitions remain under `sql/04_analytics/`; they are not duplicated in notebook code cells.

## Evidence review and acceptance criteria

For each substantive result, the analysis record must capture:

1. The question and expected result.
2. The observed result and execution time.
3. Plausible explanations for material deviations.
4. A discriminating check where the cause is not yet established.
5. The resulting decision and its impact on the next stage.
6. Relevant grain, denominator, join behavior, missingness, time basis, and limitations.
7. The accepted decision-log entry in `docs/analysis_log.md`.

WO-1 is complete only after eligible queries have executed successfully, outputs have been interpreted, decisions have been recorded, local changes have been reviewed with `git diff`, and the progress ledger has been updated. Until then, no live analytical finding is claimed.

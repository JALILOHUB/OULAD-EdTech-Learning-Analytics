# WO-1 — Analytical Readiness and Join Validation

**Status:** Completed for the defined WO-1 scope; follow-up questions are recorded separately.  
**Work branch:** `work/wo1-reconciliation-cells`  
**Verified notebook commit:** `fab3a99b5223940443ae9e5f10edea893cb301ce`  
**Execution notebook:** `notebooks/04_sql_analytics.ipynb`

## Purpose

WO-1 establishes the analytical-readiness baseline for its defined diagnostic scope. It checks database identity and session safety, compares the existing quality registry and STAGING row counts with documented baselines, inspects physical relation sizes and indexes, validates student-presentation keys, and quantifies assessment-join fan-out.

Its completion does not imply that every question associated with AN0, AN1, or AN2 has been resolved. AN0.07, AN1.10, and AN2.10 remain separately identified follow-up checks and are carried into the next analytical work order.

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

The saved notebook contains retained execution outputs for AN0.01–AN0.04, AN1.01–AN1.09, and AN2.01–AN2.09 from the recorded local PostgreSQL session. The targeted reconciliation cells for AN2.02, AN2.04, and AN2.05 were subsequently executed by the project owner and their outputs were saved in the synchronized notebook.

Across 22, 66, and 44 groups respectively, all 132/132 category-count groups reconciled to their single presentation-level denominator, and all 132/132 rounded-percentage groups reconciled within the tested rounding tolerance. No explicit `<NULL>` output category was emitted. This does not imply source-wide NULL absence; historical IMD missingness remains documented in the analysis log.

The targeted validation gate is complete. WO-1 establishes analytical readiness and descriptive profile evidence for its defined scope; it does not constitute a validated KPI or predictive-modelling phase. AN0.07, AN1.10, and AN2.10 remain follow-up questions whose execution is not established by the evidence reviewed for this update. Analytics views, KPI approval, dashboards, and business recommendations remain downstream deliverables.

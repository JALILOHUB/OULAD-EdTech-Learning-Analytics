# Notebooks

Project notebooks preserve analytical reasoning, reproducible procedures, evidence, and interpretation. Canonical SQL definitions for database objects, ingestion, quality checks, STAGING validation, and analytical queries are maintained under `sql/`.

## Notebook standards

- Each substantive code cell is preceded by a concise explanation of its purpose and method.
- Code cells remain reproducible and contain no hard-coded secrets.
- Execution claims are supported by retained, reviewable outputs.
- RAW remains unchanged; the full `student_vle` table is not loaded into memory without a documented technical justification.
- Exploratory observations are distinguished from validated findings.
- Substantive decisions and outcomes are recorded in `docs/analysis_log.md`.
- Project notebooks and code use English for consistent technical documentation.

## SQL analytics notebook

`04_sql_analytics.ipynb` resolves canonical SQL files by work-order ID through `src/analytics/db.py`. The helper uses read-only sessions, a statement timeout, and bounded result retrieval. SQL files remain the single source of truth; query text is not duplicated in notebook code cells.

The saved `04_sql_analytics.ipynb` is the historical WO-1 evidence notebook. Its outputs are evidence of prior local PostgreSQL execution, not fresh execution during later documentation work. The owner completed the focused reconciliation for AN2.02, AN2.04, and AN2.05 across 132 groups; see `docs/analysis_log.md` and `docs/analysis_progress_ledger.md`. Do not rebuild or repurpose this notebook for WO-2.


## WO-2 notebook organization

WO-2 uses one dedicated notebook: `05_wo2_analytical_investigation.ipynb`. It orchestrates all 21 canonical SQL files across WO2-A–WO2-E, displays every result set, preserves query outputs in `query_results`, and provides explicit review gates between dependent investigations.

The notebook is deliberately separate from `05_python_advanced_analytics.ipynb`; the filename is distinct and does not replace that notebook. The historical `04_sql_analytics.ipynb` remains the WO-1 evidence record and is not modified.

The notebook's live-execution flag defaults to disabled and is enabled only through an explicit authorization prompt after the AN0.01 preflight. It must not be used with Run All; each query is run individually after explicit authorization and the required review checkpoint. A closed review gate prints a clear NOT EXECUTED message and returns without sending SQL or raising a traceback. Review checkpoints return REVIEW BLOCKED when prerequisites are missing. The AN1.01 dependency refresh is also protected by the preflight, authorization, and AN0.07 review gates. AN3.06 is a high-runtime scan and must run alone. AN4.06 is reviewed before AN4.03. WO2-F is evidence review and documentation closeout, not a separate execution notebook.


### WO-2 execution flow

The WO-2 notebook follows the WO-1-style sequence: repository/import setup, environment-readiness checks, a separate AN0.01 database-identity and read-only preflight, execution-helper validation, then one query cell followed by interpretation and manual review. The AN0.01 preflight must confirm `oulad_analytics` and both read-only settings before live WO-2 execution is enabled.

The live-execution switch defaults to `False` and is deliberately enabled in a separate cell only after the preflight passes. The helper checks expected result-set counts for all 21 canonical WO-2 query IDs, displays every result set, reports row caps/truncation and batch runtime, and stores returned outputs in `query_results`. A current AN1.01 student-presentation key check is retained as a dependency before AN1.10. Each query is executed individually; do not use Run All. AN3.06 remains a standalone high-runtime scan, and AN4.06 is reviewed before AN4.03.


## 2026-11-05 — Local WO-2 execution and checkpoint behavior

The corrected AN0.07 SQL was executed locally and returned three complete result sets in 0.191 seconds. The output showed six matching validated RAW primary keys, the expected absence of a primary key on `student_vle`, six primary-key constraints in total, no other constraint types, and no indexes on `raw.student_vle`. See the progress ledger and analysis log for the complete evidence boundary and interpretation.

The notebook's review controls were adjusted after the owner encountered a closed-gate traceback. Expected workflow conditions (missing review approval, missing authorization, or missing preflight) now produce explicit status messages and skip the query without raising an exception. Actual SQL/database errors remain visible. The AN1.01 current key refresh now checks the same preflight and authorization requirements as WO-2 queries.

The saved notebook now contains the WO-2 execution outputs and interpretation/checkpoint records. AN4.07–AN4.10 passed result-count checks, but separate human review checkpoints are not recorded for each of those four queries; their interpretations retain this limitation.


## WO-2 execution closure

The saved `05_wo2_analytical_investigation.ipynb` contains the retained execution record for all 21 canonical WO-2 queries: 28 result sets, 857 displayed rows, 34 executed code cells, no saved tracebacks, and no runner row-cap truncation. The review of this saved artifact did not reconnect to PostgreSQL or rerun SQL. AN4.07–AN4.10 do not each have a separate human review checkpoint.

## AN5 — Engagement Sensitivity

AN5 — Engagement Sensitivity is **closed**. Its five canonical SQL investigations, Python execution script (`scripts/run_an5.py`), and direct-cell notebook are retained in the repository. The five queries returned eight result sets; quantitative review/export and eight visualizations are retained in `07_an5_engagement_sensitivity.ipynb`. The accepted definition and closure decision are documented in `docs/AN5_engagement_sensitivity_plan.md` Section 17. The former `reports/AN5_engagement_sensitivity_report.md` was intentionally not retained; its evidence is preserved in the plan, analysis log, progress ledger, and notebook. Do not recreate a duplicate report.


## AN5 notebook

`07_an5_engagement_sensitivity.ipynb` orchestrates AN5.01–AN5.05. It verifies the `oulad_analytics` database identity and read-only session settings, then executes each query directly in its own cell without an interactive authorization prompt. Run cells individually from top to bottom; do not use Run All. `scripts/run_an5.py` provides the equivalent sequential command-line path, supports selecting query IDs, and can export bounded CSV result sets plus a non-sensitive JSON manifest.

The five-query package has been executed locally and its saved outputs reviewed. The notebook retains all eight result sets, Python-only summary/export outputs, and eight visualizations. The review and plotting cells use retained DataFrames only and do not rerun SQL. Do not use Run All. AN5 is closed; no further AN5 SQL scan is required. The final analytical report remains a downstream deliverable and is not represented as complete.


## Validation approach

GitHub Actions and synthetic runner tests were retired on 2026-11-06. The disposable PostgreSQL fixture and mocked tests did not validate the actual OULAD data or analytical outputs and are not project acceptance gates. Validate canonical SQL through controlled read-only execution against `oulad_analytics`, inspect actual result sets, reconcile grain, joins, denominators and row counts, and retain reviewed notebook outputs. Historical workflow attempts and runner shutdowns are not analytical failures and are not to be retried.


## Notebook naming and execution conventions for new work

New analytical notebooks use the next available two-digit sequence and a work-order identifier, for example `08_an6_recorded_vle_activity_patterns.ipynb`. Existing historical filenames are not renamed because they are evidence references.

Execution controls are work-order-specific rather than forced into one incompatible pattern. WO-2 retains explicit live-execution authorization and review gates. AN5 retains direct-cell orchestration after the AN0.01 read-only preflight. For AN6, use a fresh read-only preflight, execute one canonical SQL investigation at a time, preserve every result set, document observed counts and interpretation immediately below the output, and do not use Run All or concurrent large scans. A query is not marked executed merely because its SQL file or notebook cell exists. Any SQL revision after execution must be recorded with its query version and rerun evidence; query inventories and documentation must be updated together.

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

The saved `04_sql_analytics.ipynb` on the WO-1 branch contains execution outputs for AN0.01–AN0.04, AN1.01–AN1.09, and AN2.01–AN2.09. These are evidence of a prior local session, not a fresh execution during documentation review. Relationship and coverage interpretations are documented in `docs/analysis_log.md`. Focused compact reconciliation remains open for AN2.02, AN2.04, and AN2.05 because wide Pandas output representations abbreviate middle rows. Do not rerun the whole notebook to refresh status.

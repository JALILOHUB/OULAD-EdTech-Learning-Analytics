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

WO-1 is an execution-stage work item. Its findings remain unvalidated until the eligible queries have run successfully and their outputs have been reviewed.

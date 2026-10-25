# Notebooks

Notebooks document the reasoning, evidence, and reproducible workflow for the OULAD project. The canonical SQL definitions for database tables, ingestion, quality checks, STAGING validation, and analytics remain under `sql/`.

## Notebook standards

- Explain the purpose and reasoning before each substantive code block.
- Keep code cells reproducible and avoid hard-coded secrets.
- Do not claim that a query or transformation was executed unless the output is present and verified.
- Keep RAW unchanged and do not load the full `student_vle` table into memory without a justified need.
- Distinguish exploratory observations from validated findings.
- Record substantive decisions and outcomes in `docs/analysis_log.md`.
- Keep project notebooks and code files in English unless a notebook's explicit educational purpose requires another language.

## SQL analytics notebook

`04_sql_analytics.ipynb` calls canonical SQL files by work-order ID through `src/analytics/db.py`. The helper uses read-only sessions, a statement timeout, and bounded result retrieval. Query files remain the single source of truth; do not copy SQL text into the notebook. WO-1 is prepared but must be executed locally and reviewed before its findings are treated as validated.

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

WO-2 execution is organized into grouped notebooks rather than one notebook per query:

- WO2-A: AN0.07 and AN1.10.
- WO2-B: AN2.10 and AN3.01–AN3.03.
- WO2-C: AN3.04–AN3.08.
- WO2-D: AN4.01–AN4.05.
- WO2-E: AN4.06–AN4.10.

These are work-group labels, not replacements for the official AN0–AN11 identifiers. Final notebook paths must be selected after checking the existing notebook inventory. Each code cell must be preceded by a Markdown explanation. Notebooks call canonical SQL files through `src/analytics/db.py`; they do not duplicate SQL definitions. WO2-F is a documentation and evidence-review closeout, not a separate execution notebook.

The runner returns every result set in `result_sets`. The legacy `data`, `rows_displayed`, and `display_truncated` keys continue to refer to the first result set. Each result set includes its statement number and its own display cap/truncation metadata. `elapsed_seconds` records total batch duration, not an independently measured server time for each statement.

# WO-1 — Analytical Readiness and Join Validation

**Status:** Prepared for local execution; not yet executed against the target PostgreSQL database.  
**Branch:** `work/wo-1-analytical-readiness`  
**Primary notebook:** `notebooks/04_sql_analytics.ipynb`

## Objective

Confirm the active database, read-only session settings, existing quality-registry state, current STAGING row counts, physical table sizes and indexes, student-presentation key integrity, and the correct join path for assessment records. No data is modified and no analytical views are created in WO-1.

## Before running

1. Open the project folder in VS Code or a terminal.
2. Confirm the existing local `.env` file is present and contains valid PostgreSQL connection settings. Keep `.env` local and untracked; never publish credentials or connection secrets.
3. Activate the existing virtual environment in PowerShell:

   ```powershell
   .\.venv\Scripts\Activate.ps1
   ```

4. Start Jupyter Lab from the repository root:

   ```powershell
   jupyter lab notebooks/04_sql_analytics.ipynb
   ```

5. Run the notebook from top to bottom. The notebook uses canonical SQL files by query ID; do not paste alternate SQL into the notebook.

## Execution order

| Query ID | Purpose | Expected historical reference |
|---|---|---|
| AN0.01 | Database identity and read-only settings | Database `oulad_analytics`; read-only setting is on |
| AN0.02 | Quality registry snapshot | 29 records/codes; 25 PASS, 4 REVIEW, 0 FAIL; historical `executed_at` may be NULL |
| AN0.03 | Exact STAGING row-count reconciliation | 22, 206, 32,593, 32,593, 173,912, 6,364, and 10,655,280 by table |
| AN0.04 | STAGING physical sizes and index inventory | Inspect actual catalog state; do not assume indexes exist |
| AN1.01 | Key completeness and uniqueness | Both student tables should have complete unique three-column keys |
| AN1.02 | Key-set and distinct-student reconciliation | No complete composite keys unique to either table if populations match |
| AN1.03 | Assessment join fan-out | The `id_student`-only join may multiply rows; use assessment metadata to recover presentation |
| AN2.01 | Student counts by presentation | Run only if AN1.01 passes for both student tables |
| AN2.02 | Final-result distribution | Run only if AN1.01 passes for both student tables |

## Safety design and limitations

- The Python helper reads credentials from local environment variables and never prints passwords.
- Each query connection sets `default_transaction_read_only=on`, `statement_timeout=120000`, and `lock_timeout=5000`. AN0.01 reports the active settings for verification.
- This is a session-level safeguard, not a replacement for least-privilege database permissions. No role, grant, schema, table, index, or view is created by WO-1.
- AN0.03 performs exact `COUNT(*)` queries. The large `student_vle` table is scanned in PostgreSQL, but its rows are not loaded into Pandas.
- Notebook outputs are capped at 500 rows by default. All current WO-1 queries return small summary outputs.
- The historical row counts are comparison baselines, not a substitute for live evidence. Investigate any difference before proceeding.
- Do not rerun completed RAW loading, STAGING creation, or engineering quality checks as part of this work order.

## Result review protocol

For every substantive result, record:

1. Question and expectation.
2. Observed result.
3. At least two plausible explanations when the result differs from expectation.
4. A discriminating test or evidence that could separate those explanations.
5. Decision and impact on the next step.
6. Limitations, denominator, join grain, and whether the result is descriptive or associative.
7. A concise decision-log entry after the interpretation is accepted.

Do not mark WO-1 complete until the query outputs are reviewed, the local files are applied, and `git diff` is inspected. This work order does not claim that any query has already been executed.

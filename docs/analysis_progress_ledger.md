# OULAD Analysis — Progress Ledger

Updated: 2026-11-06

Repository: JALILOHUB/OULAD-EdTech-Learning-Analytics  
Default branch: `main`  
WO-1 evidence branch: `work/wo1-reconciliation-cells`  
WO-1 notebook commit: `fab3a99b5223940443ae9e5f10edea893cb301ce`  
WO-1 integration PR: [#2](https://github.com/JALILOHUB/OULAD-EdTech-Learning-Analytics/pull/2), squash-merged on 2026-10-30  
WO-1 squash merge commit: `91d3369b41e7cfb39c0d58f87ef6f105291c1107`  
Documentation consistency branch: `docs/wo1-documentation-consistency-2026-10-30`  
Pre-documentation safety branch: `backup/pre-wo1-documentation-2026-10-30`  
Preserved backup commit: `7e28dbbc390da99f80eb0ee755b7da39fc0854d5`

The project owner previously verified that the local working tree was clean and that the local and remote WO-1 evidence branch heads matched at `fab3a99`. GitHub records confirm the subsequent PR #2 squash merge. The local machine state after that merge has not been independently verified in this ledger.

## Current verified snapshot — 2026-11-06

This section is the authoritative current status. Chronological entries below preserve what was known and recorded at earlier dates; later evidence supersedes their former next-step instructions. Historical references to synthetic tests and GitHub Actions are retained only as history and are superseded by the 2026-11-06 retirement decision.


## Current repository decision — 2026-11-06

- WO-2 PR #9 and PR #10 are merged into `main`; the saved 21-query execution evidence remains in `notebooks/05_wo2_analytical_investigation.ipynb`.
- Documentation PR #11 and AN5 preparation PR #12 are also merged into `main`.
- Merge commits: #9 `937fa7d0012775b92ba3d30d2897742ab8381222`; #10 `f58ca14800a447b1cc6498c979070ec54419a6ca`; #11 `2303e83f6e522883545172e7e48448c83203a4bf`; #12 `541b4237fe7df677d1a0c49ed077dc1ddb38d889`.
- GitHub Actions and synthetic runner tests are retired. The workflow and synthetic-only test files are absent from `main`. They did not validate the actual OULAD analytical workload and are not acceptance gates. Do not retry historical runner jobs or treat their shutdown signals as analytical failures.
- Run #42140281401 attempt 2 remained `in_progress` at the last verified check. The available GitHub integration exposes no cancellation action and no repository Actions-settings write operation. No retry was requested. The repository-level Actions feature has not been disabled, but no workflow definition remains in `main`.
- Accepted validation evidence: read-only SQL executed against `oulad_analytics`, reviewed result sets, grain/join/denominator reconciliations, retained notebook outputs, and repository diff inspection.
- AN5.01–AN5.03 are the original package; AN5.04 (ranking sensitivity) and AN5.05 (outcome-group activity sensitivity) are the owner-approved additions. The project owner has returned saved local execution outputs for all five queries on `work/an5-five-query-execution`. AN5 interpretation review remains open; AN6 and AN7 remain separate roadmap stages.

### AN5 execution evidence — 2026-11-06

The project owner returned saved local outputs from `notebooks/07_an5_engagement_sensitivity.ipynb`. The read-only preflight passed on `oulad_analytics`, PostgreSQL 18.6; both read-only settings were `on`.

| Query | Result-set row counts | Batch elapsed seconds |
|---|---:|---:|
| AN5.01 | 1, 3, 66 | 660.747 |
| AN5.02 | 69 | 268.471 |
| AN5.03 | 132 | 456.240 |
| AN5.04 | 66 | 70.314 |
| AN5.05 | 264, 22 | 282.843 |
| **Total** | **623 rows / 8 result sets** | **1,738.615** |

All five SQL files returned the expected result-set counts. No saved SQL traceback or runner-level 500-row truncation was recorded. Batch durations are not per-statement timings or total notebook wall-clock time.

Key visible findings:
- AN5.01: R0 10,655,280 rows; R1 9,868,110 distinct six-column tuples; R2 8,459,320 five-column keys. Excess fully identical rows: 787,170. Five-column groups with multiple `sum_click` values: 1,179,074. R1 is 7.39% below R0; R2 is 20.61% below R0.
- AN5.02 R0 overall: 32,593 registered student-presentations, 28,785 distinct students, 29,228 activity-bearing student-presentations, 3,365 without a matching activity row, and 89.68% coverage. Recorded clicks: 39,605,099; student-active-day pairs: 1,808,119; student-active-site pairs: 1,960,496.
- AN5.03 visible AAA 2013J R0 rows: 10,847 pre-course activity rows and 170,135 in-course rows. Negative relative days remain a distinct category; their cause is unknown.
- AN5.04: high Spearman correlation coexists with individual rank changes. AAA 2013J R0/R1 correlation 0.999703 with 276 of 383 ranks changed; GGG 2014B R0/R2 correlation 0.998118 and top-decile Jaccard 0.8876.
- AN5.05: 264 outcome-group rows; small groups occur. All 22 profile-match diagnostic rows show unique matches and zero missing, duplicate, or conflicting profile matches in this extract. Final result is retrospective descriptive grouping, not a predictor.

The saved pandas HTML output abbreviates long DataFrames even though the runner did not truncate them. Therefore, full totals and presentation-level extrema must come from complete retained DataFrames or CSV exports, not from the abbreviated display.

The notebook now includes interpretation/decision Markdown below each query output and a Python-only review/export cell. That cell calculates scenario deltas, denominator invariants, temporal summaries, ranking ranges, outcome summaries, and profile-match totals, then exports complete retained result sets to the ignored local `outputs/an5/` folder without rerunning SQL. The new cell is unexecuted; the notebook has 24 cells, 9 code cells, 8 previously executed code cells, and one new unexecuted review/export cell.

**Current decision:** AN5 is not closed. Do not add another SQL scan yet. Run the Python-only review/export cell while the current kernel still retains `query_results`. If the kernel has restarted, stop and report that state rather than automatically rerunning the expensive SQL. No KPI, source-cleaning rule, causal claim, predictive feature, or intervention is approved. AN6 and AN7 remain separate roadmap stages.

### Roadmap status

| Analytical ID | Current status | Evidence / next dependency |
|---|---|---|
| AN0 — Analytical readiness | WO-1 scope and AN0.07 completed | AN0.07 catalog outputs reviewed: six expected RAW primary keys match; `student_vle` has no primary key; no RAW `student_vle` index rows were returned. |
| AN1 — Grain, keys, and join integrity | WO-1 scope and AN1.10 completed | AN1.10 reconciled the 33,407-row naive-join excess; metadata-aware path returned 173,912 rows and zero unmatched rows. |
| AN2 — Student and presentation profile | WO-1 scope and AN2.10 completed | AN2.10 found 1,111 missing IMD rows across 971 students; no alternative value in the tested comparison. |
| AN3 — Outcomes and withdrawal | WO-2 queries executed and reviewed | AN3.01–AN3.08 saved outputs reviewed; descriptive and denominator caveats retained. |
| AN4 — Assessment analysis | WO-2 queries executed; interpretation review bounded | AN4.01–AN4.10 executed. Separate human review checkpoints are not recorded for each of AN4.07–AN4.10; do not describe every interpretation as individually approved. |
| AN5 — Engagement sensitivity | Five SQL investigations executed; interpretation review pending | Saved notebook evidence records all five queries and eight result sets. Interpretation cells and a Python-only review/export cell are added; the new Python cell remains unexecuted. No activity metric is approved. |
| AN6 — Engagement analysis | Pending AN5 | Requires an approved activity definition and documented limitations. |
| AN7 — Outcome associations | Future | Requires validated measures and explicit hypotheses; association is not causation. |
| AN8 — Predictive readiness | Future decision gate | Requires a defined prediction point, leakage-safe predictors, and temporal validation design. |
| AN9 — Validated metrics and analytical marts | Future | Requires approved metric definitions, grains, denominators, and reconciliation. |
| AN10 — Power BI | Future | Depends on curated reporting outputs and validated metrics. |
| AN11 — Final analytical report | Future | Closes the analytical phase after validated findings, limitations, and recommendations are documented. |

### WO-2 execution evidence

The saved notebook `notebooks/05_wo2_analytical_investigation.ipynb` on `work/wo2-pre-execution-readiness` is the retained execution record. Its reviewed blob SHA is `e94a9d40876fa638718a12152f572ef1562e55d8`.

| Evidence item | Verified saved result |
|---|---:|
| Canonical WO-2 queries executed | 21 / 21 |
| Result sets returned | 28 |
| Displayed rows across result sets | 857 |
| Notebook cells | 92 |
| Code cells executed | 34 / 34 |
| Saved error/traceback outputs | 0 |
| Runner row-cap truncation | None |
| Sum of query-batch elapsed times | 10.099 seconds |

The 10.099-second value is the sum of runner-reported SQL-file batch durations, not an independently measured end-to-end notebook runtime. Pandas text displays may abbreviate middle rows; this is distinct from runner row-cap truncation. AN0.01 preflight and AN1.01 dependency refresh are additional to the 21 canonical WO-2 queries.

### Key WO-2 findings and interpretation boundaries

- **AN0.07:** Six expected RAW primary keys match. `student_vle` has the expected absence of a primary key. The catalog query returned no index rows for `raw.student_vle`; this does not establish uniqueness or justify index creation.
- **AN1.10:** The naive `id_student`-only join returned 207,319 rows versus 173,912 source rows. The 33,407-row excess reconciled to students appearing in multiple presentations. The metadata-aware path returned 173,912 rows with zero unmatched rows.
- **AN2.10:** 1,111 missing IMD rows represent 971 distinct students; all were classified `NO_ALTERNATIVE_VALUE` in the tested comparison. No imputation is approved.
- **AN3.01–AN3.05:** 10,156 Withdrawn student-presentations comprise 10,063 with an unregistration date and 93 without; nine Fail rows also have an unregistration date. These are definition conflicts, not grounds for silently changing outcomes.
- **AN3.04:** The 86.67% withdrawal share for missing registration dates is based on only 45 rows (39 withdrawn), so it is unstable as a general pattern.
- **AN3.06:** Recorded-activity absence is a source-match result, not proof of no learning or no activity elsewhere.
- **AN3.07:** `small_category_flag` tests category totals, not individual outcome cells. Small cells remain possible; align wording and flag semantics before reuse.
- **AN4.02/AN4.04:** Eleven assessments lack due dates; three have 2,865 submission rows in total, while eight have none.
- **AN4.05/AN4.06:** 173 NULL scores are distinct from 329 numeric zero scores. Banked `date_submitted = -1` is a sentinel, not a calendar date.
- **AN4.07–AN4.08:** Outcome and score comparisons are retrospective and cannot be reused as predictors of the same final outcome.
- **AN4.09:** A submission after unregistration does not prove that it was accepted, graded, or valid.
- **AN4.10:** Coverage denominators are status-specific; a student may appear in both banked and non-banked groups. No final weighted-score definition is approved.

### Decisions

| ID | Current decision |
|---|---|
| D-WO2-01 | Accept WO-2 execution as complete for the 21 canonical queries and the saved-output review documented in the 2026-11-06 handover. |
| D-WO2-02 | Treat the saved notebook as historical local execution evidence; this repository review did not reconnect to PostgreSQL or rerun queries. |
| D-WO2-03 | Do not approve KPIs, causal findings, a final weighted score, predictive features, or business rules from WO-2 exploratory outputs alone. |
| D-WO2-04 | Preserve RAW, QUALITY, and STAGING. No persistent database objects were created during WO-2. |
| D-AN5-01 | Compare R0 (all rows), R1 (exact six-column duplicate exclusion for metric calculation only), and R2 (maximum `sum_click` per five-column candidate-key group) without modifying source data. |
| D-AN5-02 | Define the activity measure, grain, common eligible population, time basis, and missing-match handling before interpreting R0/R1/R2 differences. |
| D-AN5-03 | Keep AN6–AN11, KPI/mart approval, Power BI, and predictive modelling dependency-gated. |

### Current open questions

| ID | Question | Status / next action |
|---|---|---|
| OQ-01 | What do repeated `student_vle` rows represent? | Open; AN5 sensitivity analysis and source-semantics review. |
| OQ-02 | What do negative relative VLE dates mean? | Open; preserve separately and validate source time conventions before temporal interpretation. |
| OQ-03 | How should missing unregistration dates be interpreted alongside final outcomes? | WO-2 descriptive conflicts documented; any business rule remains unapproved. |
| OQ-04 | What explains missing assessment dates and how do they relate to submissions? | WO-2 descriptive evidence recorded; semantic interpretation remains limited. |
| OQ-05 | What explains missing scores and banked-submission semantics? | WO-2 profile recorded; no automatic score or banked rule approved. |
| OQ-06 | Are all WO-2 interpretations individually reviewed? | No separate human checkpoints are recorded for AN4.07–AN4.10. Preserve this limitation. |
| OQ-07 | Is repository integration complete? | PRs #9–#12 are merged into `main`. Local synchronization remains unverified. |
| OQ-08 | Is synthetic runner CI part of project acceptance? | No. Retired on 2026-11-06 because it tested synthetic fixtures rather than the actual OULAD workload. |
| OQ-09 | Is the local working tree synchronized? | Not verified by this repository inspection. |

### Current repository and CI state

- PRs #9–#12 are closed as merged into `main`; their merge commits are recorded above.
- PR #13 (`AN5: extend engagement sensitivity to five queries`) is open as Draft from `work/an5-five-query-execution` into `main`; head `574d437f48527a8c5aae218bf73ba63be41027ce`. It contains 12 changed files and is not merged.
- The current `main` tree contains the WO-2 SQL bundle, saved WO-2 notebook, documentation updates, and the initial AN5 design/three-query preparation. The five-query AN5 extension is on `work/an5-five-query-execution` under Draft PR #13; it is not merged.
- No file remains under `.github/workflows/`; the synthetic runner test files and their README were removed. No `tests/` directory remains in the current tree.
- The repository-level GitHub Actions feature has not been disabled because the available integration does not expose an Actions-settings write operation. No workflow definition remains to trigger in the current repository tree.
- Run #42140281401 attempt 2 remained `in_progress` at the last verified check. The available integration does not expose a cancellation action. No retry was requested. This run is not a project acceptance gate.
- The merged source branches remain as historical refs; branch deletion was not available through the connected GitHub operations. No branch was deleted.
- Local synchronization and working-tree status have not been verified by this repository-only session.

### Next work order

**AN5 — Engagement Sensitivity.** Five canonical read-only SQL files, `scripts/run_an5.py`, and a direct-cell orchestration notebook are prepared on `work/an5-five-query-execution`. They have not been executed against the local OULAD database. After PR integration and local synchronization, execute sequentially after a successful read-only preflight. Preserve RAW/STAGING; do not create persistent objects. The notebook follows WO-1's no-prompt execution style but must be run cell by cell, not with Run All.


## 2026-10-31 — Repository synchronization and maintenance

The project owner confirmed the current repository synchronization state after PR #7. The verified main commit is `87fd73b467a1d3dd64f43c2a89ec8f47261e5c75`; the local `main` and `origin/main` were reported aligned with a clean working tree. PR #7 was squash-merged and corrected only the introductory reconciliation status and a stale explanatory notebook cell; it did not rerun SQL or modify the database, RAW, QUALITY, or STAGING layers.

The owner also confirmed removal of the temporary work/documentation branches while retaining the two safety backups:
- Local: `backup/local-main-before-sync-2026-10-31` at `62fb8dd`.
- Remote: `backup/pre-wo1-documentation-2026-10-30` at `7e28dbb`.

These backups are intentionally retained. No backup branch is to be deleted as part of routine synchronization.

**Current analytical routing:** WO-2 remains one bounded package in the sequence AN0.07 → AN1.10 → AN2.10 → AN3 → AN4. AN0.07, AN1.10, and AN2.10 are not marked executed by this repository maintenance. AN5 remains a separate dependency-gated stage.

**Repository maintenance:** A focused consistency update is being prepared on `docs/ops-repository-consistency-2026-10-31`. Its scope is limited to the analysis-log handover, this ledger, architecture wording, and the `student_vle` grain caveat in the data dictionary. No SQL, notebook execution, database object, RAW/STAGING data, dependency manifest, or roadmap architecture is changed.

## 2026-11-02 — WO-2 execution foundation preparation

### Repository state and provenance

The project owner reported that local `main` was synchronized with `origin/main` at `51643e63b7c2c6f1398215be965ce4fe61bd6333`, `git diff --quiet` returned 0, and the working tree was clean. This is owner-reported evidence, not a local Git command executed by this update. No reset, rebase, or repeat synchronization was performed.

Changes are being prepared on `work/wo2-execution-foundation`, created from the reported main commit. The branch is not merged into `main`.

### Roadmap status

| Workstream | Status | Evidence / boundary |
|---|---|---|
| WO-1 / `notebooks/04_sql_analytics.ipynb` | Historical evidence retained | Not modified or repurposed. |
| WO-2 runner | Implementation prepared | `src/analytics/db.py` now exposes all result sets and preserves legacy first-result keys; local execution tests remain pending. |
| WO-2 synthetic tests | Authored, not executed | `tests/test_analytics_db_runner.py`; no test pass is claimed. |
| WO-2 SQL bundle | Review pending | External archive review does not establish repository integration. |
| WO2-A through WO2-E notebooks | Planned grouping | Final paths require inventory review; no execution notebooks or live outputs are claimed here. |
| WO2-F | Documentation closeout | No separate notebook planned. |
| AN5 | Dependency-gated | Remains separate; no RAW/STAGING deduplication or aggregation. |

### Executed query IDs

No WO-2 query IDs were executed as part of this update. Historical WO-1 execution evidence remains unchanged and is not relabelled as new execution.

### Files changed or prepared on the work branch

- `src/analytics/db.py` — backward-compatible multi-result execution path using Psycopg simple-query mode and `nextset()`.
- `tests/test_analytics_db_runner.py` — synthetic test cases authored; execution not yet verified.
- `sql/04_analytics/README.md` — clarified canonical SQL ownership, WO-1 evidence status, and WO-2 preparation boundary.
- `notebooks/README.md` — documented the grouped WO-2 notebook architecture and preserved the WO-1 notebook.
- `docs/analysis_log.md` — recorded technical decisions and explicitly marked unexecuted work.
- `docs/analysis_progress_ledger.md` — updated roadmap and evidence status.

### Decisions and controls

- SQL files remain the canonical query definitions; notebooks orchestrate and interpret.
- The existing WO-1 notebook remains unchanged.
- Multi-result SQL is not split on semicolons.
- Legacy result keys refer to the first result set; `result_sets` carries all result sets.
- `elapsed_seconds` is a total batch duration. Per-statement server timings are not represented as measured values.
- Preserve read-only connection mode, statement timeout, lock timeout, rollback, and connection closure.
- AN3.06 is a high-runtime query and must run alone.
- Execute AN4.06 before AN4.03; do not pre-exclude banked submissions.
- Do not modify RAW/STAGING, create indexes or constraints, or claim WO-2 findings before actual database execution.

### Repository actions

Created branch `work/wo2-execution-foundation` from `51643e63b7c2c6f1398215be965ce4fe61bd6333`. Changes are not merged. No PR merge, local machine modification, or database operation is claimed.

### Next work order

1. Run the synthetic test module in the local project environment and fix any failures.
2. Review the complete 21-file SQL bundle against the WO-2 plan and the corrected review notes; integrate SQL only after file-level approval.
3. Inspect the current notebook inventory and then create grouped WO2-A–WO2-E notebooks with Markdown rationale before each code cell.
4. Complete review and closeout documentation (WO2-F).
5. Only after local runner and SQL validation, begin AN0.07 and continue in the approved dependency-aware order. No live WO-2 query is authorized by this preparation record alone.


## 2026-11-02 — WO-2 SQL and notebook preparation

### Roadmap status

| Workstream | Status | Evidence / boundary |
|---|---|---|
| WO-1 / `notebooks/04_sql_analytics.ipynb` | Historical evidence retained | Preserved; not modified or re-executed. |
| WO-2 SQL AN0.07, AN1.10, AN2.10, AN3.01–AN3.08, AN4.01–AN4.10 | Prepared; static review applied | 21 canonical SQL files added on the preparation branch. No live database execution is claimed. |
| WO-2 runner | Existing multi-result implementation retained | `src/analytics/db.py` already supports Psycopg simple-query batches, `nextset()`, per-result display caps, and legacy first-result aliases. |
| Synthetic runner tests | Authored; execution not verified here | Existing `tests/test_analytics_db_runner.py`; no passing test run is claimed. |
| WO-2 notebook | Prepared | One notebook, `notebooks/05_wo2_analytical_investigation.ipynb`; live-execution flag defaults to False and review gates are explicit. |
| WO2-F | Pending actual evidence | Documentation closeout follows returned PostgreSQL outputs; no results are fabricated. |
| AN5–AN11 | Not started / dependency-gated | No activity metric, KPI, mart, Power BI, or predictive model is approved. |

### Executed query IDs

**None.** No WO-2 query was executed against `oulad_analytics` during this preparation. No test execution is claimed.

### Static review corrections

- AN3.03: the after-course-end condition precedes the in-course week buckets.
- AN3.06: registration is LEFT JOINed; `NO_REGISTRATION_MATCH` is distinct from matched registration with NULL `date_unregistration`.
- AN4.08: the distinct count is at student-presentation grain.
- AN4.10: removed `zero_weight_rows` exactly as requested; no change to the submitted-weight aggregation, banked-status groups, or coverage shares.
- Historical and directional expectations in selected AN3/AN4 queries are framed as hypotheses or reconciliation references rather than acceptance criteria.

### Files added or updated on the preparation branch

- Added 21 canonical SQL files under `sql/04_analytics/`.
- Added `notebooks/05_wo2_analytical_investigation.ipynb`.
- Updated `sql/04_analytics/README.md` with the full query inventory and static correction notes.
- Updated `notebooks/README.md` to specify one WO-2 notebook and preserve the existing notebook inventory.
- Updated `docs/analysis_progress_ledger.md` and `docs/analysis_log.md` with preparation status and approved technical decisions.
- `src/analytics/db.py`, its synthetic tests, `notebooks/04_sql_analytics.ipynb`, `docs/analytical_work_order_plan.md`, and `docs/data_dictionary.md` were not modified in this change set.

### Decisions and constraints

- Canonical SQL remains the sole source of query logic; the notebook orchestrates and interprets.
- One notebook is used for all WO-2 work, as approved by the project owner.
- The notebook's live-execution gate defaults to disabled; explicit authorization is required before live queries.
- AN3.06 is executed alone with a 600,000 ms runner timeout; no SQL `SET` statement is added.
- AN4.06 must be reviewed before AN4.03; banked status remains a dimension, not an exclusion rule.
- AN4.10 coverage shares remain calculated among student-presentations with the relevant status; the full student-presentation denominator is shown separately for context.
- RAW/STAGING are unchanged; no indexes, constraints, views, marts, or other persistent database objects are created.

### Repository actions

Changes are prepared on `work/wo2-pre-execution-readiness`, based on commit `aacf56fc3ae7698a7f951e1ac469b9fb2e038140`. The branch is not merged. A draft integration PR is to be opened for review; no merge is authorized.

### Next work order

1. Review the preparation diff and the exact SQL corrections.
2. Run the synthetic unit-test suite in the user's local environment and return the actual result.
3. After separate explicit approval, run AN0.07 and inspect all three result sets before deciding whether AN1.10 can proceed.
4. Continue through WO2-A–WO2-E only at the defined review gates.


## 2026-11-02 — Runner validation hardening

The project owner requested a clear separation between synthetic runner tests, isolated PostgreSQL integration tests, and the later live WO-2 investigation. The existing mocked unit tests do not connect to PostgreSQL and cannot alone validate Psycopg's actual multi-result behavior.

To address this without accessing the user's local database, an isolated integration test and GitHub Actions workflow were added on the existing `work/wo2-pre-execution-readiness` branch. The workflow provisions a disposable PostgreSQL 18 service named `oulad_runner_test`, installs the repository-pinned Psycopg 3.3.6 and required runtime dependencies, then runs the unit and integration tests. The integration test issues three SELECT statements, verifies all result sets and their order, checks `transaction_read_only = on`, and asserts the database name is exactly `oulad_runner_test`. It contains no DDL or DML.

The runner comments were corrected to avoid claiming that `prepare=False` alone selects the simple-query protocol. The documented Psycopg contract supports multiple statements without parameters and exposes subsequent results through `nextset()`; the isolated integration test is the empirical gate for the pinned version.

**Validation status:** workflow and integration test have been authored but have not yet run. No CI pass is claimed. No user database connection was opened and no OULAD data was read or changed. The live execution gate remains separate and requires the user's explicit approval.


## 2026-11-05 — WO-2 notebook structure correction

### Roadmap status

| Workstream | Status | Evidence / boundary |
|---|---|---|
| WO-1 notebook | Preserved | `notebooks/04_sql_analytics.ipynb` was inspected as the structural reference and was not modified. |
| WO-2 notebook | Rebuilt; repository write verified | `notebooks/05_wo2_analytical_investigation.ipynb` now follows the WO-1-style setup → readiness checks → database preflight → query → interpretation/review sequence. |
| WO-2 SQL | Existing canonical files retained | The 21 SQL definitions were not changed by this notebook correction. |
| Live WO-2 execution | Not verified in this work order | No AN0.07–AN4.10 query was executed by this documentation change. |
| Database state | Not inspected or modified | No connection to the user's local `oulad_analytics` database was opened by this repository edit. |

### Notebook corrections

- Replaced the single oversized setup cell with separate repository/import, environment-readiness, database-preflight, execution-helper, and helper-validation cells.
- Added a fresh AN0.01 preflight that displays database identity, PostgreSQL version, read-only settings, statement timeout, and lock timeout. The notebook stops if the database is not `oulad_analytics` or either read-only setting is not `on`.
- Added an explicit live-execution authorization cell. The switch remains `False` by default and must be deliberately changed after the successful preflight.
- Preserved one canonical SQL source per query and the existing shared runner.
- Added expected result-set-count checks for all 21 WO-2 query IDs; AN0.07, AN1.10, and AN2.10 expect three result sets, AN4.05 expects two, and the remaining queries expect one.
- Added a current AN1.01 student-presentation key refresh as an explicit dependency before AN1.10; this is a dependency check, not an additional WO-2 query.
- Added per-query Question, Expectation, Grain, Source, Safety, Runtime, and Read as context, followed by interpretation and manual review checkpoints.
- Preserved AN3.06 as a standalone high-runtime query with a 600,000 ms timeout, AN4.06 before AN4.03, and AN4.10 without `zero_weight_rows`.
- Added stable notebook cell IDs. The 04 notebook and canonical SQL files were not modified.

### CI warning and execution evidence

The earlier PR workflow run `41541198803` installed dependencies successfully, but its test step was cancelled after the hosted runner received a shutdown signal. The log also contains a Node.js 20 deprecation warning from GitHub Actions. The available log does not establish a Python assertion failure or a notebook execution failure. A later push workflow run `41940696084` was in progress at the time of this ledger update; its outcome is not claimed.

No separate warning output from the user's local Jupyter kernel is stored in the repository snapshot. Any local-only warning not present in the saved notebook or Actions log remains unverified.

### Files changed

- Updated `notebooks/05_wo2_analytical_investigation.ipynb`.
- This ledger entry records the verified repository change.
- `notebooks/04_sql_analytics.ipynb`, `src/analytics/db.py`, the 21 canonical SQL files, and RAW/STAGING data were not changed in this correction.

### Executed query IDs

**None in this repository correction.** AN0.01 is now the notebook's first local database preflight, but it has not been executed by this change.

### Next work order

1. Pull or sync the updated notebook from `work/wo2-pre-execution-readiness` into the user's local working copy without overwriting unrelated local work.
2. Restart the Jupyter kernel and run the environment cells individually.
3. Run the AN0.01 preflight and verify the displayed database identity and read-only settings.
4. Only after that succeeds, deliberately enable the live-execution switch and begin AN0.07.
5. Review all three AN0.07 result sets before the current AN1.01 key refresh and AN1.10.

## 2026-11-05 — First local WO-2 execution attempt and AN0.07 correction

### Verified local evidence reported by the project owner

- The local notebook located the project root and canonical SQL folder, imported the shared runner, and passed environment validation.
- AN0.01 executed against `oulad_analytics` and returned one row. The reported PostgreSQL version was 18.6; both `transaction_read_only` and `default_transaction_read_only` were `on`; statement timeout was 2 minutes and lock timeout was 5 seconds.
- The notebook's execution helper validation passed and the preflight gate was marked verified.
- The owner explicitly authorized live WO-2 execution. The notebook authorization switch was enabled locally; this local state is not independently inspectable from the repository.
- AN0.07 was attempted but failed before returning result sets with PostgreSQL `DatatypeMismatch`: JOIN/USING types `character` and internal `"char"` cannot be matched. No AN0.07 output is accepted as evidence, and no AN1.10 execution is authorized by this failed attempt.

### Root cause and correction

The mismatch was in AN0.07 statement 2: the CTE supplied `CHAR` values while `pg_constraint.contype` is PostgreSQL's internal `"char"` type. The join using `constraint_type` therefore compared incompatible types. The canonical SQL was corrected to cast both sides to `TEXT`:
- constraint type literals now use `'p'::TEXT`, `'u'::TEXT`, `'f'::TEXT`, and `'c'::TEXT`;
- `con.contype` is selected as `con.contype::TEXT`.

The correction was committed to `work/wo2-pre-execution-readiness` in commit `0f948ba18d4f6489f0440260bd2fa2a35faa5821`. The updated file was fetched back and the corrected casts were verified in the repository. This is a source-level correction only; it has not yet been executed against PostgreSQL.

### Execution status and next action

- Executed WO-2 query IDs with returned results: **none**.
- AN0.01 is a successful local preflight, not a WO-2 analytical query.
- AN0.07: failed attempt; corrected SQL committed; rerun pending.
- AN1.10 and all later WO-2 queries: not run.
- No RAW/STAGING data or database objects were changed.

Next: synchronize the corrected AN0.07 SQL file into the local working copy, verify that the local file matches the branch version, then rerun only AN0.07. Inspect all three result sets and their row counts, truncation flags, runtime, and semantics before proceeding to AN1.01 refresh / AN1.10. Do not rerun AN0.01 unless the connection/kernel state has changed.

## 2026-11-05 — AN0.07 local execution evidence and review-gate correction

### Verified AN0.01 preflight

The project owner returned a fresh local AN0.01 output from `oulad_analytics` on PostgreSQL 18.6. The session reported `transaction_read_only = on`, `default_transaction_read_only = on`, `statement_timeout = 2min`, and `lock_timeout = 5s`. Environment validation and the shared runner import passed. This verifies the reported local read-only session at that time; it does not establish future connection state after a kernel restart or environment change.

### AN0.07 execution — user-returned output

The corrected canonical SQL executed locally and returned all three expected result sets in 0.191 seconds. The display cap was 500 rows per result set; no result set was truncated.

| Result set | Returned rows | Verified observation |
|---|---:|---|
| 1 — RAW primary-key inventory | 7 | Six documented primary keys returned `MATCH` and `is_validated = True`; `student_vle` returned `EXPECTED_NO_PK`. |
| 2 — Constraint-type counts | 4 | `p = 6`; `u = 0`; `f = 0`; `c = 0`. |
| 3 — Index inventory for `raw.student_vle` | 0 | No index rows were returned for this table in the RAW schema. |

**Interpretation:** the six expected RAW primary keys are present and validated. The expected absence of a primary key on `student_vle` is confirmed. No indexes were found on `raw.student_vle` by this catalog query. The empty index inventory is a metadata finding, not proof of row uniqueness or a reason to create an index. No index or other persistent database object was created.

The project lead reviewed the three user-returned result sets in this conversation and accepted the AN0.07 findings. The local notebook checkpoint output showed `AN0.07 reviewed: False`; this is a closed manual-review flag, not an SQL execution failure. The user had not recorded the required `REVIEWED` input in that local checkpoint. No AN1.01 refresh or AN1.10 query was executed as part of this result.

### SQL correction and static cross-query review

The AN0.07 failure was traced to a JOIN/USING comparison between PostgreSQL internal `"char"` (`pg_constraint.contype`) and SQL `character` literals. Both sides were cast to `TEXT`. The corrected SQL was committed to `work/wo2-pre-execution-readiness` in commit `0f948ba18d4f6489f0440260bd2fa2a35faa5821`; the user subsequently returned successful execution output from that corrected file.

A static scan of all 21 WO-2 SQL files found no other explicit `::CHAR` or internal `"char"` casts. Remaining `USING` joins occur in AN1.10, AN3.03, AN3.06, and AN4.10 on shared key columns; this static inspection is not a substitute for live execution of those queries.

### Notebook execution-flow correction

The notebook was updated on the same preparation branch to make expected workflow gates non-exceptional:

- A dependent query attempted before its review gate opens now prints `NOT EXECUTED`, identifies the missing approval, and returns without sending SQL to PostgreSQL or raising a traceback.
- A review checkpoint with missing, truncated, stale, or incomplete outputs now prints `REVIEW BLOCKED` and returns `False`; it does not raise a traceback for a normal closed gate.
- The checkpoint prompt explicitly requires the project lead's approval before the user enters `REVIEWED`.
- AN1.01's direct dependency refresh now checks the live-authorization and AN0.01 preflight flags as well as AN0.07 review. A closed gate returns without opening a database connection.
- Re-running an upstream query invalidates its own review flag and all downstream approvals/results.
- Reinitializing the execution helper retains the AN0.01 preflight output but clears prior WO-2 outputs and resets review flags, preventing stale in-memory results from opening gates.
- Genuine SQL/database exceptions and unexpected result-set counts remain visible and are not suppressed.

The notebook update was committed in `a9871f6aa1fd9c253cb42f66192c949672fbb969`, followed by a small safety refinement that clears stale WO-2 outputs on helper reinitialization in commit `c341ff78f93c880fdc30ac8b8535eab17427b20b`. The notebook still contains 92 cells. The new helper and AN1.01 refresh code cells passed Python AST parsing; this is a syntax check, not a local Jupyter execution test.

### Current execution status

- AN0.01 fresh local preflight: **executed; user-returned output verified**.
- AN0.07: **executed; three result sets returned; reviewed and accepted in conversation**. The local notebook review flag has not yet been recorded in the corrected notebook.
- AN1.01 current dependency refresh: **not yet executed**.
- AN1.10, AN2.10, AN3.01–AN3.08, AN4.01–AN4.10: **not executed in WO-2**.
- No RAW, QUALITY, or STAGING data was modified. No persistent database objects were created.

### Next work order

1. Synchronize the corrected notebook and canonical AN0.07 SQL file from `work/wo2-pre-execution-readiness` to the local project. Preserve a backup of the current local notebook first if it contains unsaved execution outputs.
2. Restart the Jupyter kernel and run the setup, environment, AN0.01 preflight, helper, and authorization cells individually. A fresh preflight is required for the new kernel session.
3. Execute AN0.07 once in the updated notebook so the result is stored with the current SQL hash; send the three outputs for confirmation. The query reads catalog metadata only and previously completed in 0.191 seconds.
4. After the project lead confirms the output, run the AN0.07 review checkpoint and type `REVIEWED`.
5. Run the AN1.01 dependency refresh cell. Proceed to AN1.10 only if it returns PASS; then submit all three AN1.10 result sets for review.

The requested concise interpretation/commentary cells for each query will be added after WO-2 execution results are complete and reviewed, using actual returned outputs rather than generic or speculative annotations.

### Post-edit validation of the notebook controls

The updated helper and AN1.01 refresh cells passed Python AST parsing. A small isolated control-flow check confirmed that (a) a query attempted with live authorization disabled returns `None` without calling the database runner, (b) a review checkpoint with missing output returns `False` without a traceback, and (c) AN1.01 returns without calling the runner while the AN0.07 review gate is closed. These are isolated logic checks, not a full Jupyter execution or a live PostgreSQL test.

The six updated repository files were fetched back from `work/wo2-pre-execution-readiness` after commit. The notebook contains 92 cells (34 code cells); the corrected AN0.07 SQL and all documentation updates are present. No merge to `main` was performed.


## 2026-11-06 — WO-2 execution completed; interpretation reviewed

### Roadmap status

| Workstream | Status | Evidence / boundary |
|---|---|---|
| AN0.01 preflight | Executed in saved notebook | `oulad_analytics`, PostgreSQL 18.6; both read-only settings on; 2-minute statement timeout and 5-second lock timeout. Saved output only; not rerun during this review. |
| AN0.07 | Executed; checkpoint True | 3 result sets (7, 4, 0); six expected RAW primary keys match; `student_vle` has expected no PK; no RAW student_vle index rows. |
| AN1.01 dependency refresh | Executed; PASS | Two expected tables, 32,593 rows each; zero NULL key rows, duplicate groups, or excess rows. Not one of the 21 WO-2 query IDs. |
| AN1.10 | Executed; checkpoint True | 3 result sets (5, 22, 1); 33,407-row naive-join excess fully reconciled; correct path 173,912 rows and zero unmatched. |
| AN2.10 | Executed; checkpoint True | 3 result sets (7, 95, 1); 1,111 missing IMD rows across 971 students; no alternative value in the tested comparison. |
| AN3.01–AN3.08 / WO2-C | Executed; WO2-C checkpoint True | Eight queries; 76-row AN3.06 output; descriptive withdrawal, registration, and activity findings with denominator and causality caveats. |
| AN4.01, AN4.02, AN4.04, AN4.05 / WO2-D | Executed; WO2-D checkpoint True | Four queries; AN4.05 returns 2 result sets. AN4.02's 11 no-due-date exams include 2,865 submission rows across three exams. |
| AN4.06 | Executed; checkpoint True | 5 rows; banked and non-banked profiles retained. |
| AN4.03, AN4.07–AN4.10 | Executed; result-count checks passed | Seven queries; AN4.03 correctly followed AN4.06 review. No separate human review checkpoint is recorded for each of AN4.07–AN4.10. |
| AN5–AN11 | Not started | AN5 design is next; no engagement metric or R0/R1/R2 sensitivity result is approved. |

### Saved notebook integrity

Reviewed GitHub branch `work/wo2-pre-execution-readiness`, file `notebooks/05_wo2_analytical_investigation.ipynb`, saved blob SHA `e94a9d40876fa638718a12152f572ef1562e55d8`.

- 92 total cells; 34 code cells; 34 executed; 0 unexecuted.
- 0 saved error/traceback outputs.
- 21 WO-2 queries; 28 result sets; 857 displayed rows.
- Sum of saved query batch runtimes: 10.099 seconds.
- All expected result-set-count checks passed; no runner row-cap truncation.
- AN0.01 preflight and AN1.01 dependency refresh are additional to the 21 WO-2 queries.
- Saved notebook evidence was inspected; no live database connection or query rerun was performed during this review.

### Query execution register

| Query | Result sets | Displayed rows | Seconds |
|---|---:|---:|---:|
| AN0.07 | 3 | 11 | 0.159 |
| AN1.10 | 3 | 28 | 0.718 |
| AN2.10 | 3 | 103 | 0.079 |
| AN3.01 | 1 | 6 | 0.046 |
| AN3.02 | 1 | 15 | 0.058 |
| AN3.03 | 1 | 111 | 0.031 |
| AN3.04 | 1 | 6 | 0.039 |
| AN3.05 | 1 | 4 | 0.061 |
| AN3.06 | 1 | 76 | 4.898 |
| AN3.07 | 1 | 36 | 0.086 |
| AN3.08 | 1 | 22 | 0.044 |
| AN4.01 | 1 | 57 | 0.014 |
| AN4.02 | 1 | 11 | 0.032 |
| AN4.04 | 1 | 3 | 0.035 |
| AN4.05 | 2 | 83 | 0.333 |
| AN4.06 | 1 | 5 | 0.408 |
| AN4.03 | 1 | 17 | 0.141 |
| AN4.07 | 1 | 27 | 0.197 |
| AN4.08 | 1 | 20 | 1.391 |
| AN4.09 | 1 | 178 | 0.411 |
| AN4.10 | 1 | 38 | 0.918 |
| **Total** | **28** | **857** | **10.099** |

### Validated observations and caveats

- AN0.07: six documented RAW primary keys match; `student_vle` has no primary key as expected; the catalog query returned no index rows for `raw.student_vle`. Do not infer uniqueness or create an index from this result.
- AN1.10: the naive `id_student`-only join produces 207,319 rows versus 173,912 source rows. The 33,407 excess rows reconcile exactly to students appearing in multiple presentations. The metadata-aware path returns 173,912 rows with zero unmatched rows.
- AN2.10: 1,111 missing IMD rows represent 971 distinct students; all are classified `NO_ALTERNATIVE_VALUE`. No automatic imputation.
- AN3.01–AN3.05: 10,156 Withdrawn rows comprise 10,063 with an unregistration date and 93 without. Nine Fail rows have an unregistration date. AN3.02 exposes nine non-withdrawn/date conflicts. AN3.05 categories reconcile to 32,593 student-presentations. AN3.04's 86.67% rate is based on only 45 rows (39 withdrawn).
- AN3.06: activity absence and timing are descriptive recorded-row findings, not proof of no learning or causal withdrawal. Registration mismatch, missing unregistration date, and no recorded activity remain distinct categories.
- AN3.07: `small_category_flag` checks category totals, not individual outcome-cell counts. Individual cells can still be below 100 (including a cell with two rows); the SQL comment and flag semantics should be aligned before reuse.
- AN3.08: withdrawal proportions range from 6.93% (GGG 2013J) to 46.38% (CCC 2014B), descriptive only.
- AN4.02 correction: all 11 no-due-date assessments are Exam, but three have submission records totalling 2,865 rows; eight have none. AN4.04 returns the three submission-bearing assessment groups.
- AN4.05/AN4.06: 173 NULL scores, 329 zero scores, zero out-of-range scores; 173,739 scored rows out of 173,912. Banked `date_submitted = -1` is a sentinel, not a calendar date.
- AN4.07/AN4.08: outcome and score groupings are retrospective; do not use final outcome/score to predict the same outcome. Small cells need caution.
- AN4.09: timing categories do not prove acceptance or validity of a submission after unregistration.
- AN4.10: coverage averages use the student-presentations with the relevant banked status; the full cohort count is displayed separately. A student can appear in both status groups. The GGG 0.000 coverage pattern is consistent with zero-weight CMA/TMA and a 100-weight Exam in the assessment structure, but does not prove absence of learning activity. No final weighted-score definition is approved.

### Decisions

- WO-2's 21-query execution is complete in the saved notebook.
- Interpretations are descriptive and bounded by the saved execution; this review did not rerun PostgreSQL.
- No KPI, causal finding, final weighted score, predictive feature set, or business rule is approved.
- RAW, QUALITY, and STAGING remain unchanged; no persistent database objects were created.
- The `student_vle` repetition problem remains open. Preserve all 10,655,280 rows and do not deduplicate or aggregate source data.

### Open questions / next work order

1. Define the AN5 engagement metric, grain, time window, denominator, and treatment of negative relative dates and missing matches.
2. Specify R0 (all rows), R1 (exact six-column duplicate exclusion for metric calculation only), and R2 (maximum `sum_click` per five-column key group) as sensitivity alternatives, not data-cleaning rules.
3. Quantify metric and denominator changes under each alternative; preserve the raw/staging source unchanged.
4. Reconcile AN3.07's small-cell wording with its implemented flag before reusing the flag as an automated warning.
5. Keep AN5–AN11, KPIs, marts, Power BI, and predictive modelling dependency-gated.

### Repository and database actions

- Updated only `docs/analysis_log.md` and `docs/analysis_progress_ledger.md` on `work/wo2-pre-execution-readiness` to record this review.
- No notebook, canonical SQL, Python source, RAW/STAGING data, or database objects were changed by this documentation update.
- No merge to `main`, PR retargeting/closure, branch deletion, or database modification was performed.

# OULAD Analysis — Progress Ledger

Updated: 2026-11-02

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

## Roadmap status

| Analytical ID | Status | Evidence / note |
|---|---|---|
| AN0 — Analytical readiness | WO-1 scope completed; AN0.07 open | AN0.01–AN0.04 saved execution evidence reviewed. AN0.07 RAW key verification remains a follow-up check; execution is not established by the reviewed evidence. |
| AN1 — Grain, keys, and join integrity | WO-1 scope completed; AN1.10 open | AN1.01–AN1.09 evidence reviewed. Student-presentation keys passed the tested checks; assessment join fan-out was quantified. AN1.10 remains an investigation of the observed 33,407-row increase; execution is not established by the reviewed evidence. |
| AN2 — Student and presentation profile | WO-1 descriptive scope completed; AN2.10 open | AN2.01–AN2.09 evidence reviewed. Targeted AN2.02, AN2.04, and AN2.05 reconciliation passed across 132 groups. AN2.10 remains open for extended IMD missingness analysis; execution is not established by the reviewed evidence. |
| AN3 — Outcomes and withdrawal | Planned | Analyze outcome categories, registration/unregistration dates, and recorded activity absence with explicit denominators and careful interpretation. |
| AN4 — Assessment analysis | Planned | Analyze assessment grain, timing, weights, score completeness, submission coverage, and `is_banked` semantics. |
| AN5 — Engagement sensitivity | Dependency open | R0/R1/R2 remain alternative metric definitions; repeated `student_vle` candidate-key semantics are unresolved. |
| AN6 — Engagement analysis | Pending AN5 | Requires an approved activity definition and documented limitations. |
| AN7 — Outcome associations | Pending validated measures | Associations only; no causal interpretation is implied. |
| AN8 — Predictive readiness | Future gate | Requires a leakage-safe readiness assessment; it does not automatically authorize model development. |
| AN9 — Validated KPIs and analytical marts | Future | Requires approved definitions, grains, denominators, and validation tests. |
| AN10 — Power BI | Future | Depends on curated reporting outputs and validated KPIs. |
| AN11 — Final analytical report | Future | Depends on completed analytical validation and reporting evidence. |

## Executed analytical queries and retained evidence

| Analytical ID | Artifact | Safety | Evidence / key result |
|---|---|---|---|
| AN0.01–AN0.04 | `sql/04_analytics/AN0.*.sql`, notebook | READ-ONLY | Saved notebook outputs: database `oulad_analytics`, PostgreSQL 18.6, read-only settings; registry 29 rows (25 PASS, 4 REVIEW, 0 FAIL); all seven STAGING row counts match the historical baseline; relation/index inventory inspected. |
| AN1.01 | `sql/04_analytics/AN1.01_student_key_uniqueness.sql` | READ-ONLY | User-returned output: `student_info` and `student_registration` each 32,593 rows, 0 null keys, 32,593 distinct composite keys, 0 duplicate groups, gate PASS. |
| AN1.02–AN1.09 | Canonical SQL and saved notebook | READ-ONLY | Saved execution outputs reviewed. Key-set reconciliation and assessment join fan-out are documented; metadata and activity relationships remain descriptive and retain caveats. |
| AN2.01–AN2.09 | Canonical SQL and saved notebook | READ-ONLY | Saved execution outputs reviewed; counts, profiles, and missingness by presentation recorded. |
| AN2.02 reconciliation | Notebook reconciliation cell | READ-ONLY | 22/22 module-presentation groups: counts and rounded percentages reconcile; 0/22 explicit `<NULL>` categories; 0.078 s. |
| AN2.04 reconciliation | Notebook reconciliation cell | READ-ONLY | 66/66 presentation-dimension groups: counts and rounded percentages reconcile; 0/66 explicit `<NULL>` categories; 0.082 s. |
| AN2.05 reconciliation | Notebook reconciliation cell | READ-ONLY | 44/44 presentation-dimension groups: counts and rounded percentages reconcile; 0/44 explicit `<NULL>` categories; 0.061 s. |

Combined targeted reconciliation: 132/132 count groups passed, 132/132 rounded-percentage groups passed, one denominator per group, and 0/132 explicit `<NULL>` output categories. This does not establish source-wide absence of SQL NULL values.

## Decisions

| ID | Decision | Reason / evidence |
|---|---|---|
| D-WO1-01 | Accept the executed WO-1 and WO-1B scope as analytically complete. | Saved AN0–AN2 evidence was reviewed; AN1.01 passed; all 132 targeted category groups reconciled. AN0.07, AN1.10, and AN2.10 remain separately identified follow-up questions. |
| D-WO1-02 | Retain historical registry timestamps as NULL. | Exact historical execution times were not captured; no backfill. |
| D-WO1-03 | Do not create indexes during readiness. | Catalog inspection only; no approved cost/benefit case for persistent change. |
| D-WO1-04 | Do not deduplicate or aggregate RAW/STAGING `student_vle`. | Candidate key remains non-unique and repeated groups contain different `sum_click` values. |
| D-NEXT-01 | Execute WO-2 in a dependency-aware sequence: AN0.07, AN1.10, and AN2.10 first, followed by AN3 and AN4 within the same work-order package. | The three readiness follow-ups close outstanding AN0–AN2 questions before outcome and assessment interpretation. AN3 and AN4 can then use the validated student-presentation and assessment grains; neither requires prior approval of a VLE engagement definition. |
| D-NEXT-02 | Keep AN5 as a separate dependency-gated work order. | R0/R1/R2 are alternative metric definitions; repeated-record semantics are unresolved. |

## Open questions

| ID | Question | Status | Next justified work |
|---|---|---|---|
| OQ-01 | What do repeated `student_vle` rows represent? | Open | AN5 sensitivity design and source-semantics investigation; no destructive changes. |
| OQ-02 | What do negative relative VLE dates mean? | Open | Verify OULAD time conventions and evaluate only in a defined temporal metric. |
| OQ-03 | How should missing `date_unregistration` be interpreted alongside `final_result`? | Open | AN3 outcome/withdrawal analysis with explicit outcome categories and date caveats. |
| OQ-04 | What explains missing assessment dates, and how do they relate to submissions? | Open | AN4 assessment metadata/submission analysis. |
| OQ-05 | Why are 173 assessment scores missing and how do they relate to `is_banked`? | Open | AN4 score completeness and banked-submission analysis. |
| OQ-06 | What is the meaning and denominator treatment of `is_banked`? | Open | AN4, using source documentation and observed distributions. |
| OQ-07 | How do assessment weights behave by presentation and type? | Open | AN4 weight/timing analysis; do not assume weights sum to 100. |
| OQ-08 | What explains IMD missingness? | Open | Carry descriptive patterns forward; do not infer missingness mechanism or causation. |
| OQ-09 | What source reference establishes valid categorical values? | Open | Documentation/source provenance review when a domain decision is needed. |

## Files changed on the working branch

| File | Status | Change |
|---|---|---|
| `docs/analysis_log.md` | Updated | Added 30 October reconciliation evidence, decision, limitations, and next-stage routing. |
| `docs/analytical_readiness_work_order.md` | Updated | WO-1 scope, accepted evidence, and follow-up boundary recorded. |
| `docs/analytical_work_order_plan.md` | Updated | WO-1B reconciliation and exit criteria recorded. |
| `README.md` | Updated | Current status reflects completed WO-1 scope and remaining analytical questions. |
| `docs/analysis_progress_ledger.md` | Created, then refreshed | Records query evidence, decisions, repository integration, and next work. |
| `docs/repository_snapshot_2026-10-30.md` | Created, then extended | Preserves the pre-update snapshot and records later repository state. |
| `notebooks/04_sql_analytics.ipynb` | Updated and synchronized | Executed reconciliation cells and saved outputs were committed as `fab3a99` and included in PR #2. |

## Publication backlog

| Topic | Evidence ready? | Visual made? | Published? |
|---|---|---|---|
| WO-1 key and join validation | Yes, subject to output selection | Not verified | Not verified |
| Category reconciliation (AN2.02/04/05) | Yes | Not verified | Not verified |
| Outcomes/assessment findings | No | No | No |

## Next Work Order

| Planned ID | Purpose | Dependency |
|---|---|---|
| WO-2 / AN0.07 | Verify documented RAW key expectations against existing source structures. | Read-only inspection; no RAW/STAGING modifications. |
| WO-2 / AN1.10 | Investigate the observed 33,407-row increase in the assessment join path and isolate its cause. | Reinspect grain and join cardinality; cause remains unproven. |
| WO-2 / AN2.10 | Extend the descriptive analysis of IMD missingness, including presentation and region patterns. | Preserve denominators; do not infer missingness mechanism or causation. |
| WO-2 / AN3 | Analyze final outcomes, registration status, and withdrawal patterns with explicit denominators and date semantics. | Use validated student-presentation keys. |
| WO-2 / AN4 | Analyze assessment structure, dates, weights, submission coverage, scores, and banked submissions. | Use validated assessment metadata join. |
| Later AN5 | Compare R0/R1/R2 activity definitions and document sensitivity. | Define the engagement question first; investigate repeated-key semantics without modifying RAW/STAGING. |

## Repository actions

| Action | Branch / PR | Verified outcome |
|---|---|---|
| Created pre-documentation safety branch | `backup/pre-wo1-documentation-2026-10-30` | Created from the working branch at `7e28dbbc390da99f80eb0ee755b7da39fc0854d5`, preserving the pre-documentation state. |
| Saved executed analytical notebook | `work/wo1-reconciliation-cells` | Commit `fab3a99b5223940443ae9e5f10edea893cb301ce`; local and remote branch heads were previously verified identical by the project owner. |
| Pull request #1 | `work/wo-1-analytical-readiness` → `main` | Merged on 2026-10-29; merge commit `0201b758f966ff514f8c187aa462c1b22330cb83`. |
| Pull request #2 | `work/wo1-reconciliation-cells` → `main` | Squash-merged on 2026-10-30; merge commit `91d3369b41e7cfb39c0d58f87ef6f105291c1107`. |
| Documentation consistency updates | PR #3: `docs/wo1-documentation-consistency-2026-10-30` → `main` | Squash-merged on 2026-10-30; merge commit `2d78f16c0bb3097250eb6b498c68886ef0b6a90e`. |
| Notebook order and local handover correction | PR #5: `docs/wo1-local-sync-prep-2026-10-31` → `main` | Squash-merged on 2026-10-31; merge commit `d8d35857ea9ea16f8118cdc373aea004835cd0cb`. Notebook sections are now ordered AN0.01–AN0.04, AN1.01–AN1.09, then AN2.01–AN2.09, with each reconciliation beside its corresponding AN2 section. |

## Current analytical handover

The WO-1 execution evidence and targeted category reconciliations are retained in `main` through PR #2. The local notebook was saved, committed, and synchronized to the remote working branch at `fab3a99`, as previously verified by the project owner.

The WO-1 notebook evidence and documentation consistency updates have been integrated into `main` through PRs #2 and #3. PR #4 subsequently corrected the repository integration record. The local working-tree state after these merges has not yet been independently verified. PR #5 also corrected the stale handover text and sorted the WO-1 notebook sections numerically without re-executing SQL; its merge commit is recorded in the repository actions table.

WO-2 is sequenced as one bounded work-order package: first AN0.07, AN1.10, and AN2.10 to close the remaining readiness questions; then AN3 outcomes and withdrawal; then AN4 assessment analysis. This ordering keeps the remaining AN0–AN2 validation ahead of the dependent interpretation work while avoiding unnecessary re-execution of completed diagnostics. The execution status of the three follow-up checks is not established by the evidence reviewed.

AN5 remains separate because the repeated `student_vle` candidate-key semantics and the implications of R0/R1/R2 have not been resolved. AN6 depends on an approved activity definition. Power BI and predictive modelling remain downstream of validated analytical outputs.


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

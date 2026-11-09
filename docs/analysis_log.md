# Analysis Log — OULAD EdTech Learning Analytics

**Project Owner & Lead Analyst:** Abdeljalil El Khyati  
**Last updated:** 2026-11-07

This log preserves major project decisions and validated results. Exploratory one-off queries that did not result in a decision are not repeated here. Exact historical execution timestamps were not captured for the quality registry; no timestamps are reconstructed.

The historical engineering entries below retain their original dates and evidence. Earlier phase labels are preserved only where needed to explain the sequence of engineering work; they are not current analytical identifiers. The analytical roadmap is maintained exclusively through AN0–AN11. Existing query IDs and historical execution references remain unchanged.

| Date | Workstream | Question / Decision | Evidence | Result | Decision | Subsequent work recorded at the time |
|---|---|---|---|---|---|---|
| 2026-09-29 | Project setup | Should SQL and Python have separate responsibilities? | Project architecture | SQL relational work is central; Python complements it | PostgreSQL is the analytical backbone; use Python where justified | Set up PostgreSQL, Python environment, and notebooks |
| 2026-10-03 | Data ingestion | How to avoid path errors and unnecessary repeat downloads? | Notebook current working directory can differ; source archive is large | Relative-path risk and unnecessary re-extraction identified | Resolve paths from project location and skip existing files when safe | Validate source files and profiling results |
| 2026-10-04 | Engineering profiling — repeated student_vle keys | Is `(code_module, code_presentation, id_student, id_site, date)` unique in `student_vle`? | Candidate-key profiling | 10,655,280 rows; 8,459,320 distinct candidate keys; 2,195,960 excess rows | Do not impose a primary key on `raw.student_vle`; preserve rows | Characterize repeat patterns without deleting records |
| 2026-10-04 | RAW design — source types and missing tokens | Which RAW types and nullability are justified by source values? | Header, missing-token, and type profiling | Decimal assessment weights; `?` tokens in several source fields; all seven headers matched | Use `NUMERIC` for weight; keep source fields with `?` as nullable text where needed | Create RAW tables |
| 2026-10-06 | RAW schema creation | Can seven RAW tables be created while preserving source representation? | Validated Phase 2A findings | Seven tables created in `raw` | No business cleaning, aggregation, deduplication, or foreign-key transformation in RAW | Load source files |
| 2026-10-06 | RAW source loading | Did PostgreSQL `COPY` load the source tables? | `COPY` execution and row-count reconciliation | Seven source tables loaded; counts matched baseline | Accept RAW load and preserve the data as loaded | Investigate repeated `student_vle` keys |
| 2026-10-14 | Engineering validation — repeated student_vle records | What do repeated `student_vle` keys look like? | Repeated-key group, sum_click variation, full-row duplicate, and group-size queries | 1,614,505 repeated-key groups; 3,810,465 rows within those groups; 2,195,960 excess rows; max group size 10 | Repetition cause and intended grain remain unresolved; do not deduplicate or aggregate | Carry the limitation into analytical grain and metric design |
| 2026-10-14 | Engineering validation — keys and relationships | Are candidate keys and tested parent/reference relationships valid? | Candidate-key and relationship checks | Six other table keys passed; all tested parent/reference checks had zero unmatched rows | Keep the `student_vle` key at `REVIEW`; retain other tested key/reference results | Maintain a quality registry |
| 2026-10-14 | Quality registry and domain validation | Can quality findings be recorded consistently? | Registry inspection and seed execution results | Registry has 29 records and 29 distinct test codes: 25 `PASS`, 4 `REVIEW`; no duplicate codes in latest check | Keep historical `executed_at` values NULL because the exact execution times were not recorded | Use the registry for findings; do not rerun seed inserts without checking existing codes |
| 2026-10-14 | Engineering validation — completeness and values | Are missing tokens, score bounds, clicks, weights, and categorical values understood? | RAW completeness, numeric-range, categorical-distribution, and domain-validation queries | Known missingness appears as `?`; numeric checks were within the tested bounds; categorical-domain query returned no rows outside tested lists | Record missingness and observed domains; do not infer that a distribution alone proves domain compliance | Preserve interpretation caveats in the phase-closure report and data dictionary |
| 2026-10-14 | Engineering validation — temporal diagnostics | Are date-like values necessarily errors when negative or after listed dates? | Registration order, submission timing, relative VLE day, and week-range checks | No unregistration-before-registration rows; 19 same-day cases; 49,318 submissions after the listed assessment day; 688,988 negative relative VLE days; no VLE days beyond presentation length; no reversed numeric week ranges | Treat the results as diagnostics. Negative relative days, same-day cases, and later submissions are not automatic errors | Leave these questions documented for analytical interpretation |
| 2026-10-14 | STAGING conversion pre-checks | Are selected RAW values safe to convert to typed STAGING columns? | Conversion pre-check queries | No unexpected nonnumeric values in the tested conversion fields; source token and observed ranges were recorded | Convert the documented fields only in STAGING, not RAW | Create typed STAGING tables |
| 2026-10-14 | STAGING creation | Can typed STAGING tables be created without losing source rows? | Seven `CREATE TABLE AS SELECT` statements completed | Seven STAGING tables created; row counts match RAW | Keep RAW unchanged; do not assume constraints/indexes were copied into STAGING | Validate row counts, types, missingness, and ranges |
| 2026-10-14 | S1–S4 | Do selected STAGING conversions reconcile with the source and preserve tested bounds? | Source-token vs NULL reconciliation; residual-token check; score and VLE week checks | All seven source token counts matched STAGING NULL counts; no checked `?` remained; scores ranged 0–100 with 173 NULLs; numeric VLE weeks ranged 0–29 with no reversed ranges | Accept the tested conversions and integrity checks; this does not prove every semantic assumption | Close engineering documentation and prepare analytical modelling handover |
| 2026-10-16 | Documentation and handover | What remains before analytical modelling? | Validated SQL results, quality registry summary, and updated documentation | RAW/STAGING core implementation complete; four `REVIEW` items remain documented | Do not continue circular testing; begin next phase only after the documentation pack is applied and reviewed | Define grain, join paths, business questions, and metric definitions |

## Engineering decision: path resolution and safe source acquisition

Initial ingestion used a relative `data/raw` path. The notebook's current working directory can vary, creating a risk that files are placed under `notebooks/`. The workflow was refactored to resolve the project root using `pathlib` and skip downloading/extracting when corresponding files already exist. This avoids manual file moves and unnecessary repeat I/O.

## Engineering decision: preserve RAW and type only from evidence

- `assessments.weight` contains decimal values and uses `NUMERIC` in RAW.
- `assessments.date`, `student_registration.date_registration`, `student_registration.date_unregistration`, `student_assessment.score`, `student_info.imd_band`, `vle.week_from`, and `vle.week_to` retain source `?` tokens in nullable text columns in RAW.
- `student_vle` has no primary key because the tested five-column candidate key is not unique.
- There are no RAW foreign-key constraints. Reference integrity was checked through queries rather than enforced in RAW.

## Engineering decision: repeated `student_vle` rows

The five-column candidate key is `(code_module, code_presentation, id_student, id_site, date)`. The data includes key groups with the same `sum_click` as well as groups with different `sum_click` values. In addition, 642,613 fully identical six-column groups account for 787,170 excess identical rows. These patterns do not prove the source system's cause or the intended interaction grain. No rows have been deleted and no `SUM(sum_click)` aggregation has been applied.

## Engineering decision: typed STAGING

STAGING conversion maps `?` to SQL `NULL` only in these fields: `assessments.date`, both registration date fields, `student_assessment.score`, `student_info.imd_band`, `vle.week_from`, and `vle.week_to`. The conversion fields are typed as INTEGER except `score` as NUMERIC and `imd_band` as TEXT. `student_vle` fields were copied without aggregation, preserving all 10,655,280 rows and the observed candidate-key duplication pattern.

## Historical analytical status — 2026-11-06

The RAW, QUALITY, and STAGING engineering foundation remains complete within its documented scope. WO-1 and WO-2 have completed their defined analytical investigations. WO-2's saved notebook contains 21 executed canonical queries, 28 result sets, 857 displayed rows, 34 executed code cells, and no saved tracebacks or runner row-cap truncation. These are retained local execution outputs; this documentation review did not reconnect to PostgreSQL or rerun SQL.

AN0.07, AN1.10, AN2.10, AN3.01–AN3.08, and AN4.01–AN4.10 are recorded as executed in the WO-2 handover. AN4.07–AN4.10 do not each have a separate human review checkpoint, so execution and result-count validation must not be described as individual interpretation approval.

At this 2026-11-06 checkpoint, AN5 — Engagement Sensitivity was the active work order; the three-query preparation status and statement that no AN5 SQL had executed were historical and were superseded by the five-query execution, quantitative review, and owner-approved closure recorded in the 2026-11-07 sections below. R0/R1/R2 remain metric-only sensitivity alternatives. The repeated `student_vle` source-event semantics remain unresolved. RAW/STAGING remain unchanged. No approved composite KPI, analytical mart, Power BI dashboard, predictive model, or final report is claimed.


## Analytical phase — WO-1 execution evidence and decisions

The saved execution notebook on this branch contains retained outputs for AN0.01–AN0.04, AN1.01–AN1.09, and AN2.01–AN2.09. These are historical execution artifacts from the local PostgreSQL session, not a fresh database run performed during this documentation review. Execution counts and elapsed times are retained in `notebooks/04_sql_analytics.ipynb`; some wide Pandas displays abbreviate middle rows even when the query runner reports that its row cap was not exceeded.

| Query group | Observed result in saved notebook | Decision / interpretation | Remaining limitation |
|---|---|---|---|
| AN0.01–AN0.04 | Database identity is `oulad_analytics`; PostgreSQL 18.6; read-only settings enabled. Registry snapshot: 29 tests, 25 PASS, 4 REVIEW, 0 FAIL, with 29 NULL historical `executed_at` values. All seven STAGING row counts match the established baseline. No STAGING indexes were observed; `student_vle` occupies about 612 MB. | Accept the saved snapshot as historical execution evidence. Do not reconstruct timestamps or create indexes as part of WO-1. | These outputs do not prove the current local database remains unchanged. |
| AN1.01–AN1.03 | Both student tables have 32,593 complete, unique composite keys and reconcile with zero one-sided keys; each contains 28,785 distinct student IDs. Joining 173,912 assessment rows to student profiles by `id_student` alone yields 207,319 rows (+19.21%); the metadata-aware path preserves 173,912 rows. | Use the three-column student-presentation key. Never join assessment records to student profiles by student ID alone without the assessment/presentation constraints. | Findings are limited to the tested paths and saved database state. |
| AN2.01–AN2.02 | Counts reconcile across 22 presentations. AN2.02 returns 88 category-level rows (four recorded final-result categories across 22 presentations); the notebook output representation abbreviates middle rows. | Preserve presentation-level denominators and recorded outcome categories. | The targeted category-count and rounded-percentage reconciliation was subsequently completed on 2026-10-30. The saved reconciliation evidence is recorded in the final section of this log. Missing-outcome semantics remain a separate analytical question and are not resolved merely by category-total reconciliation. |
| AN1.04–AN1.05 | 22 course rows have 22 distinct course-presentation keys; student/course joins preserve 32,593 rows with multiplier 1.0000. All 206 assessment IDs are distinct; the 173,912 assessment rows match metadata with zero unmatched rows and multiplier 1.0000. | Accept the tested course and assessment metadata cardinalities. | No broader join path is implied beyond the tested relationships. |
| AN1.06 | 32,593 student-presentation registration rows represent 28,785 distinct people. Presentation-count distribution: one presentation 25,247; two 3,293; three 221; four 23; five 1. | Label registration rows and distinct people separately. | 45 registration dates and 22,521 unregistration dates are NULL in the established historical profile; absence of an unregistration date is not itself a withdrawal outcome. |
| AN1.07–AN1.08 | Across 22 presentations, all students with recorded activity match a registration in the same module/presentation; no activity-bearing students were outside the registered population. Coverage ranges from 80.22% to 98.69%. The highest no-activity rate is 19.78% (319/1,613) in BBB 2014B; the largest count is 371 in BBB 2014J. Negative relative activity days remain present. | Use registrations as the activity-coverage denominator. A registration with no matching activity row means no activity was recorded under the tested join, not that the student did not learn or withdrew. Preserve negative relative days for later interpretation. | The cause and meaning of absent activity and negative relative days are not established. |
| AN1.09 | All 10,655,280 `student_vle` activity rows have an exact presentation/resource metadata match. The `vle` table has 6,364 distinct site IDs and no duplicate site-ID groups. | Accept resource metadata coverage under the tested matching condition. | This does not resolve the non-unique five-column candidate key in `student_vle`. |
| AN2.03 | All 22 presentations have row counts equal to distinct student counts; status is MATCH. Population ranges from 365 to 2,498. | Preserve presentation-level grain and counts. | Descriptive population profile only. |
| AN2.04–AN2.05 | Saved outputs contain 153 demographic-category rows and 388 region/education-category rows, with presentation-level counts and percentages. The Pandas representations abbreviate middle rows. | Retain source categories and presentation denominators; do not infer causation from composition. | The targeted reconciliation was subsequently completed on 2026-10-30 across all 110 AN2.04 and AN2.05 presentation/dimension groups. Category counts and rounded percentages reconciled to the group denominators. The absence of an explicit `<NULL>` output category does not establish source-wide absence of NULL values. |
| AN2.06 | 44 presentation-by-metric rows; no NULLs in `num_of_prev_attempts` or `studied_credits` in the saved output. Median previous attempts is zero in all presentations; maximum is 6. Mean studied credits range from 33.38 to 92.66; maximum is 655. | Keep medians/ranges alongside means. Investigate extreme values before classifying them as errors. | No value has been declared invalid from range alone. |
| AN2.07–AN2.09 | Total IMD missingness is 1,111/32,593. By presentation it ranges from 0.13% (GGG 2014J) to 5.89% (FFF 2013B). By region, North Region is 731/1,823 (40.10%) and Ireland 266/1,184 (22.47%). By final result: Distinction 6.58%, Pass 4.30%, Withdrawn 2.32%, Fail 2.06%. | Preserve missing values and denominators. These are descriptive missingness patterns only. | Do not infer the mechanism or cause of missingness, or a causal relationship with outcomes. |

## Analytical decisions and remaining gate

- No RAW or STAGING data was modified, deleted, deduplicated, or aggregated by this work order.
- The non-unique `student_vle` candidate key remains unresolved: 10,655,280 rows, 8,459,320 distinct five-column candidate keys, and 2,195,960 excess rows. Do not deduplicate by assumption. Define and compare R0 (all recorded rows), R1 (exact six-column duplicates removed for metric calculation only), and R2 (maximum `sum_click` per five-column candidate-key group) as sensitivity alternatives only after a specific metric is defined.
- The focused reconciliation for AN2.02, AN2.04, and AN2.05 was completed on 2026-10-30 and is recorded above. The arithmetic checks establish category-count and rounded-percentage consistency; they do not resolve missing-value semantics or source-wide NULL presence.
- The current notebook’s saved outputs are evidence of prior execution, not proof of current database state or a fresh execution in this review.
- Power BI, validated KPIs, predictive modelling, and business recommendations remain future work.

## 2026-10-30 — WO-1 targeted category reconciliation completed

The three focused reconciliation cells were executed locally by the project owner after the saved AN2.02, AN2.04, and AN2.05 query outputs had been reviewed. This closes the specific validation gap recorded in the earlier WO-1 handover.

| Query ID | Reconciliation grain | Groups checked | Count reconciliation | Rounded percentage reconciliation | Explicit `<NULL>` output category |
|---|---|---:|---|---|---:|
| AN2.02 | Module-presentation | 22 | 22/22 passed | 22/22 passed | 0/22 |
| AN2.04 | Module-presentation × dimension (age_band, disability, gender) | 66 | 66/66 passed | 66/66 passed | 0/66 |
| AN2.05 | Module-presentation × dimension (highest_education, region) | 44 | 44/44 passed | 44/44 passed | 0/44 |
| **Total** | **All reconciliation groups** | **132** | **132/132 passed** | **132/132 passed** | **0/132** |

Observed percentage totals vary slightly around 100% because displayed category percentages are rounded. The reconciliation code confirmed a single denominator per group and that category counts sum to that denominator. AN2.05 has varying observed category counts across presentations; this is not a failure because the category counts still reconcile to the relevant presentation denominator.

**NULL interpretation:** No explicit `<NULL>` category was emitted by these grouped outputs. This check does not establish that source columns contain no SQL NULL values, nor does it replace the separately documented IMD missingness results (1,111 missing `imd_band` values in the historical profile).

**Execution evidence:** User-returned outputs for the three notebook reconciliation cells; the AN2.05 full output was supplied as an attached result file. These were local executions by the user, not executions performed by the documentation process. Recorded elapsed times: AN2.02 0.078 s; AN2.04 0.082 s; AN2.05 0.061 s. Underlying query outputs contained 88, 153, and 388 rows respectively.

**Decision:** Accept the category-count and rounded-percentage reconciliation for AN2.02, AN2.04, and AN2.05. The targeted validation gate is complete. The saved evidence supports descriptive presentation-level distributions; it does not establish causal effects, resolve the meaning of missing values, or approve these distributions as KPIs.

**Work-order disposition:** The originally planned WO-1 readiness diagnostics and the WO-1B extension, including the three targeted reconciliation checks, are executed and documented. WO-1 analytical readiness is closed for the defined scope. Remaining interpretation issues are carried into the relevant downstream stages rather than treated as reasons to repeat completed checks.

**WO-1 closure boundary:** The WO-1 closure applies to the diagnostics and reconciliation checks defined and evidenced within that work order. It does not imply that every outstanding question associated with AN0–AN2 has been resolved. AN0.07, AN1.10, and AN2.10 remain follow-up analytical checks; their execution is not established by the evidence recorded here.

**Next stage — WO-2:** Execute one bounded, SQL-first work-order package in this sequence:
1. **AN0.07** — Verify documented RAW key expectations against the existing source structures.
2. **AN1.10** — Investigate the observed 33,407-row increase in the assessment join path; its cause remains a hypothesis until tested.
3. **AN2.10** — Extend the descriptive analysis of IMD missingness, separating region and presentation patterns as far as the available data allows without causal interpretation.
4. **AN3** — Analyze outcomes and withdrawal with explicit denominators and careful date semantics.
5. **AN4** — Analyze assessment structure, dates, weights, submission coverage, scores, and banked submissions.

Keep **AN5** separate and dependency-gated. The unresolved repeated `student_vle` candidate-key semantics must be investigated through a defined engagement question and sensitivity design; no RAW/STAGING deduplication or aggregation is authorized. This routing supersedes the earlier next-stage sentence above while preserving the historical WO-1 evidence and closure decision.


## 2026-11-02 — WO-2 execution foundation decisions

The project owner confirmed the reported local synchronization state at commit `51643e63b7c2c6f1398215be965ce4fe61bd6333`: local `main` matched `origin/main`, the working tree was clean, and no reset or repeat synchronization was requested. This is owner-reported local evidence; it is not a Git operation performed by this documentation update.

The WO-2 execution foundation is being prepared on a separate branch. The shared runner in `src/analytics/db.py` is extended to execute a complete SQL file through Psycopg's simple-query protocol (`prepare=False`) and navigate result sets with `nextset()`. SQL is not split on semicolons. The legacy `data`, `rows_displayed`, `display_truncated`, and `elapsed_seconds` keys are retained for callers that consume a single result; the first three remain aliases for the first result set. The new `result_sets` collection records statement number, bounded DataFrame, displayed row count, and truncation status for each returned result set. `elapsed_seconds` measures the complete SQL-file batch; per-statement server execution time is not exposed and is therefore left unavailable rather than estimated.

The existing read-only connection, validated statement timeout, lock timeout, rollback, and connection-close behavior are retained. A synthetic unit-test module was added at `tests/test_analytics_db_runner.py` to cover legacy single-result behavior, multiple result sets, independent row caps, non-result statements, empty SQL rejection, and connection cleanup. The tests have been authored but have not been executed in the user's local environment; no PostgreSQL WO-2 query has been executed.

WO-2 notebook groups are defined as WO2-A through WO2-E, while AN0–AN11 remain the official analytical identifiers. The historical `notebooks/04_sql_analytics.ipynb` remains the WO-1 evidence record and is not to be repurposed. `docs/analytical_work_order_plan.md` remains the WO-1B plan, not the master roadmap.

No WO-2 query result, KPI, causal finding, analytical mart, or Power BI output is claimed by these preparation changes. RAW and STAGING remain unchanged. AN3.06 must be run separately with an explicit timeout after local runner validation. AN4.06 precedes AN4.03 so that banked-submission evidence is examined before timing interpretation; banked status remains an analysis dimension rather than a pre-decided exclusion.


## 2026-11-02 — WO-2 SQL review and notebook architecture

The project owner approved one dedicated notebook for WO-2 and confirmed that the `zero_weight_rows` diagnostic in AN4.10 should be removed. The rationale is that the query first constructs one row per student-assessment-status combination with an observed assessment weight, then aggregates those weights by student-presentation and banked status. A zero-sum-row count does not add a useful diagnostic in this context. The indicator was removed without changing the weight aggregation, coverage-share calculations, or banked-status grouping. This is a static logic correction, not a database result.

The 21 candidate SQL files were statically reviewed and prepared as canonical files under `sql/04_analytics/`. Additional corrections include: AN3.03 gives the after-course-end condition precedence over in-course week buckets; AN3.06 retains withdrawn student-presentations without a registration match by using a LEFT JOIN and classifies `NO_REGISTRATION_MATCH` separately; AN4.08 counts distinct student-presentations rather than implying unique people across the entire dataset. Historical and directional expectations in selected AN3/AN4 queries are treated as hypotheses or reconciliation references.

The WO-2 notebook architecture is one dedicated notebook, `notebooks/05_wo2_analytical_investigation.ipynb`, with canonical SQL kept in separate files and shared execution through `src/analytics/db.py`. The notebook displays all result sets, stores outputs in `query_results`, includes manual review checkpoints, and has a live-execution flag defaulting to disabled. AN3.06 is isolated as a high-runtime query with a 600,000 ms runner timeout. AN4.06 precedes AN4.03.

No WO-2 query was executed against PostgreSQL during this preparation, and no synthetic test execution is claimed. No findings, KPIs, or business rules are approved. RAW/STAGING and persistent database objects remain unchanged.


## 2026-11-02 — Psycopg integration-validation boundary

The mocked unit tests for `src/analytics/db.py` validate Python control flow only; they do not establish that the installed Psycopg version can return multiple result sets from one unparameterized SQL command. The runner's comments were narrowed: `prepare=False` disables statement preparation, while multi-statement execution without parameters and `nextset()` are the behavior to be validated empirically. No unsupported claim is made that the flag alone selects a particular wire protocol.

A dedicated integration test, `tests/test_analytics_db_runner_postgres.py`, and GitHub Actions workflow, `.github/workflows/analytics-runner-tests.yml`, were added. CI provisions a disposable PostgreSQL 18 database named `oulad_runner_test`, runs the pinned Psycopg 3.3.6 test, and uses SELECT statements only. The test checks three result sets, their order, and the read-only session setting. It refuses to run unless the configured database name is exactly `oulad_runner_test`.

The test and workflow are prepared but have not yet run. No CI pass or live OULAD query is claimed. The workflow does not use the user's local credentials or connect to `oulad_analytics`.


## 2026-11-05 — WO-2 notebook execution-flow correction

The WO-2 notebook was compared directly with the retained WO-1 notebook after the project owner identified a structural and diagnostic gap during local use. WO-1 separates project-root/import setup, environment checks, and the AN0.01 database-identity/read-only preflight. The earlier WO-2 version placed setup, helper definition, and review flags in one large cell and did not provide an initial connection preflight. Its first analytical query cell was gated by a disabled live-execution flag, so it could not itself demonstrate that the database connection worked.

The WO-2 notebook was rebuilt to follow the clearer WO-1 sequence:

1. Resolve the repository root and import the shared runner.
2. Validate the project paths, imports, and in-memory result store without opening a database connection.
3. Execute the canonical AN0.01 preflight through a separate read-only connection and display the database identity, server version, session settings, and timeouts.
4. Stop if the database is not `oulad_analytics` or either read-only setting is not `on`.
5. Define the multi-result WO-2 execution helper and validate its availability.
6. Keep live execution disabled by default; require a deliberate edit in a separate authorization cell after the preflight.
7. Execute one canonical query at a time, display all result sets, record runtime and truncation, and enforce manual review checkpoints.

The helper checks the expected result-set count for each of the 21 canonical WO-2 query IDs. AN0.07, AN1.10, and AN2.10 expect three result sets; AN4.05 expects two; the remaining queries expect one. A current AN1.01 student-presentation key refresh was added as a dependency check before AN1.10 because the fan-out decomposition relies on that grain. It is not counted as a new WO-2 query.

The notebook retains the previously reviewed sequencing and safety decisions: AN3.06 is run alone with a 600,000 ms timeout; AN4.06 precedes AN4.03; banked status is not automatically excluded; and AN4.10 has no `zero_weight_rows` diagnostic. The historical WO-1 notebook and canonical SQL files were not changed.

**CI evidence boundary:** the earlier PR run's dependency-install step succeeded, but its test step was cancelled after a hosted-runner shutdown signal. The log contains a Node.js 20 deprecation warning from the Actions runtime. It does not prove a Python test assertion failure, and it is not evidence of a local Jupyter warning. A later push run was in progress at the time of this entry; no result is claimed.

**Execution status:** this notebook correction is a repository artifact change only. No live connection to the user's local database and no WO-2 analytical query execution are claimed. RAW, QUALITY, STAGING, and persistent database objects remain unchanged.

## 2026-11-05 — AN0.07 execution and notebook review-gate correction

The project owner executed the corrected AN0.07 canonical SQL locally after the initial PostgreSQL type mismatch was corrected. The returned batch contained three complete result sets, no truncation, and a total elapsed time of 0.191 seconds.

The seven-row RAW key inventory showed six validated primary keys matching the documented columns and one expected absence of a primary key on `raw.student_vle`. The constraint inventory showed six primary keys and zero unique, foreign-key, or check constraints. The index inventory returned zero rows for `raw.student_vle`. These are metadata observations only. They do not establish uniqueness of the activity rows, justify deduplication, or authorize index creation.

The project lead reviewed and accepted the returned outputs in the conversation. The local notebook printed `AN0.07 reviewed: False` because the manual checkpoint input had not been recorded as `REVIEWED`. The subsequent AN1.01 dependency cell raised a RuntimeError because the gate was closed. This was an expected control-flow stop, not a PostgreSQL error and not an AN1.01 execution.

The WO-2 notebook was therefore revised to make expected closed gates safe and explicit: dependent query cells print `NOT EXECUTED` and return without sending SQL; review checkpoints print `REVIEW BLOCKED` and return `False` when prerequisites are missing; the AN1.01 dependency refresh checks preflight and live authorization before connecting; upstream reruns invalidate their own and downstream approvals/results; and helper reinitialization clears stale WO-2 in-memory outputs while retaining the AN0.01 preflight record. Genuine SQL errors remain visible and are re-raised.

A static scan of the 21 WO-2 SQL files found no other explicit casts to SQL `CHAR` or PostgreSQL internal `"char"`. The remaining `USING` joins are on shared key columns in AN1.10, AN3.03, AN3.06, and AN4.10. This is a static review only; those queries remain unexecuted.

The updated notebook is committed on `work/wo2-pre-execution-readiness` in commits `a9871f6` and `c341ff7`. The updated progress ledger records the full user-returned AN0.07 evidence and the current execution boundary. No RAW/STAGING data or persistent database objects were changed.

**Current disposition:** AN0.07 execution is complete and its findings are accepted in conversation. The notebook's local review flag must be recorded after the corrected notebook is synchronized and AN0.07 is executed in the fresh kernel session. AN1.01 refresh and AN1.10 remain pending. Query-specific interpretation cells for the full WO-2 notebook will be completed after the remaining outputs are returned and reviewed.

The revised helper and AN1.01 refresh cells passed Python AST parsing. Isolated control-flow checks confirmed that closed authorization/review gates skip execution without invoking the database runner or raising a traceback. These checks do not replace full local Jupyter execution or live PostgreSQL validation.


## 2026-11-06 — WO-2 execution review and analytical interpretation

The project owner completed the WO-2 notebook locally and synchronized the saved notebook to `work/wo2-pre-execution-readiness`. The review below is based on the retained outputs in the GitHub notebook snapshot `notebooks/05_wo2_analytical_investigation.ipynb` (blob SHA `e94a9d40876fa638718a12152f572ef1562e55d8`). This was a saved-artifact review; the reviewer did not reconnect to the owner's PostgreSQL database or rerun any query.

### Execution integrity

The saved notebook contains 92 cells, including 34 code cells. All 34 code cells have non-null execution counts (1–34); no code cell is unexecuted and no saved output has an error/traceback. The 21 canonical WO-2 queries returned the expected 28 result sets and 857 displayed rows in aggregate. All query result sets were below the runner's 500-row display cap, and every query's expected result-set-count check passed. The sum of the saved batch elapsed times is 10.099 seconds. This is the sum of runner-reported batch times, not a separately measured end-to-end notebook duration.

The saved AN0.01 preflight output identifies `oulad_analytics` on PostgreSQL 18.6, with `transaction_read_only = on`, `default_transaction_read_only = on`, `statement_timeout = 2min`, and `lock_timeout = 5s`. The saved helper-validation output confirms the live-execution authorization flag was True for this kernel session. The separate AN1.01 dependency refresh also executed and returned PASS for `student_info` and `student_registration`: 32,593 rows each, zero NULL key rows, zero duplicate-key groups, and zero excess rows. AN1.01 is a dependency check and is not counted among the 21 WO-2 queries.

The runner reported no row-cap truncation. Pandas text representations may still abbreviate middle rows with an ellipsis; where a full table is not visible in plain-text output, interpretation is limited to the complete stored result object and the displayed summary, not an assumption that every row is readable in the text representation.

### Query execution register

| Query | Result sets | Displayed rows | Batch seconds |
|---|---:|---:|---:|
| AN0.07 | 3 | 7 + 4 + 0 = 11 | 0.159 |
| AN1.10 | 3 | 5 + 22 + 1 = 28 | 0.718 |
| AN2.10 | 3 | 7 + 95 + 1 = 103 | 0.079 |
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
| AN4.05 | 2 | 5 + 78 = 83 | 0.333 |
| AN4.06 | 1 | 5 | 0.408 |
| AN4.03 | 1 | 17 | 0.141 |
| AN4.07 | 1 | 27 | 0.197 |
| AN4.08 | 1 | 20 | 1.391 |
| AN4.09 | 1 | 178 | 0.411 |
| AN4.10 | 1 | 38 | 0.918 |
| **Total** | **28** | **857** | **10.099** |

The execution order preserves the dependency rule: AN4.06 ran and its manual review checkpoint returned True before AN4.03 was executed.

### Findings and interpretation

**AN0.07 — RAW catalog structure.** The seven-row inventory confirms six documented primary keys as matching and validated; `student_vle` is marked `EXPECTED_NO_PK`. The constraint summary is six primary keys and zero unique, foreign-key, or check constraints. The index inventory returned zero rows for `raw.student_vle`. This is catalog evidence only; it neither establishes row uniqueness nor justifies creating an index or changing RAW.

**AN1.10 — assessment join fan-out.** The five presentation-count groups explain the complete excess: 28,508 + 4,162 + 705 + 32 = 33,407 rows. The reconciliation row reports 173,912 source rows, 207,319 rows for the `id_student`-only join, 33,407 observed and explained excess rows, `reconciles = True`, zero submissions without a matching student profile, 173,912 rows on the metadata-aware path, zero unmatched rows, and a match to the historical baseline. This supports the composite student-presentation join path; it does not support joining by `id_student` alone.

**AN2.10 — IMD missingness.** The saved output reports 1,111 missing IMD rows across 971 distinct students. All 1,111 are classified `NO_ALTERNATIVE_VALUE` by the tested cross-presentation comparison. Row count and distinct-student count are different units. No imputation is supported by this result.

**AN3.01–AN3.05 — withdrawal definitions and dates.** AN3.01 reports 10,156 `Withdrawn` student-presentations: 10,063 with an unregistration date and 93 without one. It also reports nine `Fail` rows with an unregistration date. AN3.02 returns nine `NOT_WITHDRAWN_WITH_DATE` conflict rows (three each in BBB, DDD, and FFF 2013J) and the 93 `WITHDRAWN_NO_DATE` rows. These are data-definition conflicts requiring explicit handling, not a basis for silently redefining outcomes. AN3.04's 45-row missing-registration-date group has 39 withdrawals (86.67%); its small denominator makes the rate unstable. AN3.05 partitions all 32,593 student-presentation rows into 10,014 `AFTER_REGISTRATION`, 22,521 `NO_UNREGISTRATION`, 39 `REGISTRATION_DATE_MISSING`, and 19 `SAME_DAY`. The categories reconcile to the student-presentation population.

**AN3.06 — activity around withdrawal.** The query returned 76 module-presentation/activity-group rows and completed in 4.898 seconds with a 600,000 ms timeout. It uses a LEFT JOIN to registration and keeps `NO_REGISTRATION_MATCH`, missing unregistration dates, no matching activity row, and activity timing groups distinct. Its denominator columns distinguish withdrawn student-presentations from all student-presentations. `NO_RECORDED_ACTIVITY_ROW` means no matching row was found in the available `student_vle` data under the tested join; it does not prove absence of learning, absence of clicks through every channel, or withdrawal causation. The query deliberately does not use `sum_click`.

**AN3.07 — education and previous attempts.** The 36 rows describe outcome shares within each category. The query's `small_category_flag` is calculated from `category_rows < 100`, not from `rows_in_cell < 100`. All category totals in the saved output exceed 100, so the flag is False; nevertheless, individual outcome cells can be small (for example, two rows in the 3+ attempts/Distinction cell). Small subgroup counts must therefore still be read cautiously. The SQL comment's phrase “Small cells (n < 100)” is broader than the implemented flag and should be reconciled before this diagnostic is reused as an automated small-cell warning. Repeated students across presentations also mean these are student-presentation rows, not independent people.

**AN3.08 — presentation variation.** The 22 presentation rows range from 6.93% Withdrawn in GGG 2013J (66/952) to 46.38% in CCC 2014B (898/1,936). This is descriptive variation; it does not establish that a module or presentation design caused withdrawal.

**AN4.01–AN4.04 — assessment structure and dates.** AN4.01 returns 57 module-presentation-assessment-type rows and shows that offered assessment weights and structures differ across presentations. AN4.02 identifies 11 assessments without a due date, all labelled `Exam`. Importantly, the saved result does **not** show zero submissions for all 11: three exams have submission records (747, 1,168, and 950; 2,865 rows total), while eight have none. AN4.04 returns those three groups and reconciles to 2,865 submissions. Therefore, “no due date” must not be interpreted as “no submission” or used alone to infer an assessment's operational status. AN4.03 was run only after AN4.06's review checkpoint and shows timing distributions by assessment type and banked status; its timing categories remain descriptive.

**AN4.05–AN4.06 — scores and banked records.** AN4.05 reports 173 NULL scores (1 banked TMA and 172 non-banked TMA), 329 zero scores, and zero scores outside 0–100. The score profile contains 173,739 non-NULL scores out of 173,912 submission rows. AN4.06 independently reports the same 173,912 total, 173,739 scored rows, 173 NULL scores, and zero missing submission-date rows under its SQL definition. Banked records have `date_submitted = -1` in the saved output; this sentinel must not be read as a literal calendar day. Banked status remains a dimension, not a blanket exclusion rule.

**AN4.07–AN4.08 — participation and score associations.** These outputs describe submission-count buckets and score summaries by final result, assessment type, and banked status. They are retrospective descriptive associations. `final_result` and score information must not be used as predictors when the target is the same final outcome; that would introduce target leakage. Small groups (including one scored Exam submission in a Withdrawn group and other small banked groups) require caution.

**AN4.09 — submission/unregistration timing.** The 178 returned groups compare recorded submission timing categories with registration unregistration dates. The comparison does not establish whether a submission was accepted, graded, or valid after withdrawal. Missing unregistration dates form a separate category and must not be conflated with after-withdrawal submissions.

**AN4.10 — submitted assessment-weight coverage.** The 38 rows are grouped by module, presentation, and banked status. The denominator `student_presentation_rows` is the full presentation population, while the average and median coverage shares are calculated among student-presentations with the corresponding status. A student may occur in both banked and non-banked groups. The GGG 2013J, 2014B, and 2014J rows show 0.000 average and median submitted-weight shares; AN4.01 shows that GGG CMA/TMA weights are zero while Exam weight is 100. This is consistent with the records represented in those status groups carrying no offered weight, not proof that students did not participate in learning activities. AN4.10 is a coverage/grain diagnostic, not approval of a final weighted-score formula. The previously requested `zero_weight_rows` field remains absent.

### Manual review checkpoints and status boundary

The saved notebook records True for the AN0.07, AN1.10, AN2.10, WO2-C, WO2-D, and AN4.06 review checkpoints. The AN1.01 dependency refresh returned PASS. The remaining query cells show expected result-set-count checks passing. The notebook does not contain a separate manual “reviewed” checkpoint after every AN4.07–AN4.10 query; execution and result-count validation must not be described as an independent human approval for each query.

### Decisions and limitations

- WO-2's 21-query execution is complete in the saved notebook snapshot and the saved outputs have been technically inspected.
- Findings remain descriptive and scoped to the saved local execution. No fresh database rerun was performed by this review.
- No KPI, weighted final score, causal explanation, predictive feature set, or business rule is approved by these exploratory queries.
- RAW, QUALITY, and STAGING data were not changed. No index, constraint, view, mart, or other persistent database object was created.
- The non-unique `student_vle` candidate key remains unresolved. Preserve all 10,655,280 source rows. No source-level deduplication or aggregation is authorized.

### Next stage — AN5 design gate

AN5 may now be designed as a separate, dependency-gated engagement-sensitivity investigation. Before writing or running its analytical query, define the engagement metric and its grain, time window, denominator, treatment of negative dates and missing registration/activity matches, and the exact comparison population. Then compare sensitivity alternatives without modifying RAW/STAGING:

- **R0:** all recorded `student_vle` rows;
- **R1:** exclude exact six-column duplicates for the metric calculation only;
- **R2:** retain one maximum `sum_click` per five-column candidate-key group for sensitivity comparison only.

R1 and R2 are analytical alternatives, not approved cleaning rules. Report how each alternative changes the chosen metric and denominator; do not use any alternative as a hidden replacement for the source data. AN5 is not executed or approved by this entry.


## 2026-11-06 — AN5 design and query preparation

The AN5 design specification defines R0 (all recorded rows), R1 (exact six-column duplicate exclusion for metric calculation only), and R2 (maximum `sum_click` per five-column candidate-key group). The provisional output grain is one registered student-presentation, with a common registered denominator across scenarios. Pre-course, in-course, post-course, unmatched activity, and no-recorded-activity states remain explicit.

Three canonical read-only SQL files were prepared under `sql/04_analytics/`:

- `AN5.01_student_vle_scenario_reconciliation.sql`
- `AN5.02_student_presentation_activity_sensitivity.sql`
- `AN5.03_temporal_activity_sensitivity.sql`

A gated orchestration notebook was prepared at `notebooks/07_an5_engagement_sensitivity.ipynb`. It requires a read-only database preflight and an explicit session authorization, runs queries individually, checks expected result-set counts, and blocks dependent queries until review checkpoints are recorded.

**Evidence boundary:** These are prepared repository artifacts only. No AN5 query has been executed against the user's local PostgreSQL database. No live database connection, RAW/STAGING modification, or persistent database-object creation was performed during this preparation.


## 2026-11-06 — Retire synthetic runner CI

The project owner decided to discontinue GitHub Actions and synthetic runner tests as part of the OULAD workflow. The previous workflow used a disposable PostgreSQL database and synthetic/mocked test cases. Those tests did not validate the actual OULAD data, the canonical analytical SQL outputs, or the analytical conclusions, and their maintenance and runner interruptions slowed the work without a proportionate benefit.

The workflow file `.github/workflows/analytics-runner-tests.yml` and synthetic-only runner-test files were removed from the active WO-2, documentation, and AN5 branches. No further retry is requested. The currently running GitHub-hosted attempt could not be cancelled through the available repository integration; deleting the workflow file does not establish that the already-running attempt has stopped. This is not a current analytical blocker and must not be described as a SQL assertion failure.

The accepted validation approach is direct, read-only execution of canonical SQL against `oulad_analytics`, review of actual returned result sets, reconciliation of grains, joins, denominators and row counts, retention of notebook evidence, and inspection of repository diffs. Historical runner interruptions remain historical only.


## 2026-11-06 — Repository integration and validation-policy closure

The WO-2 foundation, WO-2 analytical investigations, documentation consistency update, and AN5 preparation were integrated into `main` through PRs #9–#12:

| PR | Scope | Merge commit |
|---|---|---|
| #9 | WO-2 multi-result SQL execution foundation | `937fa7d0012775b92ba3d30d2897742ab8381222` |
| #10 | WO-2 canonical SQL and saved execution notebook | `f58ca14800a447b1cc6498c979070ec54419a6ca` |
| #11 | Documentation consistency and AN5 design plan | `2303e83f6e522883545172e7e48448c83203a4bf` |
| #12 | AN5.01–AN5.03 and gated orchestration notebook | `541b4237fe7df677d1a0c49ed077dc1ddb38d889` |

The GitHub Actions workflow and synthetic-only test files are absent from `main`. GitHub Actions and synthetic runner tests are not project acceptance gates. The repository-level Actions feature has not been disabled through the available integration. The last observed run #42140281401 attempt 2 remained `in_progress`; the available integration does not expose a cancellation action. No retry was requested, and the existing runner status is not an analytical blocker or SQL assertion failure.

All AN5 SQL and notebook files are prepared artifacts only. No AN5 query has been executed against the user's local PostgreSQL database. RAW, QUALITY, and STAGING were not modified by the repository integration. No persistent database objects were created. The proposed bounded AN5 expansion remains a design decision for owner review; AN6 and AN7 remain separate workstreams.


## 2026-11-06 — AN5 five-query extension preparation

The owner retained the original analytical roadmap and approved two additional AN5 investigations without merging AN6 or AN7 into AN5. The scope remains AN5 — Engagement Sensitivity.

Prepared on `work/an5-five-query-execution`:

- `AN5.04_student_ranking_sensitivity.sql`: compares average-rank Spearman correlation, rank displacement, and tie-inclusive top-decile overlap for R0/R1, R0/R2, and R1/R2 within each module-presentation. The ranking population is the common registered student-presentation population, including zero-activity registrations.
- `AN5.05_outcome_group_activity_sensitivity.sql`: compares recorded activity measures by final-result group within each module-presentation and returns a separate registration-to-profile match diagnostic. Final result is retrospective descriptive grouping, not a predictor.
- `scripts/run_an5.py`: command-line entry point using the shared read-only runner, fresh AN0.01 preflight, sequential query execution, expected result-set checks, and optional bounded CSV/JSON export.
- `notebooks/07_an5_engagement_sensitivity.ipynb`: updated to five queries and WO-1-style direct execution cells after the preflight; no interactive authorization prompt or per-query approval prompt is used. Run cells individually; do not use Run All.

The AN5 plan, progress ledger, analytics SQL inventory, notebook guide, README, data dictionary, and local-output ignore rule were updated for the five-query scope. Static repository checks confirmed all five SQL files contain the required headers and no detected data-changing/DDL statements; the notebook JSON parses and its code cells remain unexecuted. This does not establish PostgreSQL syntax validity or database execution. No AN5 SQL was run, no local database was contacted, and RAW, QUALITY, and STAGING were not modified. AN6 and AN7 remain separate roadmap stages and remain dependency-gated.


## 2026-11-06 — AN5 extension pull request opened

Opened Draft PR #13, `AN5: extend engagement sensitivity to five queries`, from `work/an5-five-query-execution` to `main`. The branch head at PR creation is `574d437f48527a8c5aae218bf73ba63be41027ce`; the PR contains 12 changed files. It remains unmerged. Static repository checks passed for required SQL headers, absence of detected data-changing/DDL statements, notebook JSON validity, and unexecuted notebook code cells. These checks do not replace PostgreSQL syntax/runtime validation. No AN5 query was executed, and local synchronization remains unverified.

## 2026-11-06 — AN5 five-query execution evidence and initial interpretation

The project owner returned the saved local execution outputs from `notebooks/07_an5_engagement_sensitivity.ipynb`. The read-only preflight passed against `oulad_analytics` on PostgreSQL 18.6; `transaction_read_only` and `default_transaction_read_only` were both `on`.

All five canonical AN5 SQL files executed and returned eight expected result sets, with 623 rows retained by the runner and no runner row-cap truncation:

| Query | Result-set row counts | Batch elapsed seconds |
|---|---:|---:|
| AN5.01 | 1, 3, 66 | 660.747 |
| AN5.02 | 69 | 268.471 |
| AN5.03 | 132 | 456.240 |
| AN5.04 | 66 | 70.314 |
| AN5.05 | 264, 22 | 282.843 |
| **Total** | **623** | **1,738.615** |

These are SQL-file batch durations, not per-statement timings or total notebook wall-clock time.

### Findings

- AN5.01 reports 10,655,280 R0 rows, 9,868,110 distinct six-column tuples, and 8,459,320 five-column candidate keys. There are 787,170 excess fully identical rows and 1,179,074 five-column groups with multiple `sum_click` values. R1 is 7.39% below R0; R2 is 20.61% below R0. Neither scenario is accepted as source truth.
- The visible AN5.02 R0 overall row reports 32,593 registered student-presentations, 28,785 distinct students, 29,228 activity-bearing student-presentations, 3,365 with no matching activity row, and 89.68% recorded-activity coverage. Recorded clicks total 39,605,099; student-active-day pairs total 1,808,119; student-active-site pairs total 1,960,496.
- The visible AN5.03 AAA 2013J R0 rows include 10,847 pre-course rows and 170,135 in-course rows. Negative relative days remain separate; their operational cause is not established.
- AN5.04 demonstrates that high Spearman correlations can coexist with many individual rank changes and lower top-decile overlap. For AAA 2013J R0/R1, correlation is 0.999703 while 276 of 383 student-presentations change rank. For GGG 2014B R0/R2, correlation is 0.998118 and top-decile Jaccard overlap is 0.8876.
- AN5.05 returns 264 outcome-group rows. Some module-presentation groups are small. All 22 rows of the profile-match diagnostic show unique profile matches and zero reported missing, duplicate, or conflicting profile matches in this extract. Final result remains retrospective descriptive grouping, not a predictor.

### Review boundary and decision

The runner did not truncate result sets at its configured 500-row cap, but pandas HTML output abbreviates longer DataFrames. Full totals and presentation-level extrema therefore require the complete in-memory result frames or CSV exports; they must not be guessed from visible leading/trailing rows.

Interpretation Markdown was added below each SQL result. A Python-only review/export cell was added to the notebook to calculate scenario differences, denominator invariants, temporal summaries, ranking sensitivity ranges, outcome summaries, and profile-match totals from the already-retained result frames. It exports the complete bounded result sets to the ignored local `outputs/an5/` folder and does not rerun SQL. At this initial checkpoint, the Python-only review/export cell had not yet been executed; its later completion is recorded in the 2026-11-07 section below.

**Historical decision (superseded):** at this checkpoint, AN5 remained open pending the Python-only review/export cell. The later execution and review evidence is recorded in the 2026-11-07 section. No KPI, source-cleaning rule, causal claim, predictive feature, or intervention is approved. AN6 and AN7 remain separate roadmap stages.


## 2026-11-07 — AN5 quantitative review and visual interpretation

The synchronized notebook retains five executed canonical SQL investigations, eight expected result sets, and 623 rows. The saved preflight records `oulad_analytics` on PostgreSQL 18.6 with both read-only settings enabled. SQL batch durations sum to 1,738.615 seconds; this is not total notebook runtime. No runner row-cap truncation or SQL traceback is recorded.

The Python-only review/export cell completed from retained result frames, exported complete bounded result sets to local Git-ignored `outputs/an5/`, and created a JSON manifest. The visualization cell generated eight figures. Neither cell opened a database connection or reran SQL.

- **AN5.01:** R0 10,655,280 rows; R1 9,868,110 (-7.39%); R2 8,459,320 (-20.61%). There are 1,179,074 repeated five-column candidate-key groups with multiple `sum_click` values. All scenarios reconcile to 32,593 registered and 29,228 activity-bearing student-presentations, with zero unmatched activity rows in the tested join.
- **AN5.02:** Click totals are 39,605,099 (R0), 38,343,063 (R1, -3.19%), and 34,402,738 (R2, -13.14%). Coverage remains 89.68% over 32,593 student-presentations; 3,365 have no activity match. Active-day pairs (1,808,119) and active-site pairs (1,960,496) are invariant.
- **AN5.03:** R0 pre-course activity is 688,988 rows (~6.47%) and 2,147,947 clicks (~5.42%). Negative course-relative days do not establish timing relative to individual registration.
- **AN5.04:** Median Spearman is 0.999850 (R0/R1), 0.998870 (R0/R2), and 0.999205 (R1/R2). Rank changes affect 82.44%, 86.51%, and 85.47% of paired student-presentations. Median top-decile Jaccard is 0.97710, 0.91565, and 0.91930; minimum 0.8286 for GGG 2013J R0/R2.
- **AN5.05:** Pooled groups contain 3,024 Distinction, 7,052 Fail, 12,361 Pass, and 10,156 Withdrawn student-presentations, with coverage 100.00%, 94.70%, 99.98%, and 70.58%. Profile diagnostics reconcile 32,593 registered keys to unique profiles with zero reported missing, duplicate, or conflicting matches.

Click volume and row counts are sensitive to repeated-row treatment, while coverage/day/site measures remain invariant in the tested scenarios. High Spearman correlation does not guarantee top-decile stability. Final-result comparisons are retrospective and descriptive, not causal or predictive. R0/R1/R2 remain sensitivity alternatives; no KPI or source-cleaning rule is approved. RAW, QUALITY, and STAGING remain unchanged.

**Historical checkpoint (superseded by the 2026-11-07 closure below):** formal AN5 closure was pending owner review and acceptance of the activity definition and limitations. The owner subsequently accepted the definition and limitations; AN6 and AN7 remain separate.


## 2026-11-07 — AN5 closure decision

**Owner acceptance:** The project owner accepted the operational definition and limitations recorded below. AN5 is closed. This is the current decision and supersedes the earlier pending-closure checkpoint in this log and the historical AN5 preparation notes.

**Decision:** Close AN5 and adopt the operational definition of recorded in-course VLE activity for downstream analysis.

The accepted grain is one registered student-presentation: `(code_module, code_presentation, id_student)`. Activity is joined to registration on the complete three-column key. In-course measures include course-relative days from 0 through `module_presentation_length`, inclusive. Pre-course and post-course records remain separate temporal diagnostics and are not silently discarded.

The primary recorded-activity dimensions are:
1. In-course activity presence and coverage among the full registered student-presentation denominator.
2. Distinct active in-course days.
3. Distinct VLE resources (`id_site`) with recorded in-course activity.

The 89.68% coverage value from AN5.02 is an any-recorded-activity result across the scenarios, not an in-course-only coverage estimate. AN6 must calculate the accepted in-course coverage separately.

Recorded click volume remains a secondary diagnostic because its totals are sensitive to repeated-row treatment. R0, R1, and R2 remain metric-only sensitivity scenarios; no source cleaning or deduplication rule is approved.

A missing activity match is defined narrowly as no matching recorded row under the specified source, join key, and time window. It is not evidence of no learning. Activity rows without registration matches remain separately reported. `final_result` remains a retrospective descriptive grouping variable, not a predictor or causal explanation.

**Evidence:** Five read-only SQL investigations executed; eight expected result sets and 623 rows retained; quantitative review/export completed; eight visualizations and their interpretation captions retained in the AN5 notebook. The returned execution showed R0/R1/R2 click totals of 39,605,099 / 38,343,063 / 34,402,738, with 89.68% overall activity coverage in each scenario. Median Spearman correlations remained high, while the minimum top-decile Jaccard overlap was 0.8286.

**Limitations:** The overall AN5 scenario summaries do not themselves establish every future in-course-only measure; AN6 must calculate and reconcile its measures under the accepted day window. No composite KPI, threshold, causal claim, intervention rule, or predictive feature is approved. RAW, QUALITY, and STAGING remain unchanged.

**Next:** Scope AN6 as a separate work order using a pre-execution metric contract. Keep AN7 separate and define its outcome and temporal leakage controls before writing SQL.


## AN6 — Recorded VLE Activity Patterns: package preparation (2026-11-08)

The AN6 work order, four canonical read-only SQL investigations, sequential Python runner, and orchestration notebook were prepared on a dedicated branch. The accepted AN5 definition is retained: registered student-presentation grain, full three-column join, and inclusive in-course window from relative day 0 through `module_presentation_length`.

The package is designed for six result sets: three readiness outputs from AN6.01 and one result set from each of AN6.02–AN6.04. The runner requires AN0.01 read-only preflight and blocks downstream scans if course-window, VLE resource-key, registration-key, or activity-key integrity checks fail. Missing activity type/week metadata is reported rather than filtered. AN6 uses R0 for presence/day/resource measures; it does not repeat R1/R2 sensitivity scans.

**Repository review:** PR #16 is open and unmerged. The package is available for code review on the dedicated branch.

**Status at preparation:** SQL has not been executed; no local database output, metric result, or visualization is claimed. The notebook contains no saved query outputs. Local PostgreSQL state and execution remain unverified.


## AN6 implementation correction — 2026-11-08

The first local AN6.01 execution stopped with PostgreSQL `UndefinedColumn: key_rows`. Root cause: the third result set referenced the per-registration grouped count in the outer aggregate without projecting it from the intermediate CTE. Corrected by carrying `key_rows` into `registration_course_match` and computing duplicate/excess registration metrics in a dedicated aggregate CTE. The connection runner was not the source of this error.

The VLE metadata key was also tightened to the presentation-scoped composite `(code_module, code_presentation, id_site)`. AN6.01 now tests this key; AN6.04 uses it in both resource-metadata joins. The runner's readiness gate now checks the activity-to-course-window match count and resets its readiness state on every new preflight / AN6.01 execution.

The notebook now prints the AN0.01 row (database, user, server version, schema, read-only settings and timeouts) and an explicit check table. The AN6.01 cell prints each result-set row count/truncation state and displays each frame before applying its gate. The later AN6.02–AN6.04 notebook query cells retain the direct `run_query` approach and were not substantively changed.

**Status:** correction committed to the existing AN6 branch and PR #16. No SQL was executed after the correction; runtime behavior and local database state remain unverified.


## 2026-11-09 — AN6.03 PostgreSQL memory-pressure repair

The owner supplied local execution evidence for AN0.01, AN6.01, and AN6.02. The database identity/read-only preflight passed. AN6.01 passed its readiness gate for all 22 course presentations, unique course/resource/registration keys, complete activity key components, and registration/activity course-window matches. VLE week metadata remained incomplete in 5,243 rows for each of week_from and week_to; this is descriptive metadata missingness and is not used as a filter. AN6.02 returned 88 rows (four measures for each of 22 presentations). Its coverage rows reconcile the denominator into in-course activity, outside-window-only, and no-recorded-activity categories. The user then encountered PostgreSQL OutOfMemory in TupleSort while running AN6.03.

**Repair:** AN6.03 now aggregates to student-presentation × temporal bucket/period grain before calculating presentation-level reach. The expensive composite distinct key count was removed, full-population distinct-student sorting was replaced with counts over pre-aggregated student-level groups, and the final global sort was removed. Exact activity-row totals, registered reach, unmatched activity-row counts, secondary click totals, PRE/IN/POST/NO_COURSE_WINDOW labels, relative seven-day periods, and boundary-day checks are retained.

**Python/notebook:** scripts/run_an6.py now emits PostgreSQL SQLSTATE and diagnostic fields with query ID and SQL path on failure, preserves the exception chain, and does not retry. Notebook 08 uses the canonical runner for preflight, AN6.01 readiness, and AN6.02–AN6.04 execution, avoiding divergent direct-runner logic.

**Evidence boundary:** The AN0.01, AN6.01, and AN6.02 outputs above are supplied by the owner from the local Jupyter session. The repaired AN6.03 has not been executed. No claim is made about its memory use, runtime, or final result.


**Repository targeting correction:** A connector write-target issue briefly placed three new AN6 repair files on main. The misplaced files were removed by a compensating main commit, restoring the pre-AN6 main file tree. The corrected files were integrated into the existing PR branch through a merge commit; PR #16 remains open and unmerged.

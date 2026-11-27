# Analysis Log — OULAD EdTech Learning Analytics

**Project Owner & Lead Analyst:** Abdeljalil El Khyati  
**Last updated:** 2026-11-22

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


**Final repository state:** PR #16 head is b4cb971a542b60d9db4de6fb67de5eae746460e6. A connector write-target issue briefly created three AN6 repair files on main; those files were removed in a compensating commit (main head 948fc9f4f16ee7e653feb0f7504d8b96889be720). The repaired files and documentation are on the PR branch. The branch is 57 commits ahead and 0 behind main; GitHub reports PR #16 mergeable and clean. No merge was performed.


## AN6 — Recorded VLE Activity Patterns: execution review and closure (2026-11-11)

The project owner supplied the synchronized Notebook 08 containing local execution outputs for AN0.01 and AN6.01–AN6.04. The AN0.01 read-only preflight passed on `oulad_analytics` (PostgreSQL 18.6). All four canonical AN6 queries returned their expected result-set counts without truncation; the retained notebook records the query outputs, runtimes, Python-only reconciliations, visualizations, and analytical review.

| Query | Result sets | Returned rows | Batch runtime | Retrieval |
|---|---:|---:|---:|---|
| AN6.01 | 3 | 22, 1, 1 | 27.348 s | Complete |
| AN6.02 | 1 | 88 | 156.565 s | Complete |
| AN6.03 | 1 | 971 | 154.189 s | Complete |
| AN6.04 | 1 | 254 | 247.918 s | Complete |
| **Total** | **6** | **1,258** | — | **No result-set truncation** |

The runtimes above are SQL-file batch durations recorded by the notebook, not end-to-end notebook wall-clock time or per-statement timings.

### Readiness and population

AN6.01 readiness passed for all 22 module-presentations, 6,364 unique course-scoped VLE resource keys, 32,593 unique registered student-presentation keys, complete activity-key components, and matching course windows. The activity source contained 10,655,280 rows. VLE `week_from` and `week_to` were each missing in 5,243 of 6,364 resource records; the overlap between those missingness sets was not measured.

AN6.02 returned 88 rows (four measures for each of 22 module-presentations). The registered population partitions exactly into:
- 28,500 student-presentations with in-course recorded activity;
- 728 with recorded activity outside the in-course window only;
- 3,365 with no recorded activity in any observed window.

Pooled in-course coverage is **87.44% (28,500 / 32,593)**. It is distinct from AN5's **89.68%** overall any-window activity coverage. Active-day and resource-breadth distributions retain zero-activity registrations. First-in-course-day statistics are conditional on a recorded in-course activity row.

### Temporal reconciliation

AN6.03 returned 971 rows without truncation. Temporal-bucket totals and relative seven-day-period totals each reconciled independently to all **10,655,280** source activity rows. AN6.02 and AN6.03 registered denominators and in-course activity-bearing reach matched. All **88** boundary diagnostics (four per module-presentation) were present.

The returned temporal buckets were:
- `IN_COURSE`: 9,966,292 rows (93.53%);
- `PRE_COURSE`: 688,988 rows (6.47%).

No `POST_COURSE` bucket was returned. This is an observed result in the supplied data, not an explanation of the dataset's extraction or observation boundary. Relative days are measured from presentation start, not individual registration.

### Resource metadata and activity types

AN6.04 returned 254 rows without truncation. All 10,655,280 activity rows matched resource metadata; unmatched resource rows, missing `activity_type` rows, and unmatched-registration activity rows were all zero. Registered in-course activity-type totals reconciled to AN6.03 for all 22 module-presentations.

The five highest-volume activity types were `forumng` (2,297,748 rows; 23.06%), `oucontent` (1,850,375; 18.57%), `subpage` (1,783,734; 17.90%), `homepage` (1,630,668; 16.36%), and `quiz` (897,842; 9.01%). Together they account for 84.89% of in-course activity rows. These are source-row volumes, not unique-student reach or learning outcomes. Reach across activity types is non-additive.

### Visual interpretation and remaining questions

Figure 1's saved output reports **22 distinct module-presentations**, 795 complete presentation-period observations, and 22 partial/post-course period rows excluded from that chart. The Markdown note was stale because it still requested re-execution to refresh a diagnostic; it has been corrected to reflect the retained output. The chart compares presentation-level activity-row counts and is not normalized for registered cohort size. It is exploratory and remains sensitive to unresolved repeated source rows.

Figure 2 describes activity-row composition by VLE type. Volume and reach are separate dimensions; the leading row-volume types do not necessarily have the highest presentation-level reach. Activity-type reach is non-additive, and type-specific row-volume rankings have not been tested under AN5 R1/R2.

Follow-up questions remain outside AN6 closure:
- normalize temporal row volumes by registered student-presentation before any cross-presentation comparison;
- examine activity-type reach separately from row volume and run type-specific R1/R2 sensitivity only if type-level volume is proposed for reporting;
- align PRE_COURSE activity with each student's registration date before interpreting personal pre-registration timing;
- measure overlap and distribution of missing `week_from`/`week_to` values if academic-week reporting is required;
- investigate the source observation boundary behind the absence of returned POST_COURSE rows.

### Closure decision and limits

**AN6 is CLOSED** for its approved descriptive scope. The six result sets were complete; readiness, coverage partition, temporal totals, in-course reach, boundary diagnostics, resource matching, and activity-type reconciliations passed. Notebook 08 retains 12 executed code cells, the full query outputs, visual outputs, and the Python-only review. The duplicate Section 13 cell and final empty code cell were removed without changing executed outputs; the Figure 1 saved-output note was corrected. No SQL or analytical code cell was rerun as part of this documentation closeout.

The analysis does not approve a production KPI, composite engagement score, causal interpretation, intervention threshold, predictive feature, or AN7 implementation. Click volume and row-volume comparisons remain sensitive to unresolved repeated `student_vle` source records. RAW, QUALITY, and STAGING were not modified, and no persistent database objects or indexes were created.

AN7 may proceed to **scoping only** after outcome/withdrawal definitions, `is_banked`, assessment weights and score coverage, CMA due-date semantics, and leakage-safe observation cutoffs are frozen. No AN7 SQL execution or predictive modelling is authorized by this AN6 closure.


## 2026-11-14 — AN7 Outcome Associations: execution review and analytical closure

AN7 was executed locally by the project owner and its retained evidence was reviewed from Notebook 09. The reviewed pre-closeout notebook blob was `a61a9f777327505272ddce1ab7e579fb743ef5b9`, with 73 cells and 32 executed Python code cells; all 32 code cells retained execution counts, 30 produced saved outputs, and two setup/helper-definition cells intentionally produced no display output. The closeout documentation update preserved the original code and saved outputs, corrected stale status wording, and added a result-specific sensitivity interpretation cell. No SQL or statistical analysis was rerun during closeout.

### SQL execution record

| Query | Result sets | Returned rows | Batch runtime |
|---|---:|---:|---:|
| AN7.01 | 3 | 20 + 15 + 22 | 0.121 s |
| AN7.02 | 1 | 171 | 0.010 s |
| AN7.03 | 1 | 32,593 | 0.405 s |
| AN7.04 | 1 | 32,593 | 96.683 s |
| AN7.05 | 1 | 32,593 | 93.835 s |
| **Total** | **7** | **65,204** | **191.054 s** |

AN7.04 and AN7.05 were separate high-cost scans and ran sequentially. The saved preflight records `oulad_analytics`, PostgreSQL 18.6, schema `public`, `transaction_read_only=on`, `default_transaction_read_only=on`, `statement_timeout=2min`, and `lock_timeout=5s`. No result truncation was reported.

### Cohort and extraction reconciliation

- 32,593 registered student-presentations and 28,785 distinct people.
- 28,500 registrations with in-course activity and 9,966,292 in-course source activity rows.
- 28,500 full-course resource-bearing registrations and zero NULL resource-key groups.
- AN7.03–AN7.05 each returned 32,593 unique full three-column keys; the one-to-one merge retained 32,593 rows.
- 107,752 pre-course active days; 23,809 registrations had at least one pre-course active day.
- No in-course active day preceded recorded registration among registrations with known registration dates.
- Exposure states at L28/L56/L84: 45 unknown, 18/9/4 zero, and 32,530/32,539/32,544 positive.

### O1/O2/O3 findings

O1 (Withdrawn vs other known outcomes) produced median Cliff's delta values from -0.178 to -0.197. Negative estimates occurred in 20–22 of 22 presentations; 18–19 confidence intervals were wholly below zero. The association is broadly consistent but less uniform than O2/O3.

O2 (Fail vs Pass/Distinction) produced median Cliff's delta values from -0.407 to -0.572. All 22 presentation estimates were negative at every landmark-feature combination, and all reported confidence intervals were wholly below zero.

O3 (Fail < Pass < Distinction) produced median Spearman rho values from 0.340 to 0.470. All 22 presentation estimates were positive at every landmark-feature combination, and all reported confidence intervals were wholly above zero.

The notebook retains 264 binary effect estimates, 132 ordinal estimates, 396 outcome-feature-landmark presentation summaries, and 24 visualizations (15 original figures plus nine sensitivity figures generated from retained CSV exports). These are presentation-specific observational associations, not pooled causal or predictive effects.

### Sensitivity analysis

The Python-only sensitivity analysis used existing dataframes and generated 660 rows: 132 primary O1, 132 O1 including eligible undated Withdrawn cases, 132 O2 excluding Fail/date-unregistration cases, and 264 O1 registration-timing-stratum rows. The 30-row summary distinguishes four period labels from the 22 module-presentation estimates.

- O1 inclusion alternative: 130/132 paired estimates retained direction. The two sign changes were near-zero resource-breadth estimates in GGG/2013J at L56 and L84. Median absolute paired change ≈0.00166; maximum ≈0.06233, with larger changes in selected 2014J presentations.
- O2 exclusion alternative: all 22 presentation estimates remained negative for both features at all three landmarks after excluding the nine Fail/date-unregistration cases.
- Registration timing: the on/before-start stratum broadly reproduced primary O1 results. The after-start stratum had 12/22 estimable and 10/22 non-estimable estimates per landmark-feature combination; the median comparison-group size among estimable estimates was five (range 1–49). No stronger-association claim is supported for this sparse stratum.

### Decisions and limitations

Active-day rate is retained as the primary candidate for AN10 predictive-readiness review. Resource breadth is retained as a secondary candidate with explicit exposure-opportunity caveats. Neither is approved as a production KPI or predictive feature. `final_result` remains outcome-only; the 93 undated Withdrawn and nine Fail/date-unregistration records remain source anomalies. Assessment scores remain excluded from early features because score/feedback availability time is not established.

The findings remain observational, use changing landmark risk sets, and are subject to repeated-person clustering, exposure differences, day-level same-day ambiguity, unresolved source repetition, unadjusted multiple comparisons, and unmeasured confounding. No causal claim, predictive performance, model, threshold, or intervention rule is approved.

**Decision:** AN7 is analytically CLOSED for its approved outcome-association scope. AN8 — Validated Metrics & Marts is now the next workstream. AN10 remains the later predictive-readiness gate, not automatic authorization to train a model. Its handover must define operational cutoffs, feature availability, temporal validation across presentations, repeated-student dependence, class imbalance, calibration, confounding, subgroup reliability, and baseline comparisons.

No RAW, QUALITY, or STAGING data was modified. No persistent database object or index was created. No SQL was rerun during the closeout review.


### Repository integration — PR #19

PR #19, “AN7: close outcome associations analysis and document findings”, was squash-merged into `main` on 2026-11-14. Merge commit: `a3c321bc1536aec81c82541da77085e39784cd8e`. The PR integrated 18 files from a clean branch created at the v1.1.0 main baseline. The original divergent execution branch was not merged directly and was not deleted. No database operation was part of the Git merge.


## 2026-11-14 — Analytical roadmap sequencing decision after AN7

Following AN7 analytical closure, the project roadmap was reviewed before defining the next work order. The former AN8 Predictive Readiness Gate is moved behind the descriptive analytical reporting stage. This avoids treating observational associations as a reason to begin predictive work before validated business measures and an interactive reporting layer are complete.

The approved sequence is:

1. **AN8 — Validated Metrics & Marts:** define and validate business-facing measures, denominators, grains, time bases, missingness policies, subgroup reporting dimensions, and curated SQL outputs.
2. **AN9 — Power BI:** build interactive reporting from approved and reconciled metrics/marts; do not re-implement metric logic inconsistently in the dashboard.
3. **AN10 — Predictive Readiness Gate:** after the descriptive dashboard, assess operational decision, target, cutoff, feature availability, leakage, temporal validation, repeated-student dependence, baseline, calibration, class imbalance, subgroup reliability, and error trade-offs. This is a readiness decision, not model training.
4. **AN11 — Consolidated Final Analytical Report:** synthesize validated findings, reporting outputs, limitations, and recommendations.

The separate Data Science / Machine Learning phase remains downstream of the completed analytical phase and its exit criteria. AN7 remains an observational association study; it does not establish predictive performance or approve model features. No SQL was rerun and no database, RAW, QUALITY, or STAGING data was changed by this roadmap decision.

Repository status at review: AN7's integration and follow-up evidence commits are present on `main`. Repository branch cleanup remains a separate controlled task; no branches were deleted during this review. The roadmap/documentation consistency updates were merged through PR #22 at `7130d9dba315561a2134c432d0d373a13613ea7a`; a wording-only follow-up PR #23 was merged at `db01d3d144c121f5e203a58c4eae423ab3195cd6`. Both were documentation-only. Local synchronization remains unverified.


## 2026-11-14 — Remote branch cleanup review

The remote repository inventory contains 23 branches: `main`, two intentional backups, and 20 temporary branches. The documentation branch `docs/branch-cleanup-review-2026-11-14`, used for PR #25, is also a cleanup candidate after local synchronization. The completed AN5 and AN7 content was checked against the current main tree. AN5 notebook execution outputs are retained with matching code-cell execution counts and result outputs; its SQL runner and AN5.04/AN5.05 SQL files match the integrated main versions. AN7's 32 executed Python code cells, execution counts, and saved outputs match the integrated Notebook 09; main adds one explanatory Markdown cell. The AN7 runner and five canonical SQL files have identical blob SHAs on the execution branch and main. Older documentation branches contain historical wording superseded by current main documents.

All 19 non-backup branches are approved deletion candidates after local main synchronization and a clean working-tree check. The two backup branches are intentionally retained. No remote branch was deleted during this review because the available GitHub connection does not expose a branch-delete operation. The progress ledger records the exact candidate list and deletion commands. Local synchronization has not yet been verified.


## 2026-11-15 — AN7 sensitivity visual review

The owner executed the Python-only sensitivity visualization cell in Notebook 09 from the retained exports in `outputs/an7/`. The saved notebook revision contains nine additional figures: three O1 primary-versus-alternative comparisons, three O2 primary-versus-exclusion comparisons, and three registration-timing estimability charts. The cell read `AN7_sensitivity_effects_full.csv` (660 rows), `AN7_sensitivity_summary.csv` (30 rows), and `AN7_binary_effects_full.csv`; its saved output reports successful completion and explicitly confirms that no SQL was executed. No statistical-analysis cell or database query was rerun for these figures.

The visual interpretation records 130/132 O1 paired estimates retaining direction, two near-zero resource-breadth sign changes in GGG/2013J at L56/L84, a median absolute paired change of approximately 0.00166 and maximum approximately 0.06233; O2 remained negative in 22/22 presentations after the specified nine-record exclusion; and the after-course-start stratum had only 12/22 estimable estimates, with median comparison-group size 5 (range 1–49). The figures are presentation-level sensitivity evidence, not confidence-interval displays, pooled student effects, causal evidence, or predictive performance.

The revised downstream sequence remains AN8 — Validated Metrics & Marts, AN9 — Power BI, AN10 — Predictive Readiness Gate, and AN11 — Consolidated Final Analytical Report. The notebook adds a pre-visualization explanation and a post-visualization interpretation/handover. No RAW, QUALITY, STAGING, SQL, or database state changed.


## 2026-11-17 — AN8 initial execution review and scope extension

The owner executed the initial AN8 notebook cells locally. The saved Notebook 10 outputs record AN0.01 read-only preflight; AN8.01–AN8.04; AN8.10–AN8.12; AN8.20; local extract export; and Python reconciliation. This review did not reconnect to PostgreSQL or rerun any query.

- Preflight: database `oulad_analytics`, PostgreSQL 18.6, read-only transaction and default settings enabled; two-minute statement timeout and five-second lock timeout.
- AN8.01: all seven expected STAGING relations exist. Returned row counts are planner estimates, not exact counts; the zero estimate for courses is not proof of an empty table. Analyze timestamps were NULL in the returned catalog profile.
- AN8.02: `student_info` and `student_registration` each contain 32,593 rows and 32,593 distinct three-column student-presentation keys; zero duplicate groups, zero NULL-key rows, and zero bidirectional key-set differences.
- AN8.03: Pass 12,361 (37.93%); Withdrawn 10,156 (31.16%); Fail 7,052 (21.64%); Distinction 3,024 (9.28%). All 32,593 student-presentation rows match registration. Distinct people by category are non-additive across presentations.
- AN8.04: 22 course presentations and 206 assessments; 11 assessments have missing due dates. Due dates do not establish score availability.
- AN8.10: registration dates: 32,312 before course start; 234 after; 2 on start; 45 missing.
- AN8.11: Withdrawn/no unregistration date = 93; Fail/with date = 9; Pass and Distinction have no unregistration dates in the saved result. Preserve anomalies for sensitivity analysis.
- AN8.12: 173,410 nonzero scores; 329 observed zero scores; 173 NULL scores across 173,912 assessment records.
- AN8.20: 85.582 seconds; 32,593 student-presentation rows and 37 columns; 10,655,280 source activity rows; 39,605,099 recorded clicks; all activity rows matched registration; zero unmatched rows; 9,966,292 in-course and 688,988 pre-course rows; no post-course or no-course-window rows. R0 was preserved.

The initial output scope was insufficient for the intended professional reporting layer: it did not provide full zero-inclusive metric distributions, current R0/R1/R2 metric impact, exposure distributions, presentation-level outcome-stratified activity profiles, or assessment opportunity coverage. The owner approved expanding AN8. Seven read-only SQL investigations AN8.30–AN8.36 and corresponding Notebook 10 cells were prepared. They have not been executed; no findings are attributed to them.

The owner also decided to preserve a full local copy of the current `data` directory (reported size approximately 487 MB) outside the project before any local data cleanup. This is a planned owner action, not a verified backup. No local files were deleted or modified by this work. The analytical decision is to preserve original evidence while allowing purpose-specific, versioned derived datasets to apply justified filtering, normalization, reshaping, aggregation, and sensitivity scenarios. Each transformation must record grain, rule, rationale, affected rows/keys, before/after counts, metric impact, alternative scenario, and approval state. No blanket deletion, automatic deduplication, mean imputation, or global outlier removal is approved.

Notebook 05 was expanded from a three-section placeholder into a documented Python advanced-analysis workbench. It remains a plan; no statistical or machine-learning analysis is claimed executed there. SQL remains responsible for relational aggregation; Python is reserved for statistical inference, bootstrap uncertainty, multivariate diagnostics, and visualization where justified. Predictive modeling remains gated by AN10.

**Disposition:** AN8 OPEN — initial extraction executed; extended analysis prepared, not executed. AN9 Power BI remains blocked pending validated metrics, denominators, transformation rules, and curated reporting outputs. AN10 remains the predictive-readiness gate after AN9; AN11 remains the consolidated final report. RAW, QUALITY, and STAGING were not modified. No permanent database objects or indexes were created.

Detailed initial evidence and the rationale for the expanded scope are in `reports/AN8_initial_results_and_scope_extension.md`.


## 2026-11-19 — AN8 Part 2 extended execution and evidence-based reporting

The owner executed AN8.30–AN8.36 locally and synchronized the saved Notebook 10 outputs to feat/an8-csv-review-visualizations. The local export was verified in PowerShell: the execution manifest exists and 17 CSV result files are present. The saved manifest reports 15 query records, 17 result sets, 37,584 exported rows, six passing gates, and zero export errors. The saved Notebook 10 CSV review section (cells 17.00–18.1) shows successful loading, individual visualizations, and a passing 17-result-set / 37,584-row inventory assertion.

The extended evidence establishes the following reporting risks:
- R1 exact six-column distinct reduces activity rows by 787,170 (7.39%) and clicks by 1,262,036 (3.19%) versus R0.
- R2 five-key MAX reduces activity rows by 2,195,960 (20.61%) and clicks by 5,202,361 (13.14%) versus R0.
- 1,614,505 repeated five-key groups include 1,179,074 groups with multiple click values; neither R1 nor R2 is accepted as source truth.
- 688,988 pre-course activity rows (6.47%) and 2,147,947 pre-course clicks (5.42%) must be separated from course-window engagement.
- 3,365 student-presentations have no recorded activity row in the retained AN8.20 extract; this does not prove absence of learning.
- 45 registrations lack a registration date, making registration-relative exposure unknown.
- 173 NULL scores and 329 observed zero scores remain distinct; AN8.35 opportunity denominators are not unique-person denominators.

The complete evidence-based interpretation is in reports/AN8_part2_analytical_findings_report.md. A dedicated Part 3 plan is in docs/AN8_part3_deep_cleaning_analysis_plan.md. Part 3 will create purpose-specific derived datasets with rule IDs, row/key impact, before/after reconciliation, sensitivity alternatives, and approval state. RAW and STAGING remain immutable.

Notebook 10 Sections 19–20 now contain prepared cross-result diagnostic cells for exposure reconciliation, zero-inclusive distributions, outcome heterogeneity, assessment states, and profile missingness/small cells. These new cells have NOT yet been executed; no computed output from them is claimed. No SQL was rerun and no database object or source data was modified during this documentation/notebook update.


## 2026-11-22 — AN8 integrated review and Part 3 semantic-cleaning design

Notebook 10 Sections 19.01–19.07 contain saved execution counts 37–43 and retained outputs. The notebook's stale metadata and introductory status were corrected, the evidence-to-decision register was expanded, and Section 21 was added as an educational findings summary. This update used the existing saved CSV-backed outputs; no PostgreSQL connection or SQL execution occurred.

The saved integrated review reports 32,593 student-presentations; 3,365 without any recorded VLE activity row; 4,093 without in-course activity; 32,548 with known positive registration-relative exposure and 45 with unknown exposure; and 4,093 zero values (12.56%) for each of four zero-inclusive activity measures. The 728 difference between no in-course activity and no activity row is a candidate pre-course-only group, not a validated classification until record-level reconciliation is completed. Assessment opportunity results distinguish 323,925 opportunities, 173,912 submission rows, 150,013 no-submission opportunities, 173 submitted NULL scores, and 329 observed-zero scores.

The OULAD source descriptor confirms that the relevant `date` fields in student VLE, registration, assessment metadata, and assessment submissions are integer day offsets from the start of a module-presentation; day zero is the reference and negative values represent days before that reference. This resolves the general meaning of negative relative-day values. It does not provide an exact calendar start date for every presentation, so calendar-date conversion remains gated on a verified presentation-date anchor. The special interpretation of `student_assessment.date_submitted=-1` remains unresolved and requires linked-row inspection. No source values were changed.

The Part 3 plan now defines source-preserving profiling, candidate field inventory across all seven CSVs, relative-day derived fields, sentinel checks, transformation audit requirements, the `data/working/raw` and immutable snapshot layout, isolated `oulad_an8_work` schemas, and AN9's three educational reporting views (source-faithful, validated working, and impact comparison). It also defines P3.00–P3.08 query groups. These are design decisions and proposed work, not executed cleaning or SQL.

Repository integration review found the feature branch at `cd243908bdcf581a9ac9b553dc70813991531330`, 122 commits ahead and 0 behind main. PR #27 remains draft/open, targets the preparation branch, and currently reports mergeable=false. Its current diff contains 8 paths; the full feature-branch comparison to main contains 37 changed paths. No retarget, merge, branch deletion, database creation, raw copy, or Power BI implementation was performed. The full 37-file diff must be reviewed before selecting an integration route.


## 2026-11-22 — Part 3 workspace verification and isolated-database approval

The owner returned a Windows PowerShell SHA-256 comparison for the eight files in each of `data/raw/`, `data/Backup/raw/`, and `data/working/raw/`. All eight file hashes matched across all three folders. The eight backup-manifest entries also passed both checks: the backup file matched its manifest hash, and the recorded source hash matched the manifest hash. This is owner-returned local evidence; no local filesystem was accessed by this repository update.

The owner approved the following operating arrangement: `data/working/raw/` is the sole operational file input for Part 3; `data/raw/` remains the immutable original; and `data/Backup/raw/` remains the immutable recovery copy. `oulad_dataset.zip` is retained in all three locations because its storage cost is immaterial relative to the dataset workspace and it preserves the source archive. The Part 3 import will consume the seven CSV files from `data/working/raw/`, not the ZIP. No folder or file was deleted, modified, or recopied, and no additional full snapshot was created.

The owner separately approved proceeding to create the isolated PostgreSQL database `oulad_an8_work` and import the seven CSVs from `data/working/raw/` into `source_ref`. This approval is scoped to the new work database. It does not authorize changes to `oulad_analytics`, RAW, QUALITY, or STAGING, or blanket cleaning, deduplication, indexes, or derived persistent objects. The existing P3.00–P3.08 SQL package remains prepared and unexecuted; it requires the isolated database and source-faithful TEXT import first.

The Part 3 branch is `feat/an8-part3-semantic-cleaning`, based on the Part 2 merge commit `0697d0694d44cc543a1fa725414bd5e2dc1ab7b9`. GitHub reported branch head `7abf3f853f0540532c5e86758eb61eb810375fa0` during this review. The owner previously reported successful local synchronization and a clean working tree at that checkpoint; any subsequent documentation commit must be synchronized locally before execution. No database creation, CSV import, P3 query execution, or Power BI work occurred in this update.

**Next work order:** prepare and statically validate the isolated database setup and controlled seven-CSV import procedure; then the owner creates/imports locally, reconciles the import with P3.00 once, and returns the results before any further P3 query is approved for execution.

## 2026-11-22 — Part 3 isolated workspace and controlled import package

Following the owner's approval, the Part 3 branch now contains separate setup artifacts for the isolated source workspace:

- `sql/00_database/02_create_oulad_an8_work.sql` creates only `oulad_an8_work` and must be run from a maintenance connection.
- `sql/05_part3/00_create_source_ref_tables.sql` creates the four planned schemas and seven empty `source_ref` tables with every source column typed as TEXT.
- `scripts/import_part3_source.py` validates the seven working CSVs against the backup manifest and recovery-copy hashes, validates exact CSV headers, refuses a non-empty or unexpected `source_ref` inventory, and imports all seven files through PostgreSQL COPY in one transaction. It hard-codes the target database name and does not use the existing `DB_NAME` setting. It retains empty strings and the literal `?` token separately by using an explicit COPY NULL marker. The ZIP archive is retained but not imported.
- `sql/05_part3/README.md` documents the controlled setup and execution order.

The import uses the documented Psycopg 3 block-wise COPY interface and transaction rollback behavior. The importer checks COPY row counts through the cursor result after each COPY. This static implementation review is supported by the official Psycopg COPY and cursor documentation: https://www.psycopg.org/psycopg3/docs/basic/copy.html and https://www.psycopg.org/psycopg3/docs/api/cursors.html.

These are prepared repository artifacts only. No local Python execution, dry run, database creation, schema/table creation, CSV import, or P3.00 execution has been performed or claimed. The user must synchronize the latest branch, run the importer's `--dry-run`, check available storage and target-database absence, then execute the approved setup locally. P3.00 remains the first SQL diagnostic after import.


## 2026-11-24 — Part 3 setup preflight, SQL repairs, and execution tooling

The owner executed the Part 3 importer dry-run with the project virtual environment (Python 3.14.7, Psycopg 3.3.6, python-dotenv 1.2.4). All seven working CSVs passed SHA-256 and column-set validation. The command did not connect to PostgreSQL or modify a database.

The owner then verified 67.51 GB free on G:, PostgreSQL 18.6, role postgres with CREATEDB=true, oulad_analytics at 1269 MB, and no existing oulad_an8_work database. This supports the approved next step of creating the isolated work database. It does not constitute database creation or data import.

Repository inspection found that P3.03, P3.04, and P3.08 contained truncated/interleaved SQL fragments. These files were replaced with complete SELECT-only statements. P3.04 was further reduced to one student_vle aggregation and one result set at registered student-presentation grain; Notebook 11 will derive the presentation/outcome summaries from that result rather than forcing three full activity scans. P3.07 now reports duplicate candidate-key groups, registration/profile key-set differences, unmatched/multiple cohort lookups, and activity reference-match cardinality without multiplying activity rows. P3.05 adds missing assessment due-date/submission reconciliation. P3.06 includes student_vle relative-day and click fields in numeric-domain profiling.

The historical AN8.30 outputs already contain the R0/R1/R2 scenario comparison and repeated-key impact. To avoid repeating completed analysis, P3.01 was narrowed to a bounded sample of original rows from conflicting five-key groups; it no longer recomputes R0/R1/R2. P3.08 is retained as a conditional baseline query and should run only if AN8.35/AN8.36 exports do not already satisfy the reporting comparison requirement.

A new isolated runner, scripts/run_part3.py, was added. It accepts one P3 query per invocation, connects only to oulad_an8_work, enforces a read-only transaction, exports all result sets without a display cap, and writes CSVs plus an execution manifest under outputs/an8/part3/. Notebook 11 was added as a separate Python review/controlled-transformation workbench; Notebook 10 remains the AN8 Part 2 evidence record. These artifacts are prepared and have not been executed.

Updated the Part 3 plan, SQL README, notebook README, business-question roadmap wording, and progress ledger. No database was created, no source CSV was imported, no P3 query was executed, and no transformation was applied. RAW, QUALITY, STAGING, and oulad_analytics remain untouched. No Power BI, prediction, or ML work was started.

**Next work order:** synchronize feat/an8-part3-semantic-cleaning; create oulad_an8_work; create source_ref/working/audit/derived schemas and seven empty TEXT source_ref tables; run the guarded importer; execute P3.00 once; review its complete export; execute P3.07 next as the key/join gate. Continue one diagnostic at a time based on reviewed evidence.


## 2026-11-26 — Part 3 isolated database and source import; notebook-led execution

The owner returned PowerShell output confirming successful creation of `oulad_an8_work`, creation and verification of the four approved schemas, and verification of the seven initially empty `source_ref` tables. The controlled importer validated the SHA-256 hashes and source column sets for all seven working CSVs, then committed the import. Reported row counts were: courses 22; assessments 206; student_info 32,593; student_registration 32,593; student_assessment 173,912; vle 6,364; student_vle 10,655,280. The importer explicitly confirmed that no source files or other databases were modified.

Notebook 11 was revised to become the primary auditable Part 3 workflow. Its guarded setup cell creates the isolated database and schemas/tables only when absent, verifies a complete existing state, and stops on partial/unexpected state without dropping or overwriting objects. Its import cell skips an already complete expected row-count state, invokes the existing controlled importer only when all seven source tables are empty, and stops on partial counts. Notebook cells invoke the canonical read-only query runner for P3.00 and P3.07, capture process output, and load the manifest-verified CSV exports. P3.07 is gated on successful automated P3.00 checks. Canonical SQL remains under sql/05_part3; no SQL text is duplicated in the notebook.

This update records only the owner-returned database/import evidence and repository preparation. P3.00, P3.07, other P3 SQL, transformations, and derived datasets have not been executed. Notebook 10 remains the AN8 Part 2 evidence record. RAW, QUALITY, STAGING, `oulad_analytics`, and source files remain outside the approved modification scope. No Power BI or ML work was started.


## 2026-11-26 — Part 3 retained-output review and notebook validation repair

Notebook 11 retained outputs were reviewed against the canonical P3 SQL. P3.02 shows a 20:30:12 UTC read-only runner execution (130.256 seconds), with five temporal field profiles, 200 boundary examples, and 22 presentation summaries. The reviewed temporal distribution contains 688,988 negative VLE offsets (6.466%), 76,643 day-zero rows (0.719%), and 9,889,649 positive rows (92.815%). The maximum VLE offset equals the recorded presentation length in all 22 presentations. Negative values remain valid pre-start activity; day zero and day L remain separately identified boundaries.

P3.05's retained runner output is dated 20:33:18 UTC (2.782 seconds) and contains four result sets: 1,927 row-level -1 records; 18 grouped score/date/banked states, with the -1 group summing to 1,927; zero duplicate assessment-student keys; and 11 assessments with missing due dates. The row-level and grouped -1 counts agree. An earlier note calling this a discrepancy was incorrect and is superseded. The current canonical P3.05 SQL adds a fifth source-grain reconciliation result set; that fifth result is absent from the retained four-set output. The meaning of -1 remains unresolved and no recoding is approved.

The notebook review also found that a later duplicate definition of `load_or_execute_part3_query` overrode the SQL-hash-aware loader. This could load a historical manifest without validating the current SQL hash. Notebook 11 was corrected to retain one hash-aware loader, to label stale exports explicitly in the historical review path, and to clear affected query/review outputs so they cannot be mistaken for validated current evidence. Notebook JSON parsing and unique cell IDs were checked after the edit. No PostgreSQL execution, data modification, or persistent object creation was performed as part of this repository correction.


## 2026-11-27 — Assessment transfer, deadline, and opportunity analysis prepared

The retained P3.05 output was examined beyond the overall `date_submitted = -1` total. Of 1,927 such records, 1,909 are marked `is_banked = 1` and 18 are marked `is_banked = 0`. The banked concentration is consistent with transferred results from previous presentations; it does not establish a current-presentation submission date. The 18 non-banked records (11 CMA and 7 TMA) remain unresolved. The grouped P3.05 output also identifies 130 other negative-day records below -1: 59 CMA, 70 TMA, and one TMA missing-score case. These require contextual review, not automatic conversion to missing or zero.

The same retained output identifies 11 Exam assessment catalogue rows with missing due dates. Student-assessment links exist for three of these items (747 records in CCC 2014B, 1,168 in CCC 2014J, and 950 in DDD 2014J); the other eight show no linked records. Because the deadline is unknown, these items cannot enter a due-date-based timeliness denominator without a separate documented rule. Their missing due dates and recorded result coverage must be disclosed separately.

Added P3.09 as a SELECT-only diagnostic with five outputs: assessment catalogue/weights, per-assessment score/banked/date/deadline states, all -1 records linked to registration and outcome context, all negative days by banked/score/type, and candidate eligible populations per assessment. The provisional opportunity population is registered on/before a known due day and not withdrawn before that day; withdrawals on the due day and unknown registration dates remain separate. The query distinguishes banked transfers from non-banked results and reconciles current non-banked result coverage against the candidate population.

Extended the canonical runner to accept P3.09 and added a guarded execution cell and business interpretation in Notebook 11. Updated the Part 3 README and analysis plan. Static inspection and notebook JSON parsing/unique-cell-ID checks were performed. No PostgreSQL execution, local notebook execution, source modification, data transformation, or persistent derived object creation is claimed. P3.09 results and denominator validity remain pending local read-only execution and review.

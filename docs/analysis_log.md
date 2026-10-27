# Analysis Log — OULAD EdTech Learning Analytics

**Project Owner & Lead Analyst:** Abdeljalil El Khyati  
**Last updated:** 2026-10-25

This log preserves major project decisions and validated results. Exploratory one-off queries that did not result in a decision are not repeated here. Exact historical execution timestamps were not captured for the quality registry; no timestamps are reconstructed.

| Date | Stage | Question / Decision | Evidence | Result | Decision | Next action |
|---|---|---|---|---|---|---|
| 2026-09-29 | Project setup | Should SQL and Python have separate responsibilities? | Project architecture | SQL relational work is central; Python complements it | PostgreSQL is the analytical backbone; use Python where justified | Set up PostgreSQL, Python environment, and notebooks |
| 2026-10-03 | Data ingestion | How to avoid path errors and unnecessary repeat downloads? | Notebook current working directory can differ; source archive is large | Relative-path risk and unnecessary re-extraction identified | Resolve paths from project location and skip existing files when safe | Validate source files and profiling results |
| 2026-10-04 | Phase 1.5 | Is `(code_module, code_presentation, id_student, id_site, date)` unique in `student_vle`? | Candidate-key profiling | 10,655,280 rows; 8,459,320 distinct candidate keys; 2,195,960 excess rows | Do not impose a primary key on `raw.student_vle`; preserve rows | Characterize repeat patterns without deleting records |
| 2026-10-04 | Phase 2A | Which RAW types and nullability are justified by source values? | Header, missing-token, and type profiling | Decimal assessment weights; `?` tokens in several source fields; all seven headers matched | Use `NUMERIC` for weight; keep source fields with `?` as nullable text where needed | Create RAW tables |
| 2026-10-06 | Phase 2B | Can seven RAW tables be created while preserving source representation? | Validated Phase 2A findings | Seven tables created in `raw` | No business cleaning, aggregation, deduplication, or foreign-key transformation in RAW | Load source files |
| 2026-10-06 | Phase 2C | Did PostgreSQL `COPY` load the source tables? | `COPY` execution and row-count reconciliation | Seven source tables loaded; counts matched baseline | Accept RAW load and preserve the data as loaded | Investigate repeated `student_vle` keys |
| 2026-10-14 | Phase 2D / B2 | What do repeated `student_vle` keys look like? | Repeated-key group, sum_click variation, full-row duplicate, and group-size queries | 1,614,505 repeated-key groups; 3,810,465 rows within those groups; 2,195,960 excess rows; max group size 10 | Repetition cause and intended grain remain unresolved; do not deduplicate or aggregate | Carry the limitation into analytical grain and metric design |
| 2026-10-14 | B2/B3 | Are candidate keys and tested parent/reference relationships valid? | Candidate-key and relationship checks | Six other table keys passed; all tested parent/reference checks had zero unmatched rows | Keep the `student_vle` key at `REVIEW`; retain other tested key/reference results | Maintain a quality registry |
| 2026-10-14 | B4/B5 | Can quality findings be recorded consistently? | Registry inspection and seed execution results | Registry has 29 records and 29 distinct test codes: 25 `PASS`, 4 `REVIEW`; no duplicate codes in latest check | Keep historical `executed_at` values NULL because the exact execution times were not recorded | Use the registry for findings; do not rerun seed inserts without checking existing codes |
| 2026-10-14 | B5 / completeness and values | Are missing tokens, score bounds, clicks, weights, and categorical values understood? | RAW completeness, numeric-range, categorical-distribution, and domain-validation queries | Known missingness appears as `?`; numeric checks were within the tested bounds; categorical-domain query returned no rows outside tested lists | Record missingness and observed domains; do not infer that a distribution alone proves domain compliance | Preserve interpretation caveats in the phase-closure report and data dictionary |
| 2026-10-14 | B5 / temporal diagnostics | Are date-like values necessarily errors when negative or after listed dates? | Registration order, submission timing, relative VLE day, and week-range checks | No unregistration-before-registration rows; 19 same-day cases; 49,318 submissions after the listed assessment day; 688,988 negative relative VLE days; no VLE days beyond presentation length; no reversed numeric week ranges | Treat the results as diagnostics. Negative relative days, same-day cases, and later submissions are not automatic errors | Leave these questions documented for analytical interpretation |
| 2026-10-14 | C2 | Are selected RAW values safe to convert to typed STAGING columns? | Conversion pre-check queries | No unexpected nonnumeric values in the tested conversion fields; source token and observed ranges were recorded | Convert the documented fields only in STAGING, not RAW | Create typed STAGING tables |
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

## Current gate

The core data-engineering implementation and the reported C2 / S1–S4 checks are complete. The four current registry items with `REVIEW` status are described in `docs/data_engineering_phase_closure.md`. No analytical model, KPI result, dashboard finding, predictive model, or business recommendation has been produced yet.


## Analytical phase preparation — WO-1

| Date | Stage | Question / Decision | Evidence | Result | Decision | Next action |
|---|---|---|---|---|---|---|
| 2026-10-25 | WO-1 preparation | How should analytical SQL be executed and reviewed without duplicating SQL or rerunning engineering checks? | Repository inspection of the existing analytics notebook, `.env.example`, environment-test notebook, SQL conventions, and documentation | Prepared a dedicated work branch with canonical AN0/AN1/AN2 diagnostic SQL, a read-only query helper, an updated SQL analytics notebook, and a runbook. No local database query has been executed by this preparation step. | Keep all changes on `work/wo-1-analytical-readiness`; do not treat planned outputs as findings. Preserve the main branch and await local execution evidence. | Run the notebook locally, review outputs and query timings, interpret deviations, then update this log with verified findings and decisions. |


## Analytical readiness evidence and WO-1B rationale

| Date | Stage | Question / Decision | Evidence | Result | Decision | Next action |
|---|---|---|---|---|---|---|
| 2026-10-27 | WO-1 / AN1.01 | Are student-presentation keys complete and unique in both student tables? | Previously returned output from `notebooks/04_sql_analytics.ipynb`, shared for review | Both `staging.student_info` and `staging.student_registration` contain 32,593 rows and 32,593 distinct composite keys `(code_module, code_presentation, id_student)`; no NULL key components or duplicate key groups were reported. | Preserve the three-column key for student-presentation joins. | Validate cardinality for additional relationships. |
| 2026-10-27 | WO-1 / AN1.02 | Do the profile and registration key sets reconcile? | Previously returned notebook output, shared for review | The tables share 32,593 complete composite keys with zero one-sided keys. Each contains 28,785 distinct student IDs. | Distinguish people from student-presentation records; the difference between these counts is not a count of distinct people with multiple registrations. | Preserve the declared grain in denominators and labels. |
| 2026-10-27 | WO-1 / AN1.03 | Does joining assessment rows to student profiles by student ID alone inflate row counts? | Previously returned notebook output, shared for review | The 173,912 source rows become 207,319 rows under the student-only join (+33,407; 19.21%). The constrained path through assessment metadata and matching module/presentation returned 173,912 rows, with no unmatched records reported in the tested path. | Do not join assessment records to student profiles by `id_student` alone. | Validate join cardinality in subsequent assessment analyses. |
| 2026-10-27 | WO-1 / AN2.01 | Do profile and registration counts reconcile by presentation? | Previously returned notebook output, shared for review | Counts reconciled across 22 presentations and 32,593 student-presentation rows. | Treat these as presentation-level records, not unique people across the dataset. | Preserve grain in outcome and engagement analysis. |
| 2026-10-27 | WO-1 / AN2.02 | What is the final-result distribution by presentation? | Previously returned notebook output, shared for review | The query produced 88 rows, but the shared excerpt showed only the first and last five rows. | Do not publish detailed comparisons from the abbreviated excerpt. | Review the retained full result before reporting the distribution. |
| 2026-10-27 | WO-1B preparation | Why extend the existing diagnostics? | Review of existing outputs, documented table grains, and unresolved analytical questions | The existing checks do not yet cover course/assessment relationship cardinality, registration-matched VLE activity, registrations without recorded activity, resource-metadata coverage, or selected profile distributions and IMD missingness. | Prepare focused read-only diagnostics without repeating completed checks or changing RAW/STAGING. | Review the proposed AN1.04–AN1.09 and AN2.03–AN2.09 definitions against the current branch and schema before execution. |
| 2026-10-27 | WO-1B execution controls | How can potentially heavy diagnostics run without weakening safeguards? | Review of `src/analytics/db.py` and the proposed timeout extension | The runner currently sets a 120,000 ms statement timeout, a 5,000 ms lock timeout, and a read-only session. The optional longer timeout is a control change, not evidence that any query has executed successfully. | Retain the default and lock timeout; use a longer timeout only when explicitly requested for selected heavy queries. | Test runner behavior locally and record query ID, elapsed time, displayed rows, truncation, and errors. |

| 2026-10-27 | WO-1B static SQL review | Do the relationship diagnostics distinguish source-row counts from joined-row counts when fan-out occurs? | Static review of the prepared AN1.04 and AN1.05 SQL definitions; no database execution | The first draft calculated the displayed source-row count after the LEFT JOIN, which could conceal fan-out in the multiplier. The definitions were corrected to count source rows before joining and report joined-row counts separately. | Keep source cardinality and join cardinality separate in every diagnostic; treat this as a code-review correction, not a data finding. | Recheck the definitions after local synchronization; execute only after the notebook integration is reviewed. |

### Evidence boundary

The AN1.01–AN1.03 and AN2.01–AN2.02 entries summarize previously returned notebook outputs shared for review; this documentation update did not execute SQL against PostgreSQL. WO-1B diagnostics remain prepared until local execution outputs are returned and interpreted. No RAW or STAGING data was modified, deleted, deduplicated, or aggregated by this work.

# Analysis Log — OULAD EdTech Learning Analytics

**Project Owner & Lead Analyst:** Abdeljalil El Khyati  
**Last updated:** 2026-10-30

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

## Current gate

The core data-engineering implementation and the reported C2 / S1–S4 checks are complete. The four current registry items with `REVIEW` status are described in `docs/data_engineering_phase_closure.md`. No analytical model, KPI result, dashboard finding, predictive model, or business recommendation has been produced yet.


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

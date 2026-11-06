# AN5 — Engagement Sensitivity Analysis Plan

**Project:** OULAD — EdTech Learning Analytics  
**Workstream:** AN5 — Engagement Sensitivity  
**Status:** Five canonical SQL investigations executed in the saved local notebook; interpretation review and AN5 exit decision pending  
**Primary source:** `staging.student_vle`  
**Related sources:** `staging.student_registration`, `staging.courses`, `staging.vle`  
**Execution model:** PostgreSQL, read-only, canonical SQL files invoked through `src/analytics/db.py`

## 1. Purpose and decision to be supported

AN5 evaluates how alternative treatments of repeated `student_vle` records affect candidate recorded-activity measures. Its purpose is not to clean the source table or select the scenario that produces the most convenient result. It establishes whether conclusions about recorded click volume and activity presence are robust to the documented repetition patterns.

AN5 is an investigative sensitivity work order. It does not approve a production KPI, causal interpretation, engagement-quality score, or predictive feature.

## 2. Evidence baseline and unresolved semantics

The historical source profile contains 10,655,280 `student_vle` rows and 8,459,320 distinct five-column candidate-key combinations:

`(code_module, code_presentation, id_student, id_site, date)`

The profile also recorded:

- 2,195,960 excess rows relative to distinct five-column keys.
- 1,614,505 repeated-key groups containing 3,810,465 rows.
- 435,431 repeated-key groups with one distinct `sum_click` value.
- 1,179,074 repeated-key groups with multiple `sum_click` values.
- 642,613 groups identical across all six columns, accounting for 787,170 excess identical rows.
- Maximum repeated-key group size: 10.

These values are historical profiling evidence, not fresh counts from the AN5 execution. Different `sum_click` values within the same five-column key mean that R2 is a sensitivity assumption, not a recovered source truth.

## 3. Analytical question and provisional measures

**Primary question:** How much do recorded click volume and recorded activity-presence measures change when repeated source rows are handled under R0, R1, and R2?

The core comparison includes:

1. Recorded click volume: sum of `sum_click` within the scenario.
2. Distinct active days: count of distinct eligible course-relative dates with at least one scenario record.
3. Active resource breadth: count of distinct `id_site` values with at least one scenario record.
4. Activity-bearing student-presentations: count and share of eligible student-presentations with at least one scenario record.
5. Recorded activity rows and scenario-specific row counts, reported as diagnostics rather than independent learning events.
6. Student-presentation ranking sensitivity within each module-presentation, including average-rank Spearman correlation, absolute rank displacement, and top-decile overlap.
7. Outcome-group activity profiles within each module-presentation, retaining registered student-presentations with no activity and explicitly diagnosing profile-match problems.

Click volume is a platform-recorded count, not a measure of learning quality, attention, comprehension, or academic success. Distinct days and resource breadth are presence measures; they do not establish intensity or quality.

## 4. Scenario definitions

All scenarios are virtual query transformations. They must not write to RAW or STAGING.

| Scenario | Rule | Interpretation |
|---|---|---|
| R0 | Retain every recorded `student_vle` row. | Source-row baseline; preserves all repeated and fully identical records. |
| R1 | Collapse exact duplicates across all six columns, retaining one copy of each distinct six-column tuple. | Tests sensitivity to fully identical row repetition only. |
| R2 | Group by the five-column candidate key and retain `MAX(sum_click)`. | Tests a conservative maximum-per-key alternative; does not claim that maximum is the true source value. |

R1 must not remove rows that share the five-column key but have different `sum_click` values. R2 must not be described as deduplication of exact rows or as a validated business rule.

## 5. Grain, population, and join design

### 5.1 Primary output grain

The primary analytical output grain is one `(code_module, code_presentation, id_student)` student-presentation.

The candidate activity scenarios are aggregated to that grain before joining to the registered population. The registration population is built independently from `staging.student_registration` and must reconcile to its student-presentation key.

### 5.2 Join path

Join activity to registration using all three columns:

`code_module, code_presentation, id_student`

Do not join on `id_student` alone. Preserve registered student-presentations with no matching activity row through a LEFT JOIN. Report unmatched registration records separately rather than silently dropping them.

### 5.3 Denominators

Use the same registered student-presentation population as the common denominator for all three scenarios:

- Eligible registered student-presentations.
- Activity-bearing student-presentations under each scenario.
- No-recorded-activity student-presentations under each scenario.
- Coverage share = activity-bearing registered student-presentations / all eligible registered student-presentations.

Report row counts and distinct `id_student` counts separately. A person may appear in multiple presentations; student-presentation counts are not unique-person counts.

Any unmatched activity-to-registration records must be reported separately and excluded from the registered-population numerator/denominator unless a later documented decision defines another population. Do not hide unmatched activity.

## 6. Time basis and negative relative dates

OULAD `student_vle.date` is a course-relative day value. Historical profiling recorded 688,988 negative values, with an observed range from -25 to 269; no rows beyond the corresponding presentation length were reported in that check.

The primary sensitivity summary must separate:

- Pre-course activity: `date < 0`.
- In-course activity: `date >= 0 AND date <= module_presentation_length`.
- Post-course activity: `date > module_presentation_length`.

Do not discard negative dates silently. Report them as a separate temporal category and provide both all-recorded and in-course-only measures where appropriate. The course-relative date is not a calendar date. Do not infer the cause or operational meaning of pre-course records from the numeric sign alone.

## 7. Missing-match and zero-activity semantics

Keep the following states distinct:

- Registered student-presentation with one or more matching activity rows.
- Registered student-presentation with no matching activity row under the scenario.
- Activity records with no matching registration key.
- Registration records with missing key components, if any are found during the read-only diagnostic.

A missing activity match means no row was found in the tested source under the specified join. It does not prove no learning, no engagement outside the platform, or no unrecorded interaction.

## 8. Required validation and reconciliation

Before interpreting scenario differences, validate:

1. Source row counts and five-column key counts against the historical baseline when feasible; treat differences as a stop-and-investigate condition, not as automatic failure.
2. R0 row count equals the input `student_vle` row count.
3. R1 has one row per distinct six-column tuple.
4. R2 has at most one row per five-column candidate key.
5. R1 retains different `sum_click` values under a shared five-column key.
6. Each scenario aggregate has exactly one row per student-presentation.
7. Scenario aggregation does not multiply registration rows.
8. The common registered denominator is identical across R0/R1/R2.
9. Activity-bearing plus no-recorded-activity student-presentations reconcile to the eligible registered population.
10. Unmatched activity-to-registration records are counted separately.
11. Negative, in-course, and post-course date buckets reconcile to scenario row counts.
12. Click sums, active-day counts, and resource counts are non-negative and use explicit NULL handling.

Do not load the full `student_vle` table into Pandas. Use SQL aggregation and bounded result sets. Avoid concurrent large scans; execute any high-cost scenario scan in a controlled sequence with a suitable statement timeout.

## 9. Query package and deliverables

The following canonical SQL files have been prepared under `sql/04_analytics/`:

- `AN5.01_student_vle_scenario_reconciliation.sql` — scenario row counts, duplicate/key invariants, and common registration-population reconciliation.
- `AN5.02_student_presentation_activity_sensitivity.sql` — R0/R1/R2 click, active-day, resource-breadth, and activity-presence comparisons.
- `AN5.03_temporal_activity_sensitivity.sql` — pre-course, in-course, and post-course sensitivity by scenario.
- `AN5.04_student_ranking_sensitivity.sql` — within-presentation average-rank correlation, rank displacement, and tie-inclusive top-decile overlap across scenario pairs.
- `AN5.05_outcome_group_activity_sensitivity.sql` — scenario-sensitive activity profiles by final-result group, plus registration-to-profile match diagnostics.

Each SQL file must include the required headers: Question, Expectation, Grain, Source, Safety, Runtime, and Read as. All statements must be read-only SELECT queries. No temporary or persistent database objects are required by this design.

The work-order notebook is `notebooks/07_an5_engagement_sensitivity.ipynb`; `scripts/run_an5.py` is the command-line execution entry point. Both invoke canonical SQL through `src/analytics/db.py`, preserve all returned result sets, and report runtime and truncation metadata. The notebook follows WO-1's direct-cell style: after a successful read-only preflight, each query cell executes directly without an interactive authorization prompt or per-query approval. Run cells individually from top to bottom; do not use Run All. The Python script executes selected queries sequentially after its own fresh preflight and can optionally export bounded CSV result sets and a non-sensitive JSON manifest. The existing `notebooks/06_final_findings_and_recommendations.ipynb` remains a separate final-report placeholder and is not repurposed.

## 10. Additional AN5 analyses

### 10.1 AN5.04 — Student ranking sensitivity

Rank registered student-presentations by recorded click volume separately within each module-presentation and scenario. Zero-activity registrations remain in the ranking population. Average ranks are used for Spearman correlation. Report pairwise rank correlation, mean/median/90th-percentile/maximum absolute rank displacement, and top-decile overlap using a tie-inclusive cutoff. Because ties can cross the cutoff, the top-decile set may contain more than exactly 10% of the population. Ranking stability is descriptive and does not establish that click volume is a valid engagement or risk measure.

### 10.2 AN5.05 — Outcome-group activity sensitivity

Compare scenario-specific activity coverage, recorded clicks, active-day pairs, and active-site pairs across `final_result` groups within each module-presentation. The population begins with registered student-presentations, including those with no matching activity (zero-filled only for these explicitly defined measures). Join to `student_info` on the complete composite key. Collapse profile records to a diagnostic one-row-per-key map before joining so duplicates cannot multiply metrics; classify missing, duplicate, conflicting, and NULL outcome matches explicitly. The second result set reports these key-match diagnostics. `final_result` is a retrospective grouping variable, not a predictor, and subgroup differences are descriptive rather than causal. Flag groups below 100 registered student-presentations; inspect individual cells as well as the flag.

## 11. Interpretation framework

For each measure, report:

- R0, R1, and R2 values.
- Absolute and percentage differences against R0.
- Scenario-specific row counts.
- The common eligible denominator and activity-bearing numerator.
- Student-presentation counts and distinct-person counts separately.
- The contribution of pre-course records.
- Module/presentation variation and small-denominator warnings.
- Any join mismatch or reconciliation exception.

A scenario difference is sensitivity evidence, not proof that one scenario is correct. Do not infer causal effects or label a higher click total as better engagement.

## 12. Exit criteria and next-stage gate

AN5 can close only when:

- All three scenario definitions are implemented in read-only SQL.
- Grain, join cardinality, row counts, and common denominators reconcile.
- Temporal categories are explicit and reconcile.
- Differences between R0/R1/R2 are quantified and interpreted with assumptions and limitations.
- The project owner has reviewed the returned outputs and the interpretation.
- The approved activity definition, if any, is explicitly documented for AN6; otherwise AN6 must retain multiple measures or remain gated.

AN5 closure does not approve a KPI, analytical mart, Power BI output, predictive feature, or causal claim. AN6 may begin only after the activity definition and its limitations have been accepted.

## 13. Safety

- READ-ONLY SQL only.
- No changes to RAW, QUALITY, or STAGING.
- No DELETE, UPDATE, INSERT, CTAS, index creation, constraint creation, view creation, or persistent table creation.
- No blind deduplication or source-row replacement.
- No full-table Pandas load.
- No claims of query execution until actual local PostgreSQL outputs are returned and reviewed.


## 14. Repository preparation status

AN5.01–AN5.05, `scripts/run_an5.py`, and the direct-cell notebook are prepared on `work/an5-five-query-execution`. They are prepared artifacts, not executed analysis. Local synchronization and a successful read-only preflight remain required before execution. The notebook intentionally follows WO-1's direct-cell pattern; it does not prompt for per-query approval, and it must be run cell by cell rather than with Run All.

## 15. First execution evidence and interpretation status — 2026-11-06

The project owner returned the saved execution outputs from `notebooks/07_an5_engagement_sensitivity.ipynb`. The notebook evidence records a successful AN0.01 read-only preflight against `oulad_analytics` on PostgreSQL 18.6, with both read-only settings enabled.

All five canonical SQL files executed and returned the expected eight result sets:

| Query | Result-set row counts | Batch elapsed seconds |
|---|---:|---:|
| AN5.01 | 1, 3, 66 | 660.747 |
| AN5.02 | 69 | 268.471 |
| AN5.03 | 132 | 456.240 |
| AN5.04 | 66 | 70.314 |
| AN5.05 | 264, 22 | 282.843 |
| **Total** | **623 displayed rows** | **1,738.615** |

No runner-level result-set truncation or saved SQL traceback is recorded. The elapsed values are SQL-file batch durations, not per-statement timings or total notebook wall-clock time.

### Initial findings supported by saved outputs

- **AN5.01:** 10,655,280 R0 rows; 9,868,110 distinct six-column tuples for R1; and 8,459,320 five-column candidate keys for R2. The profile reports 787,170 excess fully identical rows, 1,179,074 five-column key groups with multiple `sum_click` values, and a maximum key-group size of 10. R1 is 7.39% below R0; R2 is 20.61% below R0. These are sensitivity scenarios, not source corrections.
- **AN5.02:** the visible R0 overall row contains 32,593 registered student-presentations, 28,785 distinct students, 29,228 activity-bearing student-presentations, 3,365 without a matching activity row, and 89.68% recorded-activity coverage. It reports 39,605,099 recorded clicks, 1,808,119 student-active-day pairs, and 1,960,496 student-active-site pairs. Student-presentation counts must not be described as unique-person counts.
- **AN5.03:** the visible AAA 2013J R0 rows include 10,847 pre-course activity rows (49,623 recorded clicks) and 170,135 in-course rows (598,871 recorded clicks). Negative relative days remain a separate category; their cause is not established by the extract.
- **AN5.04:** visible examples show high rank correlation alongside material individual rank changes. AAA 2013J R0/R1 has correlation 0.999703 while 276 of 383 student-presentations change rank. GGG 2014B R0/R2 has correlation 0.998118, mean absolute rank change 10.42, and top-decile Jaccard overlap 0.8876. Correlation alone is not sufficient evidence of operational ranking stability.
- **AN5.05:** 264 outcome-group rows were returned. The visible groups include small cohorts; final result remains a retrospective descriptive label, not a predictor. All 22 rows in the profile-match diagnostic show one unique profile match per registered key and zero reported missing, duplicate, or conflicting profile matches in this extract.

### Display and review limitation

The SQL runner did not truncate any result set at its 500-row cap. However, the saved pandas HTML representations abbreviate longer DataFrames to leading and trailing rows. Consequently, complete cross-scenario totals and full presentation-level extrema must be derived from the retained in-memory DataFrames or complete CSV exports, not inferred from the abbreviated HTML display.

Interpretation Markdown was added below each query output. A Python-only review cell was also added to calculate scenario deltas, denominator invariants, temporal summaries, ranking ranges, outcome-group summaries, and profile-match totals from the already-retained DataFrames. It exports complete bounded result sets to the ignored local `outputs/an5/` folder and explicitly reports that no SQL is rerun. This new review/export cell has not yet been executed.

### Current decision

The five SQL investigations are executed, but AN5 is **not yet closed**. Do not add another SQL scan at this point. First run the new Python-only review/export cell while the existing notebook kernel still retains `query_results`; inspect its complete summary tables and CSV exports. If the kernel has been restarted, stop rather than rerunning the expensive SQL automatically, because the abbreviated notebook display does not reconstruct every full DataFrame.

No activity KPI, source deduplication rule, causal interpretation, predictive feature, or operational intervention is approved. AN6 and AN7 remain separate roadmap stages.

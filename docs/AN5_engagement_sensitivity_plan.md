# AN5 — Engagement Sensitivity Analysis Plan

**Project:** OULAD — EdTech Learning Analytics  
**Workstream:** AN5 — Engagement Sensitivity  
**Status:** Design specification; SQL execution not started  
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

The initial comparison will include:

1. Recorded click volume: sum of `sum_click` within the scenario.
2. Distinct active days: count of distinct eligible course-relative dates with at least one scenario record.
3. Active resource breadth: count of distinct `id_site` values with at least one scenario record.
4. Activity-bearing student-presentations: count and share of eligible student-presentations with at least one scenario record.
5. Recorded activity rows and scenario-specific row counts, reported as diagnostics rather than independent learning events.

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

Prepare separate canonical SQL files under `sql/04_analytics/`:

- `AN5.01_student_vle_scenario_reconciliation.sql` — scenario row counts, duplicate/key invariants, and common registration-population reconciliation.
- `AN5.02_student_presentation_activity_sensitivity.sql` — R0/R1/R2 click, active-day, resource-breadth, and activity-presence comparisons.
- `AN5.03_temporal_activity_sensitivity.sql` — pre-course, in-course, and post-course sensitivity by scenario.

Each SQL file must include the required headers: Question, Expectation, Grain, Source, Safety, Runtime, and Read as. All statements must be read-only SELECT queries. No temporary or persistent database objects are required by this design.

The work-order notebook should orchestrate canonical SQL without duplicating SQL text, preserve all result sets, record query hashes/runtime/truncation, and place interpretation checkpoints after outputs. The notebook path should be selected after inspecting the existing notebook inventory; do not create a duplicate orchestration notebook.

## 10. Interpretation framework

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

## 11. Exit criteria and next-stage gate

AN5 can close only when:

- All three scenario definitions are implemented in read-only SQL.
- Grain, join cardinality, row counts, and common denominators reconcile.
- Temporal categories are explicit and reconcile.
- Differences between R0/R1/R2 are quantified and interpreted with assumptions and limitations.
- The project owner has reviewed the returned outputs and the interpretation.
- The approved activity definition, if any, is explicitly documented for AN6; otherwise AN6 must retain multiple measures or remain gated.

AN5 closure does not approve a KPI, analytical mart, Power BI output, predictive feature, or causal claim. AN6 may begin only after the activity definition and its limitations have been accepted.

## 12. Safety

- READ-ONLY SQL only.
- No changes to RAW, QUALITY, or STAGING.
- No DELETE, UPDATE, INSERT, CTAS, index creation, constraint creation, view creation, or persistent table creation.
- No blind deduplication or source-row replacement.
- No full-table Pandas load.
- No claims of query execution until actual local PostgreSQL outputs are returned and reviewed.

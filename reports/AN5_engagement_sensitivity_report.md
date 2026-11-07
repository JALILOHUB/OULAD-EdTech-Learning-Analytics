# AN5 — Engagement Sensitivity Analysis Report

**Project:** OULAD — EdTech Learning Analytics  
**Workstream:** AN5 — Engagement Sensitivity  
**Evidence:** Saved local PostgreSQL outputs in `notebooks/07_an5_engagement_sensitivity.ipynb`  
**Database recorded in preflight:** `oulad_analytics`, PostgreSQL 18.6  
**Status:** Five-query execution and quantitative review documented; formal AN5 closure pending owner acceptance

## 1. Executive summary

AN5 tested how repeated records in `staging.student_vle` affect recorded activity measures through three read-only sensitivity scenarios. Five canonical SQL investigations returned eight result sets containing 623 rows. The saved preflight confirmed the intended database and read-only session settings. No runner-level row-cap truncation or SQL traceback was recorded.

The central finding is that **recorded click volume and activity-row counts change materially with repeated-row treatment, while the registered population, activity coverage, student-active-day pairs, and student-active-site pairs remain invariant across R0, R1, and R2**. Ranking analysis also shows that high overall rank correlation does not guarantee stable membership in a selected top-decile group.

AN5 does not establish which scenario represents source truth. It does not approve a source-cleaning rule, engagement KPI, causal explanation, or predictive feature. RAW and STAGING remain unchanged.

## 2. Purpose, grain, and scenarios

The five-column candidate key `(code_module, code_presentation, id_student, id_site, date)` is not unique. AN5 tests the effect of that repetition without altering the source. The primary population grain is one registered student-presentation: `(code_module, code_presentation, id_student)`.

| Scenario | Query treatment | Interpretation |
|---|---|---|
| R0 | Retain all source activity rows. | Row-preserving baseline. |
| R1 | Retain one copy of each exact six-column tuple. | Sensitivity to fully identical repetition only. |
| R2 | Retain `MAX(sum_click)` per five-column candidate key. | One-row-per-key maximum-value alternative; not validated source truth. |

R1 retains records sharing a five-column key when their click values differ. R2 is not an approved deduplication or business rule.

## 3. Execution evidence

The saved AN0.01 preflight records `oulad_analytics`, PostgreSQL 18.6, `transaction_read_only=on`, `default_transaction_read_only=on`, a 2-minute statement timeout, and a 5-second lock timeout.

| Query | Result-set row counts | Batch elapsed seconds |
|---|---:|---:|
| AN5.01 | 1, 3, 66 | 660.747 |
| AN5.02 | 69 | 268.471 |
| AN5.03 | 132 | 456.240 |
| AN5.04 | 66 | 70.314 |
| AN5.05 | 264, 22 | 282.843 |
| **Total** | **623** | **1,738.615** |

The duration is the sum of SQL-file batch timings, not total notebook runtime or per-statement timing. The runner reported no result-set truncation. Because pandas HTML abbreviates long tables, the Python-only review cell calculated summaries from retained result frames and exported complete bounded result sets to the local Git-ignored `outputs/an5/` directory. The review and plotting cells did not reconnect to PostgreSQL or rerun SQL.

## 4. Findings

### 4.1 AN5.01 — Repeated-record profile and reconciliation

| Profile measure | Result |
|---|---:|
| R0 source rows | 10,655,280 |
| Distinct five-column keys | 8,459,320 |
| Distinct six-column tuples | 9,868,110 |
| Repeated-key groups | 1,614,505 |
| Rows in repeated-key groups | 3,810,465 |
| Excess rows over five-column keys | 2,195,960 |
| Groups with multiple `sum_click` values | 1,179,074 |
| Maximum key-group size | 10 |
| Fully identical groups | 642,613 |
| Excess fully identical rows | 787,170 |

| Scenario | Rows | Reduction vs R0 |
|---|---:|---:|
| R0 | 10,655,280 | 0.00% |
| R1 | 9,868,110 | 7.39% |
| R2 | 8,459,320 | 20.61% |

All scenarios reconcile across 22 module-presentations to 32,593 registered student-presentations. Each reports 29,228 activity-bearing student-presentations and zero unmatched activity student-presentations or rows in the tested reconciliation.

**Interpretation:** exact six-column duplicates explain only part of the repeated-key pattern. The 1,179,074 groups with multiple click values mean R2 cannot be treated as recovered source truth. Neither R1 nor R2 is approved as a source correction.

### 4.2 AN5.02 — Activity measures under R0/R1/R2

The common denominator is 32,593 registered student-presentations, representing 28,785 distinct students.

| Measure | R0 | R1 | R2 |
|---|---:|---:|---:|
| Activity rows | 10,655,280 | 9,868,110 | 8,459,320 |
| Recorded clicks | 39,605,099 | 38,343,063 | 34,402,738 |
| Click change vs R0 | 0.00% | -3.19% | -13.14% |
| Activity-row change vs R0 | 0.00% | -7.39% | -20.61% |
| Activity-bearing student-presentations | 29,228 | 29,228 | 29,228 |
| Student-presentations without activity | 3,365 | 3,365 | 3,365 |
| Activity coverage | 89.68% | 89.68% | 89.68% |
| Student-active-day pairs | 1,808,119 | 1,808,119 | 1,808,119 |
| Student-active-site pairs | 1,960,496 | 1,960,496 | 1,960,496 |

All eight tested population/presence invariants were true across scenarios.

**Interpretation:** click volume and activity-row counts are sensitive to repeated-row treatment; presence, active days, and resource breadth are stable in this comparison. These remain recorded-platform measures, not direct measures of learning quality. A missing activity match does not prove that no learning occurred.

### 4.3 AN5.03 — Temporal activity

| Scenario | Bucket | Activity rows | Recorded clicks |
|---|---|---:|---:|
| R0 | IN_COURSE | 9,966,292 | 37,457,152 |
| R0 | PRE_COURSE | 688,988 | 2,147,947 |
| R1 | IN_COURSE | 9,210,950 | 36,250,422 |
| R1 | PRE_COURSE | 657,160 | 2,092,641 |
| R2 | IN_COURSE | 7,859,079 | 32,494,875 |
| R2 | PRE_COURSE | 600,241 | 1,907,863 |

Under R0, pre-course activity represents approximately 6.47% of rows and 5.42% of clicks. The output contains 22 module-presentations per scenario and PRE_COURSE/IN_COURSE buckets; no POST_COURSE rows were returned. Sums of presentation-level distinct counts are not unique totals across the dataset.

**Interpretation:** PRE_COURSE means `student_vle.date < 0` relative to presentation start. It does not establish that activity preceded each student's personal registration. Negative relative days remain visible pending a documented interpretation.

### 4.4 AN5.04 — Ranking sensitivity

Each scenario comparison covers 22 module-presentations and 32,593 paired student-presentations.

| Comparison | Median Spearman | Rank changes | Share with rank change | Median top-decile Jaccard | Minimum Jaccard |
|---|---:|---:|---:|---:|---:|
| R0 vs R1 | 0.999850 | 26,871 | 82.44% | 0.97710 | 0.9200 |
| R0 vs R2 | 0.998870 | 28,195 | 86.51% | 0.91565 | 0.8286 |
| R1 vs R2 | 0.999205 | 27,858 | 85.47% | 0.91930 | 0.8462 |

Five lowest top-decile overlaps:

| Module-presentation | Comparison | Spearman | Mean absolute rank change | Maximum change | Jaccard |
|---|---|---:|---:|---:|---:|
| GGG 2013J | R0/R2 | 0.997586 | 13.35 | 89.0 | 0.8286 |
| GGG 2013J | R1/R2 | 0.998331 | 10.81 | 102.5 | 0.8462 |
| BBB 2014B | R0/R2 | 0.998607 | 16.23 | 108.0 | 0.8728 |
| EEE 2013J | R0/R2 | 0.998693 | 10.32 | 88.5 | 0.8761 |
| DDD 2014B | R0/R2 | 0.999141 | 10.28 | 65.5 | 0.8779 |

**Interpretation:** overall ordering remains highly correlated, but many student-presentations change rank and top-decile overlap can fall to 82.86%. High Spearman correlation alone is insufficient when a decision depends on membership in a selected top group. The mean of presentation-level mean rank changes is an unweighted mean across presentations, not a student-weighted global mean. These are diagnostics, not an approved risk score.

### 4.5 AN5.05 — Activity by final-result group

The following summary pools 22 module-presentations while retaining student-presentation grain.

| Final result | Registered student-presentations | Activity coverage | Mean clicks R0 | R1 | R2 |
|---|---:|---:|---:|---:|---:|
| Distinction | 3,024 | 100.00% | 2,666.76 | 2,574.43 | 2,275.51 |
| Fail | 7,052 | 94.70% | 651.85 | 631.78 | 574.72 |
| Pass | 12,361 | 99.98% | 1,921.81 | 1,862.00 | 1,674.14 |
| Withdrawn | 10,156 | 70.58% | 313.95 | 303.91 | 273.20 |

No-recorded-activity counts are 0 (Distinction), 374 (Fail), 3 (Pass), and 2,988 (Withdrawn). Mean active days per registered student-presentation are 110.04, 33.18, 87.04, and 16.29; mean active sites are 102.45, 43.08, 89.06, and 24.23. These presence measures are unchanged across scenarios, while mean clicks decline under R1 and R2.

The SQL flags module-presentation/outcome cells below 100 registered student-presentations. Across the 22 presentations, there are 5 small Distinction cells, 2 small Fail cells, 0 small Pass cells, and 3 small Withdrawn cells.

The profile diagnostic reconciles all **32,593 registered keys** to **32,593 unique profile matches**. It reports zero duplicate registration keys, missing profile matches, duplicate profile matches, conflicting final results, or missing final results.

**Interpretation:** outcome-group differences are retrospective and descriptive, not causal. `final_result` is the grouping label, not a predictor. Group sizes vary, small cells need caution, and pooled counts are student-presentations rather than unique people.

## 5. Cross-query synthesis

1. **Repeated records are not one uniform duplicate problem.** Exact six-column duplicates are only one component; many repeated five-column keys contain different click values.
2. **Click volume is more sensitive than presence measures.** The scenarios change row counts and clicks, while coverage, active days, and resource breadth remain invariant.
3. **Time and population definitions matter.** Pre-course activity is present in the results, but negative relative day does not establish timing relative to personal registration.
4. **Global ranking similarity can hide boundary changes.** Spearman correlation and top-decile overlap answer different questions and must be read together.

The findings support further metric design; they do not select a final engagement measure.

## 6. Problems clarified and decisions

AN5 quantified the non-unique candidate key, separated exact identical tuples from repeated keys with different click values, reconciled scenario effects, retained pre-course activity, tested ranking sensitivity beyond one correlation statistic, and verified profile matching for the registered population.

AN5 did not establish the source-system cause of repetition, select R0/R1/R2 as the correct business rule, decide whether click volume should be primary or diagnostic, define the final treatment of pre-course/no-activity cases, or approve a risk threshold. No RAW, QUALITY, or STAGING data was modified; no persistent database object was created.

## 7. Relationship to the wider project and next stages

AN5 builds on the completed data-engineering foundation, WO-1 analytical readiness, and WO-2 work on join cardinality, missingness, registration/withdrawal, VLE activity, and assessment records. It reuses the composite student-presentation relationship and common registered denominator established by that earlier work.

Formal AN5 closure remains pending owner review and acceptance of the activity definition and limitations. Once that gate is satisfied, AN6 can be scoped separately for engagement analysis. AN7 remains a distinct outcome-association workstream and must distinguish association from causation. Curated reporting outputs, validated KPIs, Power BI, and the final evidence-based report follow metric validation. A separate data-science phase follows completion of the analytical phase.

No AN6 or AN7 work has been merged into AN5.

## 8. LinkedIn publication brief

This report is the evidence source for a future LinkedIn post, not publication approval. The public narrative should focus on analytical reasoning rather than claim a universal engagement score.

Suggested restrained static visual devices:
- Large numeric contrast: **10.66M source rows → 8.46M R2 scenario rows**, clearly labelled as sensitivity, not cleaning.
- Two compact bars for **-3.19%** and **-13.14%** click changes.
- A simple R0=100 index showing unchanged coverage, active-day pairs, and active-site pairs.
- Paired callout: high rank correlation (0.9976 in the lowest-overlap example) beside **0.8286 top-decile overlap**.
- Small R0/R1/R2 labels, fine connector lines or arrows, subtle grid, one restrained accent colour, generous whitespace, and short denominator/source footnotes.

Keep the caveat visible: *sensitivity analysis of recorded platform activity; not a source-cleaning decision, causal finding, or approved engagement KPI*. All public text and visuals require owner approval before publication.

## 9. Evidence limitations

- Findings are based on saved local execution outputs; this report does not claim a new database run.
- SQL batch timings are not total notebook runtime or per-statement timings.
- The runner reported no row-cap truncation, but pandas HTML display abbreviates long DataFrames; quantitative summaries use retained result frames.
- Distinct counts summed across presentations are not unique-person totals.
- Recorded VLE activity does not measure learning quality, comprehension, or attention.
- Outcome-group differences are retrospective and descriptive.
- No causal analysis, predictive validation, or operational threshold was part of AN5.

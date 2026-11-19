# AN8 Part 2 — Analytical Findings and Reporting Readiness

**Status:** Extended AN8 SQL investigations executed locally; CSV review cells executed and saved; integrated cross-result diagnostics prepared for local execution.  
**Analytical grain:** Student-presentation for activity/outcome analysis; student-assessment opportunity for assessment-state analysis; presentation/segment/outcome for profile analysis.  
**Source:** Owner-executed PostgreSQL outputs retained in Notebook 10 and the 17 CSV result sets under `outputs/an8/extracts/`.  
**Decision boundary:** This report does not approve destructive source cleaning, a production KPI, curated mart deployment, Power BI publication, or predictive modelling.

## 1. Executive conclusion

AN8 now provides more than a structural inventory. The evidence identifies concrete reporting risks that would materially change how an education platform describes engagement and academic outcomes:

1. **Click totals are not stable under unresolved repeated-row semantics.** The R1 and R2 sensitivity scenarios reduce recorded clicks by 3.19% and 13.14%, respectively, relative to R0. The source does not establish which repeated-row interpretation is true.
2. **Whole-source activity is not equivalent to activity during the course.** 688,988 of 10,655,280 activity rows (6.47%) occur before course day zero; these account for 2,147,947 of 39,605,099 recorded clicks (5.42%). Reporting all source activity as course engagement would overstate in-course activity.
3. **A meaningful zero-recorded-activity cohort exists.** 3,365 of 32,593 student-presentations have no recorded activity row in the retained activity extract. This is an observable platform-data state, not proof that students did not study or learn.
4. **Registration-relative measures are undefined for 45 records.** Missing registration dates must remain unknown; imputing day zero would fabricate exposure.
5. **Outcome, score, and profile tables require different denominators.** Student-presentations, assessment opportunities, and unique people cannot be substituted for one another. NULL scores, observed zeros, and no submission are distinct states.

The practical conclusion is that a single cleaned activity table and a single generic engagement KPI would be methodologically unsafe. Part 3 should create purpose-specific, versioned derived datasets, preserve the source evidence, and compare each transformation against explicit alternatives.

## 2. Evidence and execution integrity

The owner verified the local export manifest and 17 CSV files. The saved manifest reports 15 query records, 17 result sets, 37,584 exported rows, zero export errors, and six passing gates. The CSV review section in Notebook 10 was executed and saved: cells 17.00–18.1 loaded the retained CSVs, rendered their individual visualizations, and passed the final inventory assertion.

The new integrated diagnostics in Notebook 10, Section 19–20, were added after that saved execution. They are **prepared but not yet executed**. Their computed aggregate summaries must not be quoted as verified results until the owner runs those cells and synchronizes the outputs.

No SQL was rerun during preparation of this report. No RAW, QUALITY, or STAGING data were modified.

## 3. Validated cohort and outcome context

AN8.02 confirmed the student-presentation grain:
- `student_info`: 32,593 rows and 32,593 distinct composite keys.
- `student_registration`: 32,593 rows and 32,593 distinct composite keys.
- No duplicate composite-key groups or NULL-key rows in either relation.
- Zero key-set differences in either direction.

AN8.03 reconciled all 32,593 student-presentations to registration:

| Retrospective outcome | Student-presentations | Share |
|---|---:|---:|
| Pass | 12,361 | 37.93% |
| Withdrawn | 10,156 | 31.16% |
| Fail | 7,052 | 21.64% |
| Distinction | 3,024 | 9.28% |
| **Total** | **32,593** | **100.00% rounded** |

These are presentation registrations, not unique people. A person may appear in multiple module-presentations. `final_result` is retrospective context and must never be used as an early predictor of itself.

## 4. Repeated activity rows: quantified metric sensitivity

AN8.30 compared three definitions without changing the source:

| Scenario | Activity rows | Recorded clicks | Difference from R0 |
|---|---:|---:|---|
| R0 — preserve all source rows | 10,655,280 | 39,605,099 | Baseline |
| R1 — distinct across all six source columns | 9,868,110 | 38,343,063 | 787,170 fewer rows; 1,262,036 fewer clicks |
| R2 — MAX(sum_click) per five-column candidate key | 8,459,320 | 34,402,738 | 2,195,960 fewer rows; 5,202,361 fewer clicks |

Relative to R0:
- R1 reduces rows by 7.39% and clicks by 3.19%.
- R2 reduces rows by 20.61% and clicks by 13.14%.

The five-column candidate key has 1,614,505 repeated groups; 1,179,074 groups contain multiple distinct `sum_click` values; the maximum group size is 10. This is not a simple case where all repeated keys are exact duplicate events. R1 and R2 encode different assumptions and neither is established as ground truth.

**Reporting decision:** preserve R0 as the source-faithful reference. Do not publish click totals without a definition and sensitivity note. Do not silently deduplicate. Active days and resource breadth use distinct dates/sites and are less directly affected by repeated rows, but still need temporal, denominator, and semantic validation.

## 5. Course-relative activity and the no-recorded-activity cohort

The AN8.20 source reconciliation reports:

| Activity partition | Rows | Recorded clicks |
|---|---:|---:|
| In-course | 9,966,292 | 37,457,152 |
| Pre-course | 688,988 | 2,147,947 |
| Post-course | 0 | 0 |
| No course window | 0 | 0 |
| **Total** | **10,655,280** | **39,605,099** |

All 10,655,280 source activity rows matched the registered cohort in the tested join. This validates that join reconciliation for the supplied keys; it does not establish that each source row is a unique interaction or a learning event.

The pre-course partition is 6.47% of activity rows and 5.42% of recorded clicks. It must not be included in course-window engagement measures. It should remain available as a separate diagnostic because it may reflect pre-course access, timing conventions, or source semantics that need investigation.

The saved AN8.20 notebook output also reports 3,365 student-presentations without a recorded activity row. This group should remain in zero-inclusive denominators. Absence of a VLE row is not evidence of no learning across all channels.

## 6. Registration timing and exposure

AN8.10 reports:
- 32,312 registrations before course start;
- 234 after course start;
- 2 on course start;
- 45 with a missing registration date.

AN8.32 summarizes available exposure by presentation and registration state. Its 61 grouped rows are not 61 students; the underlying registered student-presentations must be summed to reconcile the cohort. The saved output includes 45 unknown-exposure records. The newly added Section 19 diagnostic will explicitly reconcile unknown, zero, and positive exposure counts when executed.

**Reporting decision:** raw active-day counts should not be compared across early and late registrants without an exposure denominator. Registration-relative exposure is opportunity-to-observe, not attendance. The 45 missing registration dates remain unknown; do not impute them as day zero.

## 7. Withdrawal and assessment states

AN8.11 reports:
- 10,063 Withdrawn records with an unregistration date;
- 93 Withdrawn records without one;
- 9 Fail records with an unregistration date;
- no unregistration date for Pass or Distinction records in this extract.

These are source-definition conflicts, not automatic deletion candidates. `final_result` and `date_unregistration` must remain separate fields until a documented rule is justified.

AN8.12 distinguishes:
- 173,410 nonzero observed scores;
- 329 observed zero scores;
- 173 NULL scores.

AN8.35 adds the assessment-opportunity view with five states: no submission, NULL-score-only, observed-zero-only, nonzero-score-only, and mixed score states. Its denominator is a registered student-assessment opportunity, not a unique student. Submission rows reconcile to 173,912 and NULL-score rows to 173. The newly added integrated diagnostic also checks these reconciliations; its saved output is still pending.

**Reporting decision:** never convert NULL to zero, and never equate no submission with a submitted record whose score is NULL. Banked assessment records and the `date_submitted=-1` sentinel require explicit treatment before participation/timing measures are approved. Due dates do not establish score or feedback availability.

## 8. Outcome and student-profile comparisons

AN8.34 returns 352 presentation/outcome/metric summaries. Its values are descriptive summaries within each module-presentation, not pooled student-level observations. Differences between Pass, Fail, Withdrawn, and Distinction groups can motivate hypotheses, but they do not establish causality or when a difference became observable. The integrated summary and small-cell review have been prepared in Notebook 10 Section 19.05; execute them before quoting cross-presentation weighted summaries.

AN8.36 returns 4,249 rows across eight profile dimensions. Percentages are within each module-presentation and profile segment. They are not full-cohort percentages, adjusted effects, or a fairness assessment. Missing categories and small cells need explicit audit and disclosure controls. The integrated missing-category and small-cell diagnostics are prepared but not yet executed.

## 9. Decisions for reporting and Power BI

The following decisions are supported now:

1. Keep the primary activity grain at one registered student-presentation: `(code_module, code_presentation, id_student)`.
2. Retain every registered key, including zero-recorded-activity cases.
3. Keep course-relative and registration-relative measures separate.
4. Treat recorded clicks as secondary and sensitivity-dependent; do not choose R1/R2 as source truth.
5. Keep missing registration dates and unknown exposure separate from observed zero activity.
6. Separate student-presentation, assessment-opportunity, and unique-person denominators.
7. Keep outcome labels retrospective and exclude them from early-warning features.
8. Preserve score-state distinctions and do not impute NULL scores as zero.
9. Treat profile segmentation as exploratory until small-cell, missingness, repeated-person, and presentation effects are reviewed.

Power BI should not be built on raw source tables or unapproved candidate metrics. The reporting contract must define grain, denominator, time window, zero/NULL treatment, scenario, and refresh lineage for every measure. Curated tables and any deployment DDL remain a separate reviewed and approved work order.

## 10. Part 3 — Deep cleaning and analytical validation

Part 3 is justified, but it is not a blanket cleaning exercise. It should build versioned derived datasets for specific analytical purposes while preserving original files and RAW/STAGING evidence.

The dedicated Part 3 plan is `docs/AN8_part3_deep_cleaning_analysis_plan.md`. Its first work packages should be:

- repeated `student_vle` group semantics and R0/R1/R2 row-level traceability;
- course-relative versus registration-relative time windows, including pre-course activity;
- 45 missing registration dates and the resulting unknown exposure;
- 3,365 no-recorded-activity student-presentations;
- assessment opportunity keys, banked records, NULL/zero/no-submission states, and score availability;
- profile-field missingness, category domains, small cells, and repeated people across presentations;
- presentation-level heterogeneity and uncertainty before any global threshold or ranking.

Every transformation must have a rule ID, source/target grain, reason, affected keys and rows, before/after reconciliation, metric impact, sensitivity alternative, and approval state. No source deletion, blanket imputation, or universal deduplication is approved.

## 11. Limitations and next gate

The integrated diagnostic cells in Notebook 10 Sections 19–20 are prepared but not executed. Their actual tables and any additional numerical findings remain pending local execution. This report deliberately limits its numerical claims to saved owner-executed outputs and independently reproducible arithmetic from those outputs.

AN8 remains open until:
- integrated diagnostics have been executed and reviewed;
- cleaning decisions and metric contracts are documented;
- purpose-specific derived outputs pass row/key/denominator/time validation;
- curated reporting design and deployment are separately approved and reconciled;
- Power BI source and measure contracts are validated.

No model training is authorized by this report. Predictive readiness remains a later gate after the analytical reporting phase.

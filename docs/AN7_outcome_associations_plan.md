# AN7 — Outcome Associations

**Status:** PACKAGE PREPARED — NOT EXECUTED.  
**Roadmap:** AN7 follows closed AN6 and precedes AN8 Predictive Readiness Gate.  
**Grain:** One registered student-presentation: (code_module, code_presentation, id_student).

## 1. Purpose and decision boundary

AN7 investigates associations between recorded VLE activity and retrospective academic outcomes. It is not a causal study or predictive-modeling stage. The initial release focuses on leakage-aware activity features. AN3/AN4 saved evidence is reused; completed investigations are not rerun wholesale.

No composite engagement score, student ranking, course league table, intervention threshold, predictive model, analytical mart, view, index, or persistent table is created.

## 2. Inherited evidence

- AN5/AN6 grain: one registered student-presentation, joined on all three key columns.
- In-course window: 0 <= student_vle.date <= module_presentation_length, inclusive.
- R0 retains every source row; no source deduplication is approved.
- AN5.02: 32,593 registrations, 28,785 distinct people, 29,228 with any activity, 3,365 without a matching activity row, and 89.68% any-window coverage.
- AN6.02: 28,500 with in-course activity (87.44%), 728 outside-window-only, and 3,365 with no activity in any observed window.
- Reconciliation: 28,500 + 728 = 29,228. Thus 89.68% is any-window coverage and 87.44% is in-course-only coverage.
- AN6.03: 9,966,292 in-course rows and 688,988 pre-course rows; no post-course bucket was returned.
- AN6.04: activity-type volume and student reach are distinct; reach is non-additive.
- AN3.01: 10,156 Withdrawn labels, 10,072 non-NULL unregistration dates, intersection 10,063; therefore 93 Withdrawn/no-date and 9 non-Withdrawn/with-date cases.
- AN3.06: recorded VLE activity can occur after the stored unregistration day; this is a timestamp comparison, not proof of accepted activity.
- AN1.06/AN5.02: 28,785 distinct people across 32,593 registrations. Account for repeated people; do not repeat the basic count query.
- AN4.05: 173,912 assessment rows, 173,739 non-NULL scores, 173 NULL scores, 329 zero scores; the NULL scores occur across 78 assessments and are all TMA.
- AN4.06: 1,909 banked rows (571 CMA, 1,338 TMA), with saved date_submitted=-1; preserve for retrospective score sensitivity, not timing.
- AN4.01/AN4.10: assessment structures and weights vary; GGG CMA/TMA weights are zero in source.
- AN4.03: submission timing versus due date is descriptive; CMA date semantics do not support an automatic late-submission KPI.
- AN4.02/AN4.04: 11 assessments lack a due date; three have submission records totalling 2,865 rows.

These are retained historical outputs, not fresh executions during AN7 package preparation.

## 3. Outcome contract

- **O1 — Recorded final withdrawal label:** Withdrawn versus other known final-result labels, among registrations eligible at the landmark. The 93 Withdrawn/no-date cases have indeterminate landmark eligibility and are excluded from the primary O1 risk set; include them only in a named sensitivity.
- **O2 — Failure among non-withdrawn outcomes:** Fail versus Pass+Distinction among eligible registrations with one of those three known labels. The nine Fail/with-date cases remain visible and are excluded only in a sensitivity.
- **O3 — Ordered non-withdrawn outcome:** Fail < Pass < Distinction among eligible registrations with those three known labels. Use rank-based association, not equal numeric distances.
- Missing or unexpected final_result values remain visible. final_result is an outcome only, never a predictor.

## 4. Landmark and at-risk contract

| Label | Inclusive course-relative days | Duration |
|---|---:|---:|
| L28 | 0–27 | 28 days |
| L56 | 0–55 | 56 days |
| L84 | 0–83 | 84 days |

These are analytical day windows, not academic-week definitions. A landmark is eligible only when landmark_day <= module_presentation_length.

At landmark L, primary at-risk eligibility requires a registration/course match, known date_registration <= L, no recorded unregistration on/before L, and no final_result='Withdrawn' case with missing unregistration date. A date_unregistration equal to L is treated as unregistered by the landmark. The 45 missing registration dates and the 93 undated Withdrawn cases remain explicit and outside the primary risk set.

The unregistration date is used only for landmark eligibility. It does not truncate or remove activity rows. AN3.06 documents recorded activity after some unregistration dates.

## 5. Activity feature contract

Two time bases remain separate:

1. **Course-relative activity:** days/resources in [0,L], comparable with AN6.
2. **Post-registration activity:** days/resources from GREATEST(0,date_registration) through L, the primary early-activity feature basis.

Candidate features are the proportion of available post-registration days with recorded activity and distinct resource breadth at L28/L56/L84. SQL also returns raw active-day counts and the number of available post-registration days at every landmark. This prevents late registrants from being treated as though they had a full 28/56/84-day exposure. Resource breadth remains exposure-duration-sensitive; report its denominator and run registration-timing sensitivity where cell sizes permit. Pre-course activity and in-course/pre-registration activity remain separate diagnostics. Raw activity-row totals are retained only for reconciliation (9,966,292 in-course rows); they are not primary engagement measures because repeated source-row semantics remain unresolved.

No activity is cut off at date_unregistration. The student_vle source remains unchanged and R0 is preserved.

## 6. Assessment feature boundary

AN7 reuses saved AN4 outputs and adds a limited metadata query describing assessment due dates and stored weights relative to the landmarks. It does not infer score availability. No CMA/TMA/Exam score is an early feature because the dataset does not establish when scores or feedback became visible. Banked records with date_submitted=-1 are excluded from timing features. A separate student-level assessment-participation feature requires a later explicit availability contract.

## 7. Statistical analysis contract

- Compute O1/O2/O3 separately for each eligible landmark.
- Report denominators, group counts, missingness, quantiles, and effect sizes by module-presentation first.
- Binary contrasts use Cliff's delta (rank-biserial equivalent); positive values mean a higher feature in the first-named outcome group. Confidence intervals are withheld when either group has fewer than 10 observations. Report medians and interquartile ranges alongside effect sizes.
- O3 uses Spearman rank association.
- Confidence intervals resample id_student within each module-presentation. The grain contains one row per person within a presentation; across-presentation summaries must preserve repeated-person clustering.
- Inspect presentation-specific direction changes; avoid naïve pooled comparisons and Simpson's paradox.
- No predictive model, random train/test split, causal claim, student ranking, or course league table.
- Initial review emphasizes effect sizes and intervals rather than uncorrected significance tests. Any later p-value family requires pre-specified hypotheses and multiplicity correction.
- Covariates are not inserted automatically; use requires a rationale, missingness review, and adequate cell sizes.

## 8. Canonical SQL package

| Query | File | Result sets | Role |
|---|---|---:|---|
| AN7.01 | AN7.01_outcome_registration_reconciliation.sql | 3 | Outcome labels, registration/unregistration timing, anomaly groups. |
| AN7.02 | AN7.02_assessment_landmark_context.sql | 1 | Assessment due-date/weight metadata by landmark; no score-availability claim. |
| AN7.03 | AN7.03_landmark_cohort_eligibility.sql | 1 | One row per student-presentation with explicit landmark risk states. |
| AN7.04 | AN7.04_student_presentation_daily_activity.sql | 1 | One high-cost scan; daily pre-aggregation and active-day measures. |
| AN7.05 | AN7.05_student_presentation_resource_breadth.sql | 1 | One high-cost scan; first-resource-day reduction and resource breadth. |

Expected total: seven result sets by design, not execution evidence.

## 9. Work orders and execution sequence

### WO-3 — Definitions and cohort gate
1. Run AN0.01 read-only preflight.
2. Run AN7.01 and inspect all result sets.
3. Run AN7.02; interpret due dates/weights as metadata only.
4. Run AN7.03; verify 32,593 rows, unique full key, registration/course matches, and 45 missing registration dates.
5. Review risk-status counts and approve the primary cohorts before heavy scans.

### WO-4 — Heavy student-level activity extraction
1. Run AN7.01–AN7.03 and pass the cohort gate in the same runner invocation.
2. Run AN7.04 alone with 600,000 ms timeout and max_rows >= 33,000.
3. Review its complete output and reconciliation diagnostics before authorizing the second scan.
4. Run AN7.01–AN7.03 again to establish a fresh cohort gate, then run AN7.05 alone with the same timeout and cap.
4. Reconcile full-course breadth to the 28,500 activity-bearing registrations.
5. Never run both scans in one runner invocation or concurrently. If TupleSort/OutOfMemory occurs, stop and redesign; do not raise global memory settings or blindly retry.

### WO-5 — Python association analysis
1. Merge AN7.03–AN7.05 with one-to-one validation on the full three-column key.
2. Reconcile to 32,593 registrations, 28,785 distinct people, 28,500 in-course activity-bearing registrations, and 9,966,292 in-course rows.
3. Use explicit risk-status fields for each landmark.
4. Compute O1/O2/O3 separately using post-registration active-day rates and resource breadth; report raw active days and exposure-day denominators alongside them.
5. Report per-presentation group sizes, medians/quantiles, effect sizes, and student-level bootstrap intervals.
6. Inspect cross-presentation direction changes.
7. Test the 93/9 anomaly sensitivities. Do not automatically exclude 2014J or select one presentation per person without a defensible chronology rule.

### WO-6 — Assessment follow-up, leakage review, and closure
1. Reuse AN4.01–AN4.10 saved outputs; do not rerun wholesale.
2. Decide whether early assessment participation (not scores) adds a justified secondary analysis.
3. Complete a leakage register: feature, observation end day, personal-registration basis, unregistration sensitivity, outcome dependence, and availability evidence.
4. Reconcile SQL/Python outputs and record stable, weak, heterogeneous, and unresolved associations.
5. Recommend only what AN8 should test. Do not fit a predictive model in AN7.

## 10. Safety and acceptance

- Every SQL file includes Question, Expectation, Grain, Source, Safety, Runtime, and Read as.
- All SQL is read-only. No RAW/STAGING mutation, deduplication, DDL, indexes, materialized views, or permanent tables.
- AN0.01 is mandatory. AN7.01–AN7.03 and the cohort gate precede AN7.04/AN7.05.
- Heavy scans run sequentially; complete retrieval is required. max_rows is a Python retrieval cap, not a PostgreSQL memory control.
- No automatic retry after PostgreSQL errors.
- AN7.03–AN7.05 outputs must be 32,593 unique student-presentation rows.
- Full-course activity must reconcile to 28,500 registrations and 9,966,292 source rows.
- Full-course resource breadth must be positive for the same 28,500 registrations, subject to the existing resource-key completeness check.
- Landmark active-day/resource measures must be non-decreasing across L28, L56, L84, and full course.
- Missing/indeterminate cohort states remain explicit; no silent denominator changes.
- No causal, predictive-performance, or learning-quality claim.

## 11. Open limitations

- The 93 Withdrawn/no-date cases have indeterminate withdrawal timing.
- The nine Fail/date-unregistration cases remain conflicting source evidence.
- AN3.06 confirms activity rows can occur after unregistration; it is not an activity cutoff.
- Student IDs recur across presentations; cluster-aware resampling is required for cross-presentation summaries.
- The 45 missing registration dates cannot enter the primary landmark risk set.
- Score availability time is not observed; scores are not early features.
- CMA due-date comparisons remain descriptive.
- R0 preserves source rows; row counts/clicks remain repetition-sensitive.
- AN6 week_from/week_to missingness overlap is irrelevant unless those fields are used.
- No evidence currently justifies excluding 2014J from the primary analysis.

## 12. Repository status and roadmap

The package is prepared on work/an7-outcome-associations from main 4b707623e5dc0ecf16e93311c2b466d822ad9d35. It is not merged. No AN7 SQL has executed and no database state was inspected during package preparation. Notebook 09 is initially unexecuted.

AN7 → AN8 Predictive Readiness Gate → AN9 Validated Metrics & Analytical Marts → AN10 Power BI → AN11 Final Analytical Report. A separate Data Science/ML phase remains after AN11.

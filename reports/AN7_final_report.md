# OULAD — AN7 Outcome Associations
## Final Analytical Report and AN10 Handover

**Review date:** 14 November 2026  
**Repository:** JALILOHUB/OULAD-EdTech-Learning-Analytics  
**Notebook:** notebooks/09_an7_outcome_associations.ipynb  
**Reviewed notebook blob before closeout:** a61a9f777327505272ddce1ab7e579fb743ef5b9  
**Execution evidence timestamp:** 13 November 2026, 22:33:34 UTC  
**Disposition:** **AN7 analytical scope CLOSED and integrated into main** through PR #19 (squash merge commit `a3c321bc1536aec81c82541da77085e39784cd8e`).

---

## 1. Executive summary

AN7 examined presentation-specific associations between post-registration recorded VLE activity and retrospective academic outcomes at three course-relative landmarks. The analysis used 32,593 registered student-presentations across 22 module-presentations, with 28,785 distinct people.

The results are consistent across the three outcome definitions:
- **O1 — Withdrawal:** the Withdrawn group generally had lower active-day rates and lower resource breadth than other known outcomes.
- **O2 — Failure:** the Fail group had lower values for both features than the combined Pass/Distinction group in all 22 module-presentations at all three landmarks.
- **O3 — Ordered outcome:** both features had positive monotonic associations with Fail < Pass < Distinction in all 22 module-presentations at every landmark.

Active-day rate generally showed stronger median presentation-level associations than resource breadth. The sensitivity checks broadly retained the O1/O2 directions, while revealing that the after-course-start registration stratum is too sparse for reliable effect-strength comparisons.

These are observational, presentation-specific associations. They do not show that increasing VLE activity causes better outcomes, and they do not establish predictive performance or justify automatic student interventions.

## 2. Research scope and analytical design

### Unit of analysis

One registered student within one module-presentation: (code_module, code_presentation, id_student). The final analytical frame contains 32,593 unique keys and 28,785 distinct people because some students appear in more than one presentation.

### Observation landmarks

| Landmark | Inclusive course-relative days | Window length |
|---|---:|---:|
| L28 | 0–27 | 28 days |
| L56 | 0–55 | 56 days |
| L84 | 0–83 | 84 days |

The windows are day-based, not academic-week labels. Presentation start periods vary; the analysis did not invent calendar dates.

### Primary features

- **Post-registration active-day rate:** distinct days with recorded activity after the student's registration point, divided by available post-registration exposure days.
- **Post-registration resource breadth:** distinct non-NULL resource IDs first observed within the corresponding window.

Course-relative activity was retained separately for reconciliation. Resource breadth was not normalized by exposure days and therefore remains sensitive to registration timing.

### Outcome definitions

- **O1:** Withdrawn versus Fail/Pass/Distinction combined, within the landmark-specific AT_RISK set.
- **O2:** Fail versus Pass/Distinction combined, excluding Withdrawn.
- **O3:** ordinal Fail < Pass < Distinction, evaluated with Spearman's rank correlation.

Final result was used only as an outcome, never as a predictor.

## 3. Execution evidence and database safeguards

All five canonical read-only SQL investigations were executed locally by the project owner. The reviewed pre-closeout Notebook 09 contained 73 cells, including 32 Python code cells, all with execution counts. Thirty code cells produced saved outputs; two setup/helper-definition cells intentionally had no display output. The closeout added one Markdown interpretation cell, bringing the retained notebook to 74 cells without rerunning code. The five SQL result sets and Python outputs are retained without reported truncation.

| Investigation | Result sets | Returned rows | Batch runtime |
|---|---:|---:|---:|
| AN7.01 — Outcome and registration reconciliation | 3 | 20 + 15 + 22 | 0.121 sec |
| AN7.02 — Assessment landmark context | 1 | 171 | 0.010 sec |
| AN7.03 — Landmark cohort eligibility | 1 | 32,593 | 0.405 sec |
| AN7.04 — Daily activity extraction | 1 | 32,593 | 96.683 sec |
| AN7.05 — Resource breadth extraction | 1 | 32,593 | 93.835 sec |
| **Total** | **7** | **65,204** | **191.054 sec** |

AN7.04 and AN7.05 were executed sequentially as separate high-cost scans. AN7.01–AN7.03 were refreshed before AN7.05 and the cohort gate passed.

The retained preflight records database oulad_analytics, PostgreSQL 18.6, schema public, transaction_read_only=on, default_transaction_read_only=on, a two-minute statement timeout, and a five-second lock timeout.

No persistent database objects were created. No RAW, QUALITY, or STAGING data was modified. No source activity rows were deleted, deduplicated, or aggregated.

## 4. Cohort and extraction reconciliation

| Check | Observed result |
|---|---:|
| Registered student-presentations | 32,593 |
| Distinct people | 28,785 |
| In-course activity-bearing registrations | 28,500 |
| Full-course resource-bearing registrations | 28,500 |
| In-course source activity rows | 9,966,292 |
| Duplicate three-column keys in analytical inputs | 0 |
| NULL resource-key groups | 0 |
| Pre-course active days | 107,752 |
| Registrations with at least one pre-course active day | 23,809 |

There were zero in-course active days before recorded registration among registrations with known registration dates.

### Landmark eligibility

| Risk status | L28 | L56 | L84 |
|---|---:|---:|---:|
| AT_RISK | 27,435 | 26,423 | 25,629 |
| UNREGISTERED_BY_LANDMARK | 5,002 | 6,023 | 6,822 |
| INDETERMINATE_WITHDRAWAL_TIMING | 93 | 93 | 93 |
| REGISTRATION_DATE_MISSING | 45 | 45 | 45 |
| NOT_REGISTERED_BY_LANDMARK | 18 | 9 | 4 |
| **Total** | **32,593** | **32,593** | **32,593** |

The eligible risk set changes by landmark. Later estimates therefore do not represent repeated measurements on an unchanged cohort.

### Exposure validation

| Exposure state | L28 | L56 | L84 |
|---|---:|---:|---:|
| Unknown exposure | 45 | 45 | 45 |
| Zero exposure | 18 | 9 | 4 |
| Positive exposure | 32,530 | 32,539 | 32,544 |

No record had exposure greater than its landmark, and no active-day count exceeded available exposure. Unknown exposure was not converted to zero.

## 5. Outcome and assessment context

AN7.01 retained two source anomalies: 93 Withdrawn student-presentations have no stored unregistration date; nine Fail student-presentations have a stored unregistration date. The nine Fail records have different date patterns across presentations; they are not treated as one uniform timing condition. The 45 missing registration dates also remain explicit.

AN7.02 returned 171 assessment-context rows. Eleven assessments have missing due dates. Due dates and stored weights describe assessment structure; they do not establish when a student received a score or feedback. The 173 NULL assessment scores remain distinct from 329 observed zero scores. No assessment score was used as an early feature.

## 6. O1 — Withdrawn versus other known outcomes

| Landmark | Feature | Median Cliff's delta | Negative estimates | 95% CIs wholly below zero |
|---|---|---:|---:|---:|
| L28 | Active-day rate | -0.191 | 21 / 22 | 19 / 22 |
| L28 | Resource breadth | -0.178 | 20 / 22 | 18 / 22 |
| L56 | Active-day rate | -0.195 | 22 / 22 | 19 / 22 |
| L56 | Resource breadth | -0.197 | 20 / 22 | 18 / 22 |
| L84 | Active-day rate | -0.194 | 22 / 22 | 19 / 22 |
| L84 | Resource breadth | -0.193 | 20 / 22 | 18 / 22 |

**Interpretation:** the Withdrawn group generally had lower active-day rates and resource breadth than the other known-outcome group. The direction is broadly consistent across presentations and landmarks, but some confidence intervals include zero. This supports an association within the defined risk sets, not a causal explanation of withdrawal.

## 7. O2 — Fail versus Pass/Distinction

| Landmark | Feature | Median Cliff's delta | Negative estimates | 95% CIs wholly below zero |
|---|---|---:|---:|---:|
| L28 | Active-day rate | -0.468 | 22 / 22 | 22 / 22 |
| L28 | Resource breadth | -0.407 | 22 / 22 | 22 / 22 |
| L56 | Active-day rate | -0.531 | 22 / 22 | 22 / 22 |
| L56 | Resource breadth | -0.475 | 22 / 22 | 22 / 22 |
| L84 | Active-day rate | -0.572 | 22 / 22 | 22 / 22 |
| L84 | Resource breadth | -0.527 | 22 / 22 | 22 / 22 |

**Interpretation:** lower recorded activity is consistently associated with the Fail group rather than Pass/Distinction. All 22 presentation-level estimates are negative and all reported intervals are wholly below zero. The larger absolute medians at later landmarks must be read against changing risk sets; they do not establish a strengthening effect within a fixed cohort.

## 8. O3 — Ordered academic outcome

| Landmark | Feature | Median Spearman rho | Positive estimates | 95% CIs wholly above zero |
|---|---|---:|---:|---:|
| L28 | Active-day rate | 0.379 | 22 / 22 | 22 / 22 |
| L28 | Resource breadth | 0.340 | 22 / 22 | 22 / 22 |
| L56 | Active-day rate | 0.436 | 22 / 22 | 22 / 22 |
| L56 | Resource breadth | 0.383 | 22 / 22 | 22 / 22 |
| L84 | Active-day rate | 0.470 | 22 / 22 | 22 / 22 |
| L84 | Resource breadth | 0.407 | 22 / 22 | 22 / 22 |

**Interpretation:** higher activity values tend to accompany higher ordered outcomes across Fail < Pass < Distinction. All estimates are positive in all presentations. The ordinal mapping represents rank order only; it does not assume equal academic distances between categories.

## 9. Sensitivity analysis

The sensitivity calculations were produced from existing dataframes and generated 660 rows: 132 primary O1, 132 alternative O1, 132 O2 exclusion, and 264 registration-timing estimates. The 30-row summary retains presentation-level estimates rather than pooling them.

### O1 — Include eligible undated Withdrawn cases

| Landmark | Feature | Primary median | Alternative median |
|---|---|---:|---:|
| L28 | Active-day rate | -0.1915 | -0.1918 |
| L28 | Resource breadth | -0.1783 | -0.1845 |
| L56 | Active-day rate | -0.1949 | -0.1963 |
| L56 | Resource breadth | -0.1971 | -0.2013 |
| L84 | Active-day rate | -0.1940 | -0.1966 |
| L84 | Resource breadth | -0.1933 | -0.1996 |

Of 132 paired estimates, 130 retained their direction. Two sign changes occurred for resource breadth in GGG / 2013J at L56 and L84, both close to zero. Median absolute paired change was approximately 0.00166; the maximum was approximately 0.06233, with larger changes concentrated in selected 2014J presentations.

**Interpretation:** the broad O1 pattern is reasonably stable under the tested inclusion rule. This does not establish that missing withdrawal dates are harmless or reveal their true timing.

### O2 — Exclude Fail cases with an unregistration date

All 22 presentation-level estimates remained negative for both features at all landmarks.

| Landmark | Feature | Median Cliff's delta | Negative estimates |
|---|---|---:|---:|
| L28 | Active-day rate | -0.4677 | 22 / 22 |
| L28 | Resource breadth | -0.4069 | 22 / 22 |
| L56 | Active-day rate | -0.5312 | 22 / 22 |
| L56 | Resource breadth | -0.4755 | 22 / 22 |
| L84 | Active-day rate | -0.5723 | 22 / 22 |
| L84 | Resource breadth | -0.5275 | 22 / 22 |

**Interpretation:** the O2 direction is unchanged under this alternative exclusion. The sensitivity does not explain the source conflict or establish predictive validity.

### O1 — Registration-timing strata

For registrations on or before course start:

| Landmark | Feature | Median effect | Negative estimates |
|---|---|---:|---:|
| L28 | Active-day rate | -0.1946 | 21 / 22 |
| L28 | Resource breadth | -0.1784 | 20 / 22 |
| L56 | Active-day rate | -0.1955 | 22 / 22 |
| L56 | Resource breadth | -0.1973 | 20 / 22 |
| L84 | Active-day rate | -0.1929 | 22 / 22 |
| L84 | Resource breadth | -0.1902 | 20 / 22 |

For registrations after course start, only 12 of 22 estimates were estimable per landmark-feature combination; 10 were non-estimable. The median comparison-group size among estimable comparisons was five (range 1–49), and some estimates reached -1 or +1.

**Interpretation:** the on-or-before-start stratum broadly reproduces the primary O1 pattern. The after-start stratum is too sparse for a reliable strength comparison and must not be described as a stronger association.

### Sensitivity conclusion

The tested O1/O2 alternatives preserve the broad direction of the main findings. The timing analysis supports the primary pattern among on-or-before-start registrations, but late-registration estimates remain weakly identified. Sensitivity results are a robustness assessment of descriptive associations, not causal validation.

## 10. Visual evidence

The notebook now retains 24 visualizations: the original 15 two outcome/registration anomaly and missing-date charts; two assessment context charts; three landmark eligibility composition charts; active-day-rate and resource-breadth heatmaps; and six presentation-level effect-distribution boxplots, plus nine sensitivity figures (three O1 paired-comparison charts, three O2 paired-comparison charts, and three registration-timing estimability charts). The nine additional figures read retained CSV exports; they do not rerun SQL or recalculate the original statistical analysis.

The AN7.04 and AN7.05 heatmaps describe extraction-level registrations with valid exposure; they are not restricted to the AT_RISK statistical cohort. The boxplots summarize presentation-level estimates, not pooled student-level distributions.

## 11. Temporal leakage controls

- final_result is an outcome only and never a predictor.
- date_unregistration is used for retrospective landmark eligibility and sensitivity, not as an early feature and not to truncate VLE activity.
- Assessment due dates and weights are descriptive metadata only.
- student_assessment.score is excluded from early features because score/feedback publication times are not observed.
- Banked date_submitted = -1 is a sentinel, not a valid event date.
- Course-relative activity and post-registration activity remain separate.
- risk_status and id_student are cohort-control/join fields, not model features.
- VLE activity is day-level; ordering within the same day as registration is unknown.

## 12. Methodological limitations

1. Associations are observational and do not demonstrate causality.
2. O1/O2/O3 use landmark-specific risk sets with changing denominators.
3. The same person may appear in multiple module-presentations; estimates are presentation-specific and must not be naively pooled as independent people.
4. Resource breadth is not normalized by exposure duration.
5. The 93 undated Withdrawn and nine Fail/date-unregistration records remain unresolved source anomalies.
6. The 45 missing registration dates have unknown post-registration exposure.
7. Due dates do not prove score or feedback availability.
8. R0 preserves repeated source activity rows; row and click totals remain sensitive to unresolved source repetition.
9. Confidence intervals are not adjusted for the full family of comparisons.
10. Prior attainment, demographics, course structure, teaching design, and other unmeasured factors may confound associations.
11. No predictive model, calibration analysis, or out-of-time validation was conducted.

## 13. Questions answered by AN7

| Question | Evidence-based answer |
|---|---|
| Is recorded activity associated with withdrawal? | Yes, lower activity is generally associated with Withdrawn outcomes in eligible landmark cohorts; O1 is less uniform than O2/O3. |
| Is recorded activity associated with failure? | Yes, both features show negative O2 effects in all 22 presentations at all landmarks. |
| Does activity vary monotonically with ordered outcomes? | Yes, O3 Spearman estimates are positive in all 22 presentations at all landmarks. |
| Does the result depend on the 93 undated Withdrawn cases? | The broad O1 pattern remains similar under the tested eligible-inclusion alternative; actual withdrawal timing remains unknown. |
| Do the nine Fail/date-unregistration cases determine O2 direction? | No; excluding them leaves all 22 presentation estimates negative for both features at every landmark. |
| Does registration timing matter? | The on-or-before-start stratum is broadly consistent; the after-start stratum is too sparse for a reliable comparison. |
| Are early assessment scores valid features? | Not established. Due dates and weights do not prove score/feedback availability. |
| Are these findings predictive or causal? | No. AN7 is an association study, not a model or causal design. |

## 14. Decisions

- Carry active-day rate forward as the primary candidate for AN10 predictive-readiness assessment.
- Retain resource breadth as a secondary candidate, with explicit exposure-opportunity analysis.
- Do not create a composite score, threshold, student ranking, intervention rule, or production KPI from AN7.
- Preserve source anomalies and the original R0 activity rows.
- Do not use future outcomes or unverified assessment-availability fields as predictors.
- Keep the changing landmark risk sets explicit in any later evaluation.

## 15. New questions for AN10

1. What is the exact operational prediction cutoff and target horizon?
2. Can every candidate feature be shown to be available by that cutoff, including same-day registration/activity ambiguity?
3. How should changing landmark cohorts and registrations after course start be handled?
4. What temporal validation split avoids leakage across presentations and repeated student identities?
5. How do class imbalance and subgroup sizes affect calibration and decision usefulness?
6. Does active-day rate add information beyond resource breadth, and does resource breadth add information beyond active-day rate?
7. Which confounders and prior-attainment variables are available at the operational cutoff?
8. How should missing exposure, no recorded activity, and zero activity be represented without conflating them?
9. What baseline and evaluation metrics would be appropriate for the intended operational decision?
10. What false-positive and false-negative trade-offs would be acceptable for any future support workflow?

## 16. AN10 handover recommendation

AN10 is a predictive-readiness gate, not automatic authorization to train a model. It should verify target definition, operational cutoff, feature availability, cohort construction, temporal validation, repeated-student dependence, class imbalance, calibration, confounding, subgroup reliability, and baseline comparisons before any model implementation is approved.

AN7 provides candidate associations for this review; it does not approve predictive features.

## 17. Final disposition

**AN7 analytical scope: CLOSED.**

The five SQL investigations, cohort and merge reconciliations, O1/O2/O3 estimates, 660-row sensitivity analysis, interpretation, visual review, and leakage controls are documented. No SQL rerun or database modification was required for closeout.

**AN10: not started and deliberately deferred.** The next workstream is AN8 — Validated Metrics & Marts, followed by AN9 — Power BI. AN10 will assess predictive readiness only after the descriptive reporting stage and remains a decision gate, not model training.

The overall analytical phase remains incomplete: validated metrics and analytical marts, Power BI reporting, and the consolidated project final report remain downstream deliverables. The separate Data Science / Machine Learning phase remains deferred until the analytical phase exit criteria are met.
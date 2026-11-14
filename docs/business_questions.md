# Business Questions

**Status:** AN5, AN6, and AN7 are closed within their approved investigative scopes. AN8 predictive readiness has not started.  
**Updated:** 2026-11-10

## Primary question

How can an online learning platform identify engagement patterns, academic risk, and factors associated with student success?

## Question families

### Engagement

- How does recorded student activity vary across module presentations, students, resources, and relative course days?
- How do recorded activity presence/coverage, distinct active days, and distinct resource breadth vary at registered student-presentation grain within the in-course window?
- How sensitive are click totals to repeated `student_vle` rows under R0, R1, and R2?
- How does recorded activity vary before, around, and after assessment days?

### Academic performance

- How are assessment submissions and scores distributed across module presentations and assessment types?
- Which learner, course, registration, and activity characteristics are associated with score and final-result differences?
- How do missing scores, banked submissions, and unavailable assessment dates affect metric denominators?

### Retention and withdrawal

- What patterns are observed among students with a recorded `Withdrawn` final result?
- How do registration and unregistration day values relate to observed activity and outcomes?
- What can be concluded from missing unregistration values, and what cannot be inferred?

### Risk indicators

- Can a transparent combination of prior activity and assessment information identify groups for further review?
- Which indicators are descriptive, and which would require a predictive evaluation design?
- How should model performance be validated and compared with a simple baseline if prediction is later justified?

## Analytical discipline

Keep four concepts distinct:

1. **Observation:** what the supplied records show.
2. **Association:** variables that vary together under a defined analysis.
3. **Prediction:** a model's ability to estimate an outcome on appropriately separated evaluation data.
4. **Causation:** a claim requiring a research design capable of supporting causal inference.

Do not describe an association as a cause. Do not finalize a KPI until its grain, numerator, denominator, exclusions, time basis, and validation query are documented.

## Next-phase gate

Before each new work order writes SQL, freeze a metric contract: business question, grain, eligible population, join path, numerator, denominator, time basis, inclusion/exclusion rules, missing/unmatched semantics, measures and units, sensitivity policy, expected reconciliations, and claims out of scope. The AN5 activity definition is documented in `docs/AN5_engagement_sensitivity_plan.md`. Repeated `student_vle` rows remain a metric-sensitivity issue; RAW and STAGING remain preserved.


## AN6 — Recorded VLE Activity Patterns

- Among all registered student-presentations, what proportion has at least one recorded VLE row within day 0 through presentation length, inclusive?
- How are zero-inclusive distinct active days and distinct resource IDs distributed?
- When is first in-course activity recorded among activity-bearing student-presentations?
- How does activity distribute across PRE/IN/POST and fixed seven-day relative periods?
- How do activity-type resource breadth and registered student-presentation reach vary, and how complete is resource metadata?

AN6 uses the fixed registered student-presentation denominator. The 89.68% AN5.02 overall coverage is not reused as an in-course estimate. Missing VLE records do not establish absence of learning.


### Questions raised by the AN6 execution review

- Do presentation-level temporal activity-row profiles remain materially different after normalization by registered student-presentations?
- How do activity-type row volume, distinct resource breadth, and registered reach compare when reported as separate dimensions?
- If activity-type row volume is used in reporting, how sensitive are type-specific volumes and rankings to R1/R2 repeated-row treatments?
- Among PRE_COURSE records, what share occurred before the individual student's registration date, after aligning the date basis correctly?
- Do missing week_from and week_to values overlap, and are missing values concentrated by activity type or module-presentation?
- Why are no POST_COURSE activity rows observed in the returned dataset, and what can be established about the source's observation boundary?
- Are early first activity, sustained distinct active days, and resource breadth descriptively associated with outcomes under a frozen, leakage-safe observation window?

These are follow-up questions, not findings or approved metrics. Activity-row volume remains sensitive to unresolved repeated source records; type-level reach is non-additive across activity types; and no-recorded-activity states describe the supplied VLE records rather than learning absence.


## AN7 — Outcome associations: answered questions

- Are post-registration active-day rates associated with withdrawal? Yes. O1 median Cliff's delta ranged from -0.178 to -0.197 across landmark-feature combinations; 20–22 of 22 presentation estimates were negative. Some confidence intervals include zero.
- Are post-registration activity measures associated with failure? Yes. O2 estimates were negative in all 22 presentations at L28, L56, and L84 for both features.
- Do activity measures vary monotonically with Fail < Pass < Distinction? Yes. O3 Spearman estimates were positive in all 22 presentations at all three landmarks.
- Does the O1 pattern depend materially on including eligible undated Withdrawn records? The broad direction remained similar; 130 of 132 paired estimates retained their sign. Actual withdrawal timing remains unknown.
- Do the nine Fail/date-unregistration records determine O2 direction? No. Excluding them left all 22 presentation estimates negative for both features at all landmarks.
- Does registration timing affect interpretation? Yes. The on-or-before-start stratum broadly reproduced primary O1 results. The after-start stratum had only 12/22 estimable comparisons and small comparison groups, so effect strength remains unresolved.

These findings are observational associations, not causes or evidence of predictive performance. Active-day rate is the primary candidate for AN8 readiness review; resource breadth is secondary because it is not normalized by exposure opportunity. Neither is an approved production KPI or model feature.

## AN8 — New predictive-readiness questions

- What operational decision, prediction cutoff, and target horizon would be justified?
- Can every candidate feature be shown to be available at that cutoff, including same-day registration/activity ambiguity?
- How should changing landmark cohorts and late registrations be handled?
- What temporal validation design prevents leakage across presentations and repeated student identities?
- Does active-day rate add information beyond resource breadth, and vice versa?
- How should class imbalance, calibration, subgroup reliability, confounding, and false-positive/false-negative trade-offs be assessed?
- Which baseline and evaluation metrics would be meaningful for the intended operational decision?

These are AN8 questions, not approved modelling decisions.

# Business Questions

**Status:** AN5 and AN6 are closed within their approved investigative scopes. AN7 remains gated by outcome-definition and temporal-leakage decisions.  
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


## AN7 — Outcome Associations (planned)

- Among registrations eligible at L28, L56, and L84, how are post-registration active days and resource breadth associated with the recorded Withdrawn label?
- Among eligible non-withdrawn outcomes, how do Fail versus Pass/Distinction groups differ in recorded activity?
- Among eligible non-withdrawn outcomes, is there a monotonic association between recorded activity and Fail < Pass < Distinction?
- Do associations differ by module-presentation and landmark?
- How sensitive are results to the 93 Withdrawn/no-date and nine Fail/with-date cases?
- Which assessment dates and stored weights fall before each landmark, without assuming score availability?

L28 (days 0–27), L56 (0–55), and L84 (0–83) are inclusive course-relative windows, not academic weeks. Primary activity features begin at the student's recorded registration day, bounded below by course day 0. Course-relative measures remain separate for AN6 reconciliation. Primary landmark eligibility excludes missing registration dates, registrations after the landmark, unregistrations on/before the landmark, and Withdrawn cases with missing unregistration dates. Activity is not truncated at unregistration. These are planned questions, not findings. final_result is an outcome, never a feature. No predictive model, causal claim, KPI, or intervention threshold is approved.

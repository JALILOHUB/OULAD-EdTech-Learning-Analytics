# Business Questions

**Status:** AN5 sensitivity analysis is complete. The operational definition of recorded in-course VLE activity is accepted for downstream analysis; AN6 and AN7 remain separate planned workstreams.  
**Updated:** 2026-11-07

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

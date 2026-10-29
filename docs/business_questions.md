# Business Questions

**Status:** Question design only. Analytical SQL and findings have not yet been produced.  
**Updated:** 2026-10-15

## Primary question

How can an online learning platform identify engagement patterns, academic risk, and factors associated with student success?

## Question families

### Engagement

- How does recorded student activity vary across module presentations, students, resources, and relative course days?
- Which engagement measures can be computed at a clearly defined grain without double-counting repeated `student_vle` keys?
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

Before writing analytical SQL, define the grain of each proposed output, map valid join paths, choose an initial small set of business questions, and document exact measure definitions. In particular, the `student_vle` repeated-key issue must be addressed at the metric-definition level; RAW rows must remain preserved.

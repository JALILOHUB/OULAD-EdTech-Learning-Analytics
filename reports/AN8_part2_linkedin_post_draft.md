# LinkedIn Draft — OULAD Part 2: When Activity Metrics Depend on Data Semantics

I have completed the extended AN8 investigation in my OULAD EdTech Learning Analytics project. The most important lesson was not how many records the platform contains — it was how easily a reporting decision can change the story those records tell.

Three findings stood out:

- **Repeated activity records materially affect click totals.** Keeping all source rows (R0) gives 39.61 million recorded clicks. Removing exact six-column duplicates (R1) reduces the total by 3.19%. Applying a five-key MAX assumption (R2) reduces it by 13.14%. The source does not establish which repeated-row interpretation is correct, so neither scenario is treated as ground truth.
- **Course timing matters.** 688,988 activity rows — 6.47% of the source — occurred before the course-relative day zero. Counting them as in-course engagement would overstate course activity.
- **A zero-activity cohort must not disappear.** 3,365 of 32,593 student-presentations had no recorded VLE activity row in the retained extract. This does not prove that students did not learn; it shows why the reporting denominator and the meaning of “no recorded activity” must be explicit.

I also kept 45 registrations with missing registration dates separate from observed zero activity. Their registration-relative exposure is unknown, not zero.

These results changed the next step of the project. Rather than applying a blanket deduplication or imputation rule, I am moving into a dedicated deep-cleaning and validation workstream: versioned derived datasets, row-level transformation lineage, before/after reconciliation, and sensitivity analysis.

The original source evidence remains preserved. The goal is to make the reporting layer more trustworthy before building Power BI measures — and before considering any predictive model.

#LearningAnalytics #DataQuality #PostgreSQL #DataAnalytics #EdTech #PowerBI #DataEngineering

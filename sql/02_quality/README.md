# Data Quality SQL

**Current status:** Core checks have been executed and results recorded. The registry currently contains 29 distinct test codes: 25 `PASS` and 4 `REVIEW`.

## Canonical scripts

- `01_validate_candidate_keys.sql` — candidate-key completeness and uniqueness checks; the `student_vle` key is expected to remain under review.
- `02_validate_relationships.sql` — tested parent and enrollment/reference relationships.
- `03_data_quality_registry.sql` — creates `quality.test_results`.
- `04_seed_initial_quality_results.sql` — idempotent-by-test-code seed for the initial B2/B3 findings; checks existing codes before inserting.
- `05_recheck_completeness.sql` — documented missing-token checks.
- `06_validate_values_and_ranges.sql` — numeric and categorical checks.
- `07_validate_temporal_consistency.sql` — registration, assessment timing, activity day, and VLE week diagnostics.
- `08_characterize_student_vle_duplicates.sql` — deeper characterization of repeated candidate keys and fully identical rows.
- `09_record_b5_results.sql` — records B5 results only for test codes not already present.

## Interpretation rules

- A query that returns no out-of-domain records applies only to the accepted-value list used in that query; document its source before changing the corresponding registry status.
- `REVIEW` is appropriate when evidence has been observed but its business/source meaning is not settled.
- Do not mark negative relative days, late submissions, or repeated records as errors by default.
- Do not delete records or aggregate `sum_click` solely to make a candidate key unique.
- The historical registry `executed_at` values remain NULL because exact historical execution timestamps were not captured. Do not invent them.

## Execution notes

Run each result-producing `SELECT` separately in pgAdmin when you need each result set. Seed scripts avoid inserting already present test codes, but they do not update an existing result if its description or status changes. Review changes before executing write statements.

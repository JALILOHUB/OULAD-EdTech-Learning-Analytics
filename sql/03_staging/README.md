# STAGING SQL Layer

**Current status:** Seven typed tables have been created and the reported C2 and S1–S4 checks have completed successfully.

## Files and order

1. `01\\\_validate\\\_staging\\\_conversions.sql` — pre-conversion checks against RAW source values (C2).
2. `02\\\_create\\\_staging\\\_table.sql` — creates the seven typed STAGING tables from RAW.
3. `03\\\_validate\\\_staging\\\_integrity.sql` — validates row counts, selected data types, missing-value reconciliation, numeric bounds, VLE week ranges, and the preserved `student\\\_vle` candidate-key pattern.

## Transformation rules

The documented `?` token is converted to SQL `NULL` only in the selected STAGING fields: `assessments.date`, the two registration date fields, `student\\\_assessment.score`, `student\\\_info.imd\\\_band`, and `vle.week\\\_from` / `vle.week\\\_to`. Their types are INTEGER except for `score` (NUMERIC) and `imd\\\_band` (TEXT).

All seven STAGING row counts match RAW. No rows were deleted. `student\\\_vle` retains 10,655,280 rows and the observed 2,195,960 excess rows relative to its 8,459,320 distinct five-column candidate-key combinations.

## Execution caution

The creation script has already been executed in the current database. Do not re-run it against the existing `staging` tables. `CREATE TABLE AS SELECT` does not automatically copy all constraints and indexes from RAW. Any future constraints or indexes must be selected and validated separately.


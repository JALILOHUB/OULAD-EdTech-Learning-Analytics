# STAGING SQL Layer

**Current status:** Seven typed tables have been created and the reported C2 and S1–S4 checks have completed successfully.

## Files and order

1. `01_validate_staging_conversions.sql` — pre-conversion checks against RAW source values (C2).
2. `02_create_staging_table.sql` — creates the seven typed STAGING tables from RAW.
3. `03_validate_staging_integrity.sql` — validates row counts, selected data types, missing-value reconciliation, numeric bounds, VLE week ranges, and the preserved `student_vle` candidate-key pattern.

## Transformation rules

The documented `?` token is converted to SQL `NULL` only in the selected STAGING fields: `assessments.date`, the two registration date fields, `student_assessment.score`, `student_info.imd_band`, and `vle.week_from` / `vle.week_to`. Their types are INTEGER except for `score` (NUMERIC) and `imd_band` (TEXT).

All seven STAGING row counts match RAW. No rows were deleted. `student_vle` retains 10,655,280 rows and the observed 2,195,960 excess rows relative to its 8,459,320 distinct five-column candidate-key combinations.

## Execution caution

The creation script has already been executed in the current database. Do not re-run it against the existing `staging` tables. `CREATE TABLE AS SELECT` does not automatically copy all constraints and indexes from RAW. Any future constraints or indexes must be selected and validated separately.

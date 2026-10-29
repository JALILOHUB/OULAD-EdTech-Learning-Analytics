# RAW SQL Layer

**Current status:** Created and loaded; row counts reconciled against the established baseline.

## Files

- `01_create_raw_tables.sql` defines the seven RAW tables with types and primary keys justified by source profiling.
- `02_load_raw.sql` loads the seven OULAD CSV files using PostgreSQL `COPY` and includes the baseline row-count query.

## Design rules

- Preserve source column values, including literal `?` tokens.
- Use validated PostgreSQL types; source fields containing missing-value tokens remain nullable text where required.
- Do not clean, deduplicate, aggregate, or apply business rules in RAW.
- `raw.student_vle` intentionally has no primary key because its tested five-column candidate key is not unique.
- Six other RAW tables have primary keys based on the candidate-key validation results. No RAW foreign keys are defined; reference consistency was tested with SQL queries.

## Execution caution

The `COPY` statements are not idempotent against already populated tables. Do not re-run the load script on the existing project database unless the target tables have been deliberately prepared for a full reload. Do not re-create the existing tables as a routine step.

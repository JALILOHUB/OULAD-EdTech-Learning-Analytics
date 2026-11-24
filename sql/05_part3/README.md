# Part 3 — Source Semantics and Controlled Cleaning

**Status:** P3.00–P3.08 are prepared SELECT-only diagnostics. The importer dry-run passed on 2026-11-24. The isolated database, source import, and all P3 SQL executions remain pending.

## Execution contract

The scripts target the isolated oulad_an8_work database and the source_ref schema. They assume the seven source CSVs have been imported with their original column names and all source fields retained as TEXT. Empty strings and the literal question-mark token remain distinguishable. Numeric parsing uses guarded regular-expression checks so unexpected tokens are not silently cast or discarded.

The P3 diagnostic SQL is read-only. Do not run these files against oulad_analytics, RAW, QUALITY, or STAGING. No script in this package approves deletion, deduplication, imputation, or source correction.

## Query inventory

| Query | File | Purpose | Runtime |
|---|---|---|---|
| P3.00 | P3.00_source_inventory_and_profile.sql | Relation/column inventory and exact row counts | HIGH |
| P3.01 | P3.01_student_vle_repeated_event_semantics.sql | Bounded representative raw rows from conflicting five-key groups; reuse AN8.30 for R0/R1/R2 sensitivity | HIGH |
| P3.02 | P3.02_relative_day_semantics.sql | Negative/zero/positive offsets, boundaries, linked source rows | HIGH |
| P3.03 | P3.03_registration_missingness_and_exposure.sql | Missing registration records with linked learner/activity context | HIGH |
| P3.04 | P3.04_zero_activity_cohort_semantics.sql | Full registered cohort with one mutually exclusive temporal state and row-level activity counts | HIGH |
| P3.05 | P3.05_assessment_sentinel_and_score_semantics.sql | date_submitted=-1, banked/score states, candidate keys, missing due-date links | MEDIUM |
| P3.06 | P3.06_categorical_and_numeric_domain_audit.sql | Category tokens/domains and numeric ranges, including VLE day/click fields | HIGH |
| P3.07 | P3.07_cross_domain_grain_and_join_validation.sql | Candidate-key uniqueness, cohort reconciliation, and activity reference-match cardinality | HIGH |
| P3.08 | P3.08_educational_indicator_baseline.sql | Source-faithful educational indicator baseline by presentation/outcome | HIGH |

## Required operating rules

1. Execute P3.00 once after import. Confirm all seven source relations, column names, and exact row counts.
2. Execute P3.07 next as the key/join gate. Review duplicate keys, cohort key-set differences, join row counts, and activity reference-match cardinalities before relying on cross-domain joins.
3. Run high-cost queries individually; do not run multiple full student_vle scans concurrently.
4. Review actual source rows before deciding the meaning of any negative or sentinel value.
5. Preserve every source value. These queries are SELECT-only and do not create derived tables.
6. Keep R0 as source-faithful. R1 and R2 are sensitivity scenarios only; neither is approved as source truth.
7. Do not convert relative days into calendar dates until an exact authoritative presentation start date is established.
8. Do not interpret absence of VLE records as absence of learning.
9. Record every later approved transformation in an audit register with rule ID, evidence, affected keys/rows, before/after impact, alternatives, and approval.
10. No persistent DDL, index, data update, or deletion is authorized by this package.

All query files contain the required Question, Expectation, Grain, Source, Safety, Runtime, and Read as headers.

## Isolated source workspace

- Original source: data/raw/ (immutable).
- Recovery copy: data/Backup/raw/ (immutable).
- Part 3 import input: data/working/raw/ (sole operational input).
- oulad_dataset.zip remains in all three locations; only the seven CSV files are imported.

The owner verified the eight-file SHA-256 comparison and backup-manifest checks on 2026-11-22. The importer dry-run was subsequently executed successfully on 2026-11-24 using the project virtual environment. All seven CSV files passed SHA-256 and column-set validation. The dry-run did not connect to PostgreSQL or change any database.

## One-time setup and execution sequence

1. Synchronize feat/an8-part3-semantic-cleaning locally and confirm a clean working tree.
2. Confirm that oulad_an8_work does not already exist. Never drop or recreate it automatically.
3. From a PostgreSQL maintenance connection (for example, postgres), execute sql/00_database/02_create_oulad_an8_work.sql once.
4. Connect to oulad_an8_work and execute sql/05_part3/00_create_source_ref_tables.sql once.
5. The 2026-11-24 dry-run is already verified. Do not repeat it unless the importer, working CSVs, or backup manifest changes.
6. Run .venv\\Scripts\\python.exe scripts/import_part3_source.py from the project root. The importer connects only to oulad_an8_work, verifies the exact target database and empty source tables, imports all seven CSVs in one transaction, checks expected COPY row counts, and rolls back the transaction on failure.
7. Run P3.00 once and review all three result sets (column inventory, exact row counts, and relation inventory).
8. Run P3.07 and review its key/join gates before other cross-domain diagnostics.
9. Run P3.01 for bounded conflicting source-row samples; do not recompute AN8.30 R0/R1/R2 sensitivity. Continue with P3.02–P3.06 in evidence-led order, one high-cost scan at a time. Run P3.08 only if AN8.35/AN8.36 retained outputs do not already provide the required source-faithful baseline.
10. Execute one query per invocation with .venv\\Scripts\\python.exe scripts/run_part3.py --query P3.00 (replace the ID for the next approved query). The runner enforces a read-only session, targets only oulad_an8_work, exports every result set without a row cap, and writes a timestamped execution manifest and CSVs under outputs/an8/part3/.
11. Review the exported files in notebooks/11_an8_part3_semantic_analysis.ipynb; do not use Run All across query gates.

The importer uses the existing local .env connection settings for host, port, user, and password, but hard-codes the target database name as oulad_an8_work; it deliberately ignores DB_NAME to prevent accidental connection to oulad_analytics. Empty CSV fields are retained as empty strings using the explicit COPY NULL marker \N; literal question-mark values are preserved. All imported columns are TEXT. The ZIP archive is not imported.

**Execution boundary:** database creation, schema/table creation, CSV import, and P3 SQL execution are not complete until owner-returned local outputs are reviewed. No result should be inferred from the presence of these scripts.

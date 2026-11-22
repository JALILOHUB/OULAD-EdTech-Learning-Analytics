# Part 3 — Source Semantics and Controlled Cleaning

**Status:** SQL diagnostics authored; not executed. No database, schema, table, index, or source file was created or modified by these scripts.

## Execution contract

The scripts target the isolated `oulad_an8_work` database and the `source_ref` schema. They assume the seven source CSVs have been imported with their original column names and all source fields retained as TEXT. Empty strings are treated as missing for profiling; the literal `?` remains a separate source token. Numeric parsing uses guarded regular-expression checks so unexpected tokens are not silently cast or discarded.

The database and import contract are prerequisites, not part of this read-only SQL package. Do not run these files against `oulad_analytics`, RAW, QUALITY, or STAGING. No Part 3 database setup or import is included here.

## Query inventory

| Query | File | Purpose | Runtime |
|---|---|---|---|
| P3.00 | `P3.00_source_inventory_and_profile.sql` | Relation/column inventory and exact row counts | HIGH |
| P3.01 | `P3.01_student_vle_repeated_event_semantics.sql` | Repeated-key groups, click-value conflicts, R0/R1/R2 sensitivity | HIGH |
| P3.02 | `P3.02_relative_day_semantics.sql` | Negative/zero/positive offsets, boundaries, linked sample rows | HIGH |
| P3.03 | `P3.03_registration_missingness_and_exposure.sql` | Missing registration records with linked learner/activity context | HIGH |
| P3.04 | `P3.04_zero_activity_cohort_semantics.sql` | No-row, pre-course-only, in-course, and other temporal activity states | HIGH |
| P3.05 | `P3.05_assessment_sentinel_and_score_semantics.sql` | `date_submitted=-1`, banked, NULL/zero/nonzero score, key checks | MEDIUM |
| P3.06 | `P3.06_categorical_and_numeric_domain_audit.sql` | Category tokens/domains and numeric ranges across source files | MEDIUM |
| P3.07 | `P3.07_cross_domain_grain_and_join_validation.sql` | Candidate-key uniqueness and join fan-out controls | MEDIUM |
| P3.08 | `P3.08_educational_indicator_baseline.sql` | Source-faithful educational indicator baseline by presentation/outcome | HIGH |

## Required operating rules

1. Execute P3.00 first. Confirm all seven source relations and their column names before running later files.
2. Review actual sample rows before deciding the meaning of any negative/sentinel value.
3. Preserve every source value. These queries are SELECT-only and do not create derived tables.
4. Keep R0 as source-faithful. R1 and R2 are sensitivity scenarios only; neither is approved as source truth.
5. Do not convert relative days into calendar dates until an exact authoritative presentation start date is established.
6. Do not interpret absence of VLE records as absence of learning.
7. Record every later approved transformation in the audit register with rule ID, evidence, affected keys/rows, before/after impact, alternatives, and approval.
8. No persistent DDL, index, data update, or deletion is authorized by this package.

All query files contain the required Question, Expectation, Grain, Source, Safety, Runtime, and Read as headers.


## Isolated source workspace setup

The owner-approved source workspace is:

- Original source: `data/raw/` (immutable).
- Recovery copy: `data/Backup/raw/` (immutable).
- Part 3 import input: `data/working/raw/` (the only operational input).
- Archive: `oulad_dataset.zip` is retained in all three locations; the importer reads the seven CSVs only.

The eight-file SHA-256 comparison and all eight backup-manifest checks were verified locally by the owner on 2026-11-22. Do not delete or recopy any of these folders as part of this setup.

### One-time setup sequence

1. Synchronize `feat/an8-part3-semantic-cleaning` locally and confirm a clean working tree.
2. Confirm that `oulad_an8_work` does not already exist. Never drop or recreate it automatically.
3. From a PostgreSQL maintenance connection (for example, `postgres`), execute `sql/00_database/02_create_oulad_an8_work.sql` once.
4. Connect to `oulad_an8_work` and execute `sql/05_part3/00_create_source_ref_tables.sql` once.
5. From the project root, run `python scripts/import_part3_source.py --dry-run`. This validates the seven working CSV hashes against the backup manifest and checks their exact headers without connecting to PostgreSQL.
6. If the dry run passes, run `python scripts/import_part3_source.py`. The importer connects only to `oulad_an8_work`, verifies the target database and empty source tables, imports all seven CSVs in one transaction, checks expected COPY row counts, and rolls back the entire import on failure.
7. Run P3.00 once and review all three result sets (column inventory, exact row counts, and relation inventory) before proceeding to any other P3 query.

The importer uses the existing local `.env` connection settings for host, port, user, and password, but hard-codes the target database name as `oulad_an8_work`; it deliberately ignores `DB_NAME` to prevent accidental connection to `oulad_analytics`. Empty CSV fields are retained as empty strings by using the explicit COPY NULL marker `\\N`; literal `?` values are preserved. All imported columns are TEXT. The ZIP archive is not imported.

**Execution boundary:** the setup scripts and importer are prepared artifacts. Database creation, schema/table creation, CSV import, and P3.00 execution remain local owner actions and must not be reported as complete until their outputs are returned and reviewed.

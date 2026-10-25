# Analytics SQL Layer

**Current status:** Analytical views are not yet implemented. WO-1 establishes read-only readiness and relationship diagnostics; it creates no analytical views.

## Canonical query files

- `AN0.01_database_identity.sql` — database identity and read-only session settings.
- `AN0.02_quality_registry_snapshot.sql` — reconciliation of the existing registry with its documented historical state; completed quality tests are not rerun.
- `AN0.03_staging_row_count_reconciliation.sql` — exact STAGING row counts compared with the historical baseline.
- `AN0.04_staging_relation_sizes_and_indexes.sql` — physical relation sizes and existing index definitions.
- `AN1.01_student_key_uniqueness.sql` — completeness and uniqueness of student-presentation keys.
- `AN1.02_student_key_set_reconciliation.sql` — comparison of composite-key sets in both directions.
- `AN1.03_student_assessment_join_fanout.sql` — effect of joining assessment rows to students by student ID alone.
- `AN2.01_student_presentation_profile.sql` — student and registration counts by presentation; gated by AN1.01.
- `AN2.02_final_result_distribution.sql` — final-result distribution within presentations; gated by AN1.01.

## Notebook and SQL conventions

The notebook `notebooks/04_sql_analytics.ipynb` invokes canonical files by stable query ID through `src/analytics/db.py`. Each query is maintained in its own SQL file and produces a defined result. SQL definitions are not duplicated in notebook code cells.

Before an analytical query or view is accepted, its documentation records:

1. Business question.
2. Output grain.
3. Join paths and their justification.
4. Measures, denominators, exclusions, and time basis.
5. Validation against source-level counts or independent SQL checks.
6. Decisions and limitations in `docs/analysis_log.md`.

Repeated-key behavior in `student_vle` remains an explicit modelling limitation. Aggregation decisions depend on a validated metric definition. WO-1 creates no views, indexes, or tables.

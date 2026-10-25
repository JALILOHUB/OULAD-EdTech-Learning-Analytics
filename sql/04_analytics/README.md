# ANALYTICS SQL Layer

**Current status:** Analytical views have not yet been implemented. WO-1 adds read-only readiness and relationship diagnostics; it does not create analytical views.

## Canonical query files

- `AN0.01_database_identity.sql` — confirm database identity and read-only session settings.
- `AN0.02_quality_registry_snapshot.sql` — compare the current registry with the documented historical state without rerunning quality tests.
- `AN0.03_staging_row_count_reconciliation.sql` — compare exact STAGING counts with the historical baseline.
- `AN0.04_staging_relation_sizes_and_indexes.sql` — inspect physical sizes and existing indexes.
- `AN1.01_student_key_uniqueness.sql` — validate student-presentation key completeness and uniqueness.
- `AN1.02_student_key_set_reconciliation.sql` — compare the two complete composite-key sets.
- `AN1.03_student_assessment_join_fanout.sql` — quantify the effect of joining assessment rows to students by student ID alone.
- `AN2.01_student_presentation_profile.sql` — compare student and registration counts by presentation; gated by AN1.01.
- `AN2.02_final_result_distribution.sql` — summarize final outcomes within presentations; gated by AN1.01.

## Notebook execution contract

The notebook `notebooks/04_sql_analytics.ipynb` calls these canonical files by stable query ID through `src/analytics/db.py`. Do not copy SQL text into notebook cells. Keep each SQL file to one result-producing statement.

Before creating a query or view:

1. State the business question.
2. Define the output grain.
3. Identify and justify join paths.
4. Define measures, denominators, exclusions, and time basis.
5. Validate the result against source-level counts or independent SQL checks.
6. Record decisions and limitations in `docs/analysis_log.md`.

Do not begin by aggregating `student_vle` until the repeated-key issue has been accounted for in the proposed metric definition. WO-1 creates no views, indexes, or tables.

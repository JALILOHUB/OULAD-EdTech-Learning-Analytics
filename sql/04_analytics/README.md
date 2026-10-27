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
- `AN1.04_course_presentation_relationships.sql` — course-key uniqueness and student-to-course join cardinality.
- `AN1.05_assessment_metadata_relationships.sql` — assessment-key uniqueness and submission-to-metadata cardinality.
- `AN1.06_registration_person_grain.sql` — student-presentation registrations versus distinct people and presentation counts per person.
- `AN1.07_activity_coverage_by_presentation.sql` — recorded VLE activity coverage among matching registered student-presentations.
- `AN1.08_registrations_without_activity.sql` — registered student-presentations without a matching recorded VLE activity row.
- `AN1.09_vle_resource_match_coverage.sql` — activity-to-resource metadata match coverage and key-grain diagnostics.
- `AN2.01_student_presentation_profile.sql` — student and registration counts by presentation; gated by AN1.01.
- `AN2.02_final_result_distribution.sql` — final-result distribution within presentations; gated by AN1.01.
- `AN2.03_presentation_size_profile.sql` — presentation population and course-length profile.
- `AN2.04_gender_age_disability_distribution.sql` — descriptive demographic-category distributions by presentation.
- `AN2.05_region_education_distribution.sql` — regional and education-category distributions by presentation.
- `AN2.06_numeric_student_profile.sql` — previous-attempt and studied-credit distributions by presentation.
- `AN2.07_imd_missing_by_presentation.sql` — IMD-band missingness by presentation.
- `AN2.08_imd_missing_by_region.sql` — IMD-band missingness by recorded region, retaining NULL region.
- `AN2.09_imd_missing_by_final_result.sql` — IMD-band missingness by recorded final-result category, retaining NULL values.

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


## WO-1B scope and execution status

WO-1B extends the initial readiness checks with relationship-cardinality, registration/activity coverage, resource-metadata coverage, and selected descriptive-profile diagnostics. The additional query definitions are intended to remain read-only and do not create views, indexes, tables, or constraints.

The WO-1B query definitions are prepared for local schema review and execution. Their presence in this repository does not establish that they have run or that their expectations were met. Record execution evidence and interpretation in `docs/analysis_log.md`. Run potentially heavy activity queries individually with the longer timeout only after the local runner change has been reviewed and tested.

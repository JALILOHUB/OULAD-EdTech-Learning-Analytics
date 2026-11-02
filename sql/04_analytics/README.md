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


## Work-order organization and execution status

WO-1 is the historical evidence notebook and remains unchanged. Future work orders use separate notebooks grouped by analytical dependencies; the canonical SQL files remain the single source of truth and are invoked through `src/analytics/db.py`. The official analytical identifiers remain AN0–AN11; notebook group labels (WO2-A through WO2-E) do not replace or renumber them.

WO-2 SQL files are prepared and reviewed separately from repository integration. Their presence in an external ZIP archive does not establish that they are part of this directory. No WO-2 query is recorded as executed until actual PostgreSQL output is reviewed.

## WO-1B scope and execution status

WO-1B extends the initial readiness checks with relationship-cardinality, registration/activity coverage, resource-metadata coverage, and selected descriptive-profile diagnostics. The additional query definitions are intended to remain read-only and do not create views, indexes, tables, or constraints.

The saved notebook contains historical outputs for the canonical AN0.01–AN0.04, AN1.01–AN1.09, and AN2.01–AN2.09 queries. These outputs document a prior local PostgreSQL session; they are not a fresh execution during this documentation review. The owner subsequently completed focused reconciliation for AN2.02, AN2.04, and AN2.05 across 132 groups, as recorded in `docs/analysis_log.md` and the progress ledger. Do not rerun the entire notebook solely to update status. The non-unique `student_vle` candidate key remains unresolved, and no analytical views have been created.


## WO-2 preparation boundary

The shared runner supports multiple SELECT result sets while retaining the legacy first-result keys. It uses Psycopg's simple-query execution path and result-set navigation; SQL text is not split on semicolons. Result rows are capped independently for display. `elapsed_seconds` is the total SQL-file batch duration; per-statement server timings are not currently available from this runner.

Synthetic runner tests are maintained in `tests/test_analytics_db_runner.py`. Their presence is not evidence that they have been executed. The runner and tests must pass local validation before any WO-2 SQL is run against the project database. AN3.06 is a high-runtime scan and must be run alone with an explicit timeout.


## WO-2 canonical SQL inventory

The following read-only investigations are maintained as individual canonical SQL files. They have been statically reviewed and prepared for controlled execution; their presence does not mean they have been run against the project database.

| Query | File | Purpose |
|---|---|---|
| AN0.07 | `AN0.07_raw_primary_key_verification.sql` | Verify documented RAW primary keys, constraint types, and all student_vle indexes. |
| AN1.10 | `AN1.10_assessment_fanout_decomposition.sql` | Decompose and reconcile assessment-join fan-out. |
| AN2.10 | `AN2.10_imd_missingness_extension.sql` | Profile IMD missingness by module, region, presentation, and cross-presentation alternatives. |
| AN3.01 | `AN3.01_final_result_vs_unregistration.sql` | Cross-tabulate final-result labels and unregistration-date presence. |
| AN3.02 | `AN3.02_withdrawal_definition_conflicts.sql` | Identify withdrawal-definition conflicts and compare dates with presentation length. |
| AN3.03 | `AN3.03_withdrawal_timing_distribution.sql` | Classify unregistration timing relative to presentation start and end. |
| AN3.04 | `AN3.04_registration_timing_profile.sql` | Profile registration timing and descriptive withdrawal rates. |
| AN3.05 | `AN3.05_registration_unregistration_order.sql` | Check registration/unregistration date ordering. |
| AN3.06 | `AN3.06_withdrawn_activity_absence.sql` | Compare Withdrawn student-presentations with recorded VLE activity and registration matches. |
| AN3.07 | `AN3.07_outcome_rates_by_attempts_education.sql` | Describe outcome shares by previous attempts and education. |
| AN3.08 | `AN3.08_withdrawal_rate_by_presentation.sql` | Describe withdrawal and pass/distinction shares by presentation. |
| AN4.01 | `AN4.01_assessment_structure_by_presentation.sql` | Describe assessment structure, weights, and due-date coverage. |
| AN4.02 | `AN4.02_assessments_missing_date.sql` | Profile assessments with missing due dates and linked submissions. |
| AN4.03 | `AN4.03_submission_timing_vs_due_date.sql` | Compare submission dates with due dates by banked status. |
| AN4.04 | `AN4.04_submissions_without_due_date.sql` | Profile submissions linked to assessments without due dates. |
| AN4.05 | `AN4.05_score_profile_and_null_scores.sql` | Describe score distributions and NULL scores by banked status. |
| AN4.06 | `AN4.06_banked_assessments_profile.sql` | Profile observed banked-flag values before timing interpretation. |
| AN4.07 | `AN4.07_assessment_participation_by_outcome.sql` | Describe submission participation by outcome and banked status, retaining zero-submission student-presentations. |
| AN4.08 | `AN4.08_score_by_final_result.sql` | Describe non-NULL scores by outcome, assessment type, and banked status. |
| AN4.09 | `AN4.09_submissions_after_unregistration.sql` | Compare submission and unregistration day values. |
| AN4.10 | `AN4.10_weighted_score_grain_check.sql` | Check student-assessment grain and submitted assessment-weight coverage. |

## WO-2 static-review corrections

- AN3.03 checks `date_unregistration > module_presentation_length` before assigning in-course week buckets, preventing post-course dates from being misclassified when a presentation is shorter than a bucket boundary.
- AN3.06 uses a LEFT JOIN to registration and reports `NO_REGISTRATION_MATCH` separately from a matched registration with a NULL unregistration date. Recorded-activity absence remains narrowly defined as no matching row in `staging.student_vle`.
- AN4.08 reports distinct student-presentations rather than implying that a person is unique across multiple presentations.
- AN4.10 removes the non-informative `zero_weight_rows` indicator. The submitted-weight aggregation and banked-status grouping remain unchanged.
- Historical or directional expectations are explicitly treated as hypotheses/reconciliation references, not forced acceptance criteria.

The single orchestration notebook is `notebooks/05_wo2_analytical_investigation.ipynb`. It invokes these files through `src/analytics/db.py`, displays all result sets, and enforces manual review checkpoints. Its live-execution gate defaults to disabled. AN3.06 must run alone with an explicit timeout; AN4.06 precedes AN4.03.

**Execution status:** no WO-2 query is recorded as executed. No database query was run while preparing this inventory. RAW and STAGING remain unchanged.

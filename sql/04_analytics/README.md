# Analytics SQL Layer

**Current status:** WO-1, WO-2, and AN5 read-only investigations are executed and documented in retained notebooks. AN5 is closed with an accepted operational definition of recorded in-course VLE activity. No analytical views, marts, composite engagement score, or causal/predictive definitions have been implemented.

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

The canonical WO-2 SQL files are maintained in this directory and were executed against the user's local PostgreSQL database. Their saved outputs are retained in `notebooks/05_wo2_analytical_investigation.ipynb`; the 2026-11-06 handover records the 21-query execution and review boundary.

## WO-1B scope and execution status

WO-1B extends the initial readiness checks with relationship-cardinality, registration/activity coverage, resource-metadata coverage, and selected descriptive-profile diagnostics. The additional query definitions are intended to remain read-only and do not create views, indexes, tables, or constraints.

The saved notebook contains historical outputs for the canonical AN0.01–AN0.04, AN1.01–AN1.09, and AN2.01–AN2.09 queries. These outputs document a prior local PostgreSQL session; they are not a fresh execution during this documentation review. The owner subsequently completed focused reconciliation for AN2.02, AN2.04, and AN2.05 across 132 groups, as recorded in `docs/analysis_log.md` and the progress ledger. Do not rerun the entire notebook solely to update status. The non-unique `student_vle` candidate key remains unresolved, and no analytical views have been created.


## WO-2 runner and execution notes

The shared runner supports multiple SELECT result sets while retaining the legacy first-result keys. It uses Psycopg's simple-query execution path and result-set navigation; SQL text is not split on semicolons. Result rows are capped independently for display. `elapsed_seconds` is the total SQL-file batch duration; per-statement server timings are not currently available from this runner.

GitHub Actions and synthetic runner tests were retired on 2026-11-06 because they exercised synthetic fixtures rather than the actual OULAD analytical workload. They are not prerequisites or acceptance gates. Validate canonical SQL through controlled read-only execution against `oulad_analytics`, review returned outputs, and reconcile grains, joins, denominators and row counts. AN3.06 is a high-runtime scan and must be run alone with an explicit timeout.


## WO-2 canonical SQL inventory

The following read-only investigations are maintained as individual canonical SQL files. WO-2 queries AN0.07, AN1.10, AN2.10, AN3.01–AN3.08, and AN4.01–AN4.10 were executed against the project database; their saved outputs are retained in the WO-2 notebook. AN5.01–AN5.05 were executed locally; eight expected result sets and their quantitative review are retained in `notebooks/07_an5_engagement_sensitivity.ipynb`.

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

**Execution status:** all 21 canonical WO-2 queries were executed and their saved outputs reviewed as documented in the 2026-11-06 handover. RAW and STAGING remain unchanged.


## 2026-11-05 — AN0.07 local execution evidence (historical snapshot)

The project owner executed the corrected `AN0.07_raw_primary_key_verification.sql` locally. The query returned all three expected result sets in 0.191 seconds, with no truncated result sets:

- Seven RAW tables were returned. Six documented primary keys matched the actual validated primary keys; `student_vle` returned the expected `EXPECTED_NO_PK` status.
- The constraint inventory returned six primary keys and zero unique, foreign-key, or check constraints.
- The `raw.student_vle` index inventory returned zero rows.

This is user-returned execution evidence, reviewed in the project conversation. The empty index inventory does not establish row uniqueness and does not authorize index creation. No RAW/STAGING data or persistent database objects were changed. AN1.01's fresh dependency refresh and AN1.10 remain pending.


## WO-2 execution closure and AN5 routing

The saved notebook `notebooks/05_wo2_analytical_investigation.ipynb` records 21 executed canonical queries, 28 result sets, 857 displayed rows, 34 executed code cells, no saved tracebacks, and no runner row-cap truncation. The sum of query-batch elapsed times is 10.099 seconds; it is not an end-to-end notebook runtime. The execution outputs are historical local PostgreSQL evidence and were not rerun during this documentation review.

**Historical status at the 2026-11-06 checkpoint (superseded):** AN5 was then active and its five-query extension was still under review. PR #13 was subsequently merged, quantitative review was completed, and AN5 was closed on 2026-11-07. The current AN5 disposition is documented below and in `docs/AN5_engagement_sensitivity_plan.md` Section 17.


## AN5 — Engagement Sensitivity

The AN5 design and closure decision are documented in `docs/AN5_engagement_sensitivity_plan.md`. Five read-only scenario investigations were executed and reviewed. `01_student_engagement_template.sql` is an unexecuted design scaffold, not a canonical query or implemented analytics view; it is retained as a future design reference and is not part of AN6's approved SQL inventory.

| Query | File | Purpose |
|---|---|---|
| AN5.01 | `AN5.01_student_vle_scenario_reconciliation.sql` | Reconcile five-column candidate keys, exact six-column duplicates, R0/R1/R2 row counts, and activity-to-registration matches. |
| AN5.02 | `AN5.02_student_presentation_activity_sensitivity.sql` | Compare recorded click volume, activity presence, student-active-day pairs, and student-active-site pairs at registered student-presentation grain using a common denominator. |
| AN5.03 | `AN5.03_temporal_activity_sensitivity.sql` | Compare pre-course, in-course, and post-course activity under each scenario and retain unmatched activity separately. |
| AN5.04 | `AN5.04_student_ranking_sensitivity.sql` | Compare within-presentation student ranks, rank displacement, Spearman correlation, and top-decile overlap across scenarios. |
| AN5.05 | `AN5.05_outcome_group_activity_sensitivity.sql` | Compare activity measures by final-result group within presentations and diagnose registration-to-profile matching. |

The orchestration notebook is `notebooks/07_an5_engagement_sensitivity.ipynb`; the command-line entry point is `scripts/run_an5.py`. Both use the shared read-only runner and require a successful AN0.01 preflight. The notebook follows WO-1's direct-cell execution style without per-query prompts; run cells individually, not with Run All. The script runs selected queries sequentially and can optionally export bounded outputs.

**Execution status:** AN5.01–AN5.05 have been executed against the owner's local PostgreSQL database. The saved notebook retains eight expected result sets, the Python-only quantitative review/export, and eight visualizations. AN5 is closed; its accepted operational definition and limits are documented in `docs/AN5_engagement_sensitivity_plan.md`. Preserve RAW and STAGING unchanged. No composite KPI or causal/predictive claim is approved.



## AN6 — Recorded VLE Activity Patterns

AN6 is **closed** for its approved descriptive scope. The canonical read-only queries are retained in this directory and their complete local execution outputs are preserved in `notebooks/08_an6_recorded_vle_activity_patterns.ipynb`.

| Query | File | Result sets | Returned rows | Batch runtime |
|---|---|---:|---:|---:|
| AN6.01 | `AN6.01_activity_readiness_and_metadata.sql` | 3 | 22, 1, 1 | 27.348 s |
| AN6.02 | `AN6.02_in_course_student_presentation_metrics.sql` | 1 | 88 | 156.565 s |
| AN6.03 | `AN6.03_relative_time_patterns.sql` | 1 | 971 | 154.189 s |
| AN6.04 | `AN6.04_activity_type_resource_patterns.sql` | 1 | 254 | 247.918 s |

All six result sets were retrieved without truncation. AN6.01 readiness passed; AN6.02 coverage-state partition passed; AN6.03 temporal-bucket/relative-period totals, AN6.02 reach, and boundary diagnostics reconciled; and AN6.04 resource metadata and registered in-course activity-type totals reconciled.

### Verified analytical outputs

- Registered student-presentations: 32,593; with in-course recorded activity: 28,500 (87.44%); outside-window-only: 728; no recorded activity in any observed window: 3,365.
- In-course activity rows: 9,966,292 (93.53% of 10,655,280); pre-course rows: 688,988 (6.47%). No post-course bucket was returned.
- All 10,655,280 activity rows matched resource metadata; unmatched resource rows, missing `activity_type` rows, and unmatched-registration activity rows were zero.
- The five highest-volume activity types account for 84.89% of in-course activity rows. These are source-row volumes, not unique-student reach or learning outcomes.
- VLE `week_from` and `week_to` are each missing in 5,243 of 6,364 resource records; their missingness overlap was not assessed.

The 87.44% in-course coverage is not interchangeable with AN5's 89.68% overall any-window coverage. The fixed registered denominator includes all eligible student-presentations. Distinct active days and resource breadth retain zero-activity registrations; first-activity timing is conditional on recorded in-course activity. Activity-type reach is non-additive. No returned POST_COURSE bucket is an observed data result, not an explanation of the source observation boundary.

The two notebook figures are exploratory. Figure 1 compares presentation-level activity-row volumes across complete relative seven-day periods and is not normalized by registered cohort size. The saved diagnostic reports 22 distinct module-presentations, 795 complete presentation-period observations, and 22 excluded partial/post-course period rows. Figure 2 describes activity-row composition by type; volume is not reach. Activity-row and click volumes remain sensitive to unresolved repeated source records.

No production KPI, composite score, causal claim, intervention threshold, predictive feature, or AN7 implementation is approved by AN6 closure. RAW, QUALITY, and STAGING remain unchanged; no persistent database objects or indexes were created. See `docs/AN6_recorded_vle_activity_patterns_plan.md`, `docs/analysis_log.md`, and `docs/analysis_progress_ledger.md` for the full evidence and interpretation boundaries.

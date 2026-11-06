-- Question: How do the documented repeated-key patterns in student_vle reconcile under R0, R1, and R2, and how much activity is unmatched to the registered student-presentation population?
-- Expectation: R0 preserves every source row; R1 equals the number of distinct six-column tuples; R2 equals the number of distinct five-column candidate keys. No scenario is assumed to be the source truth.
-- Grain: One overall source-profile row; one scenario row; and one row per module-presentation for registration/activity-key reconciliation.
-- Source: staging.student_vle, staging.student_registration.
-- Safety: READ-ONLY. Do not modify RAW, QUALITY, or STAGING. No deduplication or aggregation is written back to the database.
-- Runtime: HIGH. Multiple aggregations scan the 10.6M-row student_vle table. Run alone with statement_timeout_ms=600000.
-- Read as: R1 collapses only exact six-column duplicates. R2 retains MAX(sum_click) per five-column candidate key as a sensitivity assumption, not a validated correction. Activity-to-registration matching uses the full three-column student-presentation key.

-- 1. Reconcile the historical candidate-key and exact-row repetition profile.
WITH grouped_keys AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           COUNT(*)::BIGINT AS key_group_rows,
           COUNT(DISTINCT sum_click)::BIGINT AS distinct_sum_click_values
    FROM staging.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
),
exact_groups AS (
    SELECT code_module, code_presentation, id_student, id_site, date, sum_click,
           COUNT(*)::BIGINT AS exact_group_rows
    FROM staging.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date, sum_click
),
source_profile AS (
    SELECT COUNT(*)::BIGINT AS r0_rows,
           COUNT(DISTINCT ROW(code_module, code_presentation, id_student, id_site, date))::BIGINT
               AS distinct_five_column_keys,
           COUNT(DISTINCT ROW(code_module, code_presentation, id_student, id_site, date, sum_click))::BIGINT
               AS distinct_six_column_tuples
    FROM staging.student_vle
),
key_profile AS (
    SELECT COUNT(*)::BIGINT AS five_column_key_groups,
           COUNT(*) FILTER (WHERE key_group_rows > 1)::BIGINT AS repeated_key_groups,
           SUM(key_group_rows) FILTER (WHERE key_group_rows > 1)::BIGINT AS rows_in_repeated_key_groups,
           SUM(key_group_rows - 1)::BIGINT AS excess_rows_over_five_column_keys,
           COUNT(*) FILTER (WHERE distinct_sum_click_values > 1)::BIGINT AS groups_with_multiple_sum_click_values,
           MAX(key_group_rows)::BIGINT AS maximum_key_group_size
    FROM grouped_keys
),
exact_profile AS (
    SELECT COUNT(*)::BIGINT AS six_column_tuple_groups,
           COUNT(*) FILTER (WHERE exact_group_rows > 1)::BIGINT AS fully_identical_groups,
           SUM(exact_group_rows - 1)::BIGINT AS excess_fully_identical_rows
    FROM exact_groups
)
SELECT s.r0_rows,
       s.distinct_five_column_keys,
       s.distinct_six_column_tuples,
       k.repeated_key_groups,
       k.rows_in_repeated_key_groups,
       k.excess_rows_over_five_column_keys,
       k.groups_with_multiple_sum_click_values,
       k.maximum_key_group_size,
       e.fully_identical_groups,
       e.excess_fully_identical_rows,
       (s.r0_rows = s.distinct_five_column_keys + k.excess_rows_over_five_column_keys) AS r0_key_reconciliation,
       (s.distinct_six_column_tuples = e.six_column_tuple_groups) AS r1_tuple_reconciliation
FROM source_profile AS s
CROSS JOIN key_profile AS k
CROSS JOIN exact_profile AS e;

-- 2. Confirm the row-count basis of the three metric-only sensitivity scenarios.
WITH r1 AS (
    SELECT DISTINCT code_module, code_presentation, id_student, id_site, date, sum_click
    FROM staging.student_vle
),
r2 AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           MAX(sum_click) AS sum_click
    FROM staging.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
),
scenario_counts AS (
    SELECT 'R0'::TEXT AS scenario, COUNT(*)::BIGINT AS scenario_rows
    FROM staging.student_vle
    UNION ALL
    SELECT 'R1', COUNT(*)::BIGINT FROM r1
    UNION ALL
    SELECT 'R2', COUNT(*)::BIGINT FROM r2
)
SELECT scenario, scenario_rows
FROM scenario_counts
ORDER BY scenario;

-- 3. Reconcile activity-bearing student-presentations against registration under each scenario.
WITH registered_population AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS registered_student_presentations,
           COUNT(DISTINCT id_student)::BIGINT AS distinct_registered_students
    FROM staging.student_registration
    GROUP BY code_module, code_presentation
),
scenario_rows AS (
    SELECT 'R0'::TEXT AS scenario,
           code_module, code_presentation, id_student, id_site, date, sum_click
    FROM staging.student_vle

    UNION ALL

    SELECT 'R1'::TEXT,
           code_module, code_presentation, id_student, id_site, date, sum_click
    FROM (
        SELECT DISTINCT code_module, code_presentation, id_student, id_site, date, sum_click
        FROM staging.student_vle
    ) AS exact_rows

    UNION ALL

    SELECT 'R2'::TEXT,
           code_module, code_presentation, id_student, id_site, date, MAX(sum_click) AS sum_click
    FROM staging.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
),
activity_by_student AS (
    SELECT scenario, code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS scenario_activity_rows,
           SUM(sum_click)::NUMERIC AS scenario_sum_click
    FROM scenario_rows
    GROUP BY scenario, code_module, code_presentation, id_student
),
activity_match AS (
    SELECT a.scenario, a.code_module, a.code_presentation,
           COUNT(*)::BIGINT AS activity_student_presentations,
           COUNT(*) FILTER (WHERE r.id_student IS NOT NULL)::BIGINT AS matched_activity_student_presentations,
           COUNT(*) FILTER (WHERE r.id_student IS NULL)::BIGINT AS unmatched_activity_student_presentations,
           SUM(a.scenario_activity_rows) FILTER (WHERE r.id_student IS NOT NULL)::BIGINT AS matched_activity_rows,
           SUM(a.scenario_activity_rows) FILTER (WHERE r.id_student IS NULL)::BIGINT AS unmatched_activity_rows,
           SUM(a.scenario_sum_click) FILTER (WHERE r.id_student IS NOT NULL)::NUMERIC AS matched_sum_click,
           SUM(a.scenario_sum_click) FILTER (WHERE r.id_student IS NULL)::NUMERIC AS unmatched_sum_click
    FROM activity_by_student AS a
    LEFT JOIN staging.student_registration AS r
      ON r.code_module = a.code_module
     AND r.code_presentation = a.code_presentation
     AND r.id_student = a.id_student
    GROUP BY a.scenario, a.code_module, a.code_presentation
)
SELECT a.scenario, a.code_module, a.code_presentation,
       COALESCE(p.registered_student_presentations, 0) AS registered_student_presentations,
       COALESCE(p.distinct_registered_students, 0) AS distinct_registered_students,
       a.activity_student_presentations,
       a.matched_activity_student_presentations,
       a.unmatched_activity_student_presentations,
       a.matched_activity_rows, a.unmatched_activity_rows,
       a.matched_sum_click, a.unmatched_sum_click
FROM activity_match AS a
LEFT JOIN registered_population AS p
  ON p.code_module = a.code_module
 AND p.code_presentation = a.code_presentation
ORDER BY a.scenario, a.code_module, a.code_presentation;

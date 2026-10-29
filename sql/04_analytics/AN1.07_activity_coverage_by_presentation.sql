-- Question: How much recorded VLE activity belongs to registered students in the same presentation?
-- Expectation: Distinguish any activity-bearing students from activity-bearing students with an exact registration match.
-- Grain: One row per registered module presentation.
-- Source: staging.student_registration, staging.student_vle.
-- Safety: READ-ONLY; preserve all source rows and do not infer withdrawal from missing activity.
-- Runtime: High; scans the 10.6M-row student_vle table. Run alone with statement_timeout_ms=600000.
-- Read as: matched_active_students is the coverage numerator. activity_students_not_registered counts distinct activity keys without a matching registration. Raw activity counts and click sums are descriptive, not approved KPIs.

-- 1. Aggregate activity by presentation and student before matching the registration key.
WITH registration_counts AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS registration_rows,
           COUNT(DISTINCT id_student)::BIGINT AS registered_students
    FROM staging.student_registration
    GROUP BY code_module, code_presentation
),
activity_by_student AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS student_activity_rows,
           SUM(sum_click)::NUMERIC AS student_stored_sum_click
    FROM staging.student_vle
    GROUP BY code_module, code_presentation, id_student
),
activity_counts AS (
    SELECT code_module, code_presentation,
           SUM(student_activity_rows)::BIGINT AS activity_rows,
           COUNT(*)::BIGINT AS students_with_any_activity,
           COUNT(*) FILTER (WHERE EXISTS (
               SELECT 1 FROM staging.student_registration AS r
               WHERE r.code_module = a.code_module
                 AND r.code_presentation = a.code_presentation
                 AND r.id_student = a.id_student
           ))::BIGINT AS matched_active_students,
           COUNT(*) FILTER (WHERE NOT EXISTS (
               SELECT 1 FROM staging.student_registration AS r
               WHERE r.code_module = a.code_module
                 AND r.code_presentation = a.code_presentation
                 AND r.id_student = a.id_student
           ))::BIGINT AS activity_students_not_registered,
           SUM(student_stored_sum_click)::NUMERIC AS stored_sum_click
    FROM activity_by_student AS a
    GROUP BY a.code_module, a.code_presentation
),
activity_detail AS (
    SELECT code_module, code_presentation,
           COUNT(DISTINCT id_site)::BIGINT AS distinct_sites_with_activity,
           COUNT(DISTINCT date)::BIGINT AS distinct_activity_days,
           COUNT(*) FILTER (WHERE date < 0)::BIGINT AS negative_day_rows,
           MIN(date) AS minimum_activity_day,
           MAX(date) AS maximum_activity_day
    FROM staging.student_vle
    GROUP BY code_module, code_presentation
)
SELECT r.code_module, r.code_presentation,
       r.registration_rows, r.registered_students,
       COALESCE(a.activity_rows, 0) AS activity_rows,
       COALESCE(a.students_with_any_activity, 0) AS students_with_any_activity,
       COALESCE(a.matched_active_students, 0) AS matched_active_students,
       COALESCE(a.activity_students_not_registered, 0) AS activity_students_not_registered,
       ROUND(100.0 * COALESCE(a.matched_active_students, 0) / NULLIF(r.registered_students, 0), 2) AS pct_registered_students_with_matched_activity,
       COALESCE(d.distinct_sites_with_activity, 0) AS distinct_sites_with_activity,
       COALESCE(d.distinct_activity_days, 0) AS distinct_activity_days,
       COALESCE(d.negative_day_rows, 0) AS negative_day_rows,
       d.minimum_activity_day, d.maximum_activity_day,
       a.stored_sum_click
FROM registration_counts AS r
LEFT JOIN activity_counts AS a USING (code_module, code_presentation)
LEFT JOIN activity_detail AS d USING (code_module, code_presentation)
ORDER BY r.code_module, r.code_presentation;

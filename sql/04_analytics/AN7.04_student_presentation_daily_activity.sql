-- Question: What distinct active-day measures are observed per registered student-presentation across course-relative and post-registration landmark windows?
-- Expectation: One row per registered student-presentation; course-window activity presence and raw in-course row totals reconcile to AN6.
-- Grain: One row per student-presentation: (code_module, code_presentation, id_student).
-- Source: staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY. R0 retains every source row; no deduplication, deletion, DDL, or persistent objects.
-- Runtime: HIGH. One sequential scan/aggregation of student_vle. Run alone with statement_timeout_ms=600000 and max_rows >= 33000.
-- Read as: Course-relative and post-registration measures are separate. Post-registration begins at GREATEST(0,date_registration); missing dates do not create exposure. Activity is not truncated at date_unregistration. Raw row counts are reconciliation diagnostics only.

WITH cohort AS (
    SELECT r.code_module,r.code_presentation,r.id_student,r.date_registration,
           c.module_presentation_length AS course_length,
           CASE WHEN r.date_registration IS NULL THEN NULL
                ELSE GREATEST(0,r.date_registration) END AS registered_start_day
    FROM staging.student_registration r
    JOIN staging.courses c
      ON c.code_module=r.code_module AND c.code_presentation=r.code_presentation
),
daily AS (
    SELECT v.code_module,v.code_presentation,v.id_student,v.date AS activity_day,
           COUNT(*)::BIGINT AS source_activity_rows
    FROM staging.student_vle v
    JOIN cohort c
      ON c.code_module=v.code_module
     AND c.code_presentation=v.code_presentation
     AND c.id_student=v.id_student
    WHERE v.date <= c.course_length
    GROUP BY v.code_module,v.code_presentation,v.id_student,v.date
)
SELECT c.code_module,c.code_presentation,c.id_student,
       COUNT(d.activity_day) FILTER (WHERE d.activity_day BETWEEN 0 AND 27)::BIGINT AS course_active_days_l28,
       COUNT(d.activity_day) FILTER (WHERE d.activity_day BETWEEN 0 AND 55)::BIGINT AS course_active_days_l56,
       COUNT(d.activity_day) FILTER (WHERE d.activity_day BETWEEN 0 AND 83)::BIGINT AS course_active_days_l84,
       COUNT(d.activity_day) FILTER (WHERE d.activity_day BETWEEN 0 AND c.course_length)::BIGINT AS course_active_days_full,
       COUNT(d.activity_day) FILTER (
         WHERE c.registered_start_day IS NOT NULL
           AND d.activity_day BETWEEN c.registered_start_day AND 27
       )::BIGINT AS registered_active_days_l28,
       COUNT(d.activity_day) FILTER (
         WHERE c.registered_start_day IS NOT NULL
           AND d.activity_day BETWEEN c.registered_start_day AND 55
       )::BIGINT AS registered_active_days_l56,
       COUNT(d.activity_day) FILTER (
         WHERE c.registered_start_day IS NOT NULL
           AND d.activity_day BETWEEN c.registered_start_day AND 83
       )::BIGINT AS registered_active_days_l84,
       COUNT(d.activity_day) FILTER (
         WHERE c.registered_start_day IS NOT NULL
           AND d.activity_day BETWEEN c.registered_start_day AND c.course_length
       )::BIGINT AS registered_active_days_full,
       COUNT(d.activity_day) FILTER (WHERE d.activity_day < 0)::BIGINT AS pre_course_active_days,
       COUNT(d.activity_day) FILTER (
         WHERE d.activity_day >= 0 AND c.date_registration IS NOT NULL
           AND d.activity_day < c.date_registration
       )::BIGINT AS in_course_pre_registration_active_days,
       MIN(d.activity_day) FILTER (
         WHERE d.activity_day BETWEEN 0 AND c.course_length
       )::INTEGER AS first_in_course_activity_day,
       MIN(d.activity_day) FILTER (
         WHERE c.registered_start_day IS NOT NULL
           AND d.activity_day BETWEEN c.registered_start_day AND c.course_length
       )::INTEGER AS first_post_registration_activity_day,
       COALESCE(SUM(d.source_activity_rows) FILTER (
         WHERE d.activity_day BETWEEN 0 AND c.course_length
       ),0)::BIGINT AS in_course_activity_rows_full
FROM cohort c
LEFT JOIN daily d
  ON d.code_module=c.code_module
 AND d.code_presentation=c.code_presentation
 AND d.id_student=c.id_student
GROUP BY c.code_module,c.code_presentation,c.id_student,
         c.date_registration,c.course_length,c.registered_start_day;

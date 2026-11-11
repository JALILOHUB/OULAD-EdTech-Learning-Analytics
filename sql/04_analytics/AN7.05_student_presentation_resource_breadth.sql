-- Question: How many distinct VLE resources were first observed by each student-presentation within course-relative and post-registration landmark windows?
-- Expectation: One row per registered student-presentation; full-course resource presence reconciles to AN6's 28,500 activity-bearing registrations.
-- Grain: One row per student-presentation: (code_module, code_presentation, id_student).
-- Source: staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY. R0 retains every source row; no deduplication, deletion, DDL, or persistent objects.
-- Runtime: HIGH. One sequential scan/grouping of student_vle by student-presentation and resource. Run alone with statement_timeout_ms=600000 and max_rows >= 33000.
-- Read as: Breadth counts non-NULL id_site values after first-day reduction; no COUNT(DISTINCT) is applied to the full activity table. Course-relative and post-registration breadth are separate.

WITH cohort AS (
    SELECT r.code_module,r.code_presentation,r.id_student,r.date_registration,
           c.module_presentation_length AS course_length,
           CASE WHEN r.date_registration IS NULL THEN NULL
                ELSE GREATEST(0,r.date_registration) END AS registered_start_day
    FROM staging.student_registration r
    JOIN staging.courses c
      ON c.code_module=r.code_module AND c.code_presentation=r.code_presentation
),
resource_first AS (
    SELECT v.code_module,v.code_presentation,v.id_student,v.id_site,
           MIN(v.date) FILTER (
             WHERE v.date BETWEEN 0 AND c.course_length
           ) AS first_in_course_day,
           MIN(v.date) FILTER (
             WHERE c.registered_start_day IS NOT NULL
               AND v.date BETWEEN c.registered_start_day AND c.course_length
           ) AS first_post_registration_day
    FROM staging.student_vle v
    JOIN cohort c
      ON c.code_module=v.code_module
     AND c.code_presentation=v.code_presentation
     AND c.id_student=v.id_student
    WHERE v.date BETWEEN 0 AND c.course_length
    GROUP BY v.code_module,v.code_presentation,v.id_student,v.id_site
)
SELECT c.code_module,c.code_presentation,c.id_student,
       COUNT(r.id_site) FILTER (WHERE r.first_in_course_day <= 27)::BIGINT AS course_resource_breadth_l28,
       COUNT(r.id_site) FILTER (WHERE r.first_in_course_day <= 55)::BIGINT AS course_resource_breadth_l56,
       COUNT(r.id_site) FILTER (WHERE r.first_in_course_day <= 83)::BIGINT AS course_resource_breadth_l84,
       COUNT(r.id_site) FILTER (WHERE r.first_in_course_day IS NOT NULL)::BIGINT AS course_resource_breadth_full,
       COUNT(r.id_site) FILTER (WHERE r.first_post_registration_day <= 27)::BIGINT AS registered_resource_breadth_l28,
       COUNT(r.id_site) FILTER (WHERE r.first_post_registration_day <= 55)::BIGINT AS registered_resource_breadth_l56,
       COUNT(r.id_site) FILTER (WHERE r.first_post_registration_day <= 83)::BIGINT AS registered_resource_breadth_l84,
       COUNT(r.id_site) FILTER (WHERE r.first_post_registration_day IS NOT NULL)::BIGINT AS registered_resource_breadth_full,
       COUNT(*) FILTER (WHERE r.id_site IS NULL)::BIGINT AS null_resource_key_groups
FROM cohort c
LEFT JOIN resource_first r
  ON r.code_module=c.code_module
 AND r.code_presentation=c.code_presentation
 AND r.id_student=c.id_student
GROUP BY c.code_module,c.code_presentation,c.id_student;

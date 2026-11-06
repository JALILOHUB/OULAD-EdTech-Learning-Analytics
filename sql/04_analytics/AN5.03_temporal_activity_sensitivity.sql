-- Question: How do pre-course, in-course, and post-course recorded activity patterns vary under R0, R1, and R2?
-- Expectation: Negative relative days remain visible as pre-course records; no date category is silently discarded. Course metadata and registration matches are reported explicitly.
-- Grain: One row per scenario, module-presentation, temporal bucket, and registration-match status.
-- Source: staging.student_vle, staging.student_registration, staging.courses.
-- Safety: READ-ONLY. No source records are updated, deleted, or replaced.
-- Runtime: HIGH. Three scenario aggregations scan the 10.6M-row activity table. Run alone with statement_timeout_ms=600000.
-- Read as: Dates are course-relative day values, not calendar dates. Pre-course activity does not establish its operational cause. Counts are recorded activity rows and student-presentation presence, not independent learning events.

-- 1. Classify every scenario row against course-relative presentation boundaries.
WITH scenario_rows AS (
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
classified AS (
    SELECT s.scenario, s.code_module, s.code_presentation,
           s.id_student, s.id_site, s.date, s.sum_click,
           CASE
               WHEN c.code_module IS NULL THEN 'COURSE_METADATA_MISSING'
               WHEN s.date < 0 THEN 'PRE_COURSE'
               WHEN s.date <= c.module_presentation_length THEN 'IN_COURSE'
               ELSE 'POST_COURSE'
           END AS temporal_bucket,
           CASE
               WHEN r.id_student IS NULL THEN 'NO_REGISTRATION_MATCH'
               ELSE 'REGISTERED_STUDENT_PRESENTATION'
           END AS registration_match_status
    FROM scenario_rows AS s
    LEFT JOIN staging.courses AS c
      ON c.code_module = s.code_module
     AND c.code_presentation = s.code_presentation
    LEFT JOIN staging.student_registration AS r
      ON r.code_module = s.code_module
     AND r.code_presentation = s.code_presentation
     AND r.id_student = s.id_student
),
bucket_metrics AS (
    SELECT scenario, code_module, code_presentation,
           temporal_bucket, registration_match_status,
           COUNT(*)::BIGINT AS scenario_activity_rows,
           SUM(sum_click)::NUMERIC AS recorded_sum_click,
           COUNT(DISTINCT id_student)::BIGINT AS distinct_students,
           COUNT(DISTINCT id_site)::BIGINT AS distinct_sites,
           COUNT(DISTINCT date)::BIGINT AS distinct_relative_days
    FROM classified
    GROUP BY scenario, code_module, code_presentation,
             temporal_bucket, registration_match_status
),
registered_population AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS registered_student_presentations
    FROM staging.student_registration
    GROUP BY code_module, code_presentation
)
SELECT b.scenario, b.code_module, b.code_presentation,
       b.temporal_bucket, b.registration_match_status,
       b.scenario_activity_rows, b.recorded_sum_click,
       b.distinct_students, b.distinct_sites, b.distinct_relative_days,
       p.registered_student_presentations
FROM bucket_metrics AS b
LEFT JOIN registered_population AS p
  ON p.code_module = b.code_module
 AND p.code_presentation = b.code_presentation
ORDER BY b.scenario, b.code_module, b.code_presentation,
         b.temporal_bucket, b.registration_match_status;

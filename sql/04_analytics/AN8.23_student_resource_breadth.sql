-- [AN8.23] Course-relative and post-registration resource breadth
-- Question: How many distinct non-NULL VLE resources were recorded within course and registration-relative windows?
-- Expectation: Return both in-course breadth and post-registration in-course breadth at registered student-presentation grain.
-- Grain: One row per registered student-presentation (code_module, code_presentation, id_student).
-- Source: staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY SELECT. Preserve R0 source rows; do not deduplicate or modify RAW/QUALITY/STAGING.
-- Runtime: HIGH. One full activity scan/grouping; execute alone with an explicit 600000 ms statement timeout.
-- Read as: In-course breadth uses days 0..course end. Post-registration breadth uses max(date_registration, 0)..course end. Neither measure is exposure-normalized.
WITH cohort AS (
    SELECT
        r.code_module,
        r.code_presentation,
        r.id_student,
        r.date_registration,
        c.module_presentation_length AS course_length,
        CASE
            WHEN r.date_registration IS NULL THEN NULL
            ELSE GREATEST(r.date_registration, 0)
        END AS exposure_start
    FROM staging.student_registration AS r
    JOIN staging.courses AS c
      USING (code_module, code_presentation)
),
resource_counts AS (
    SELECT
        v.code_module,
        v.code_presentation,
        v.id_student,
        COUNT(DISTINCT v.id_site) FILTER (
            WHERE v.id_site IS NOT NULL
              AND v.date BETWEEN 0 AND c.course_length
        )::BIGINT AS in_course_resource_breadth,
        COUNT(DISTINCT v.id_site) FILTER (
            WHERE v.id_site IS NOT NULL
              AND c.exposure_start IS NOT NULL
              AND v.date BETWEEN c.exposure_start AND c.course_length
        )::BIGINT AS post_registration_resource_breadth
    FROM staging.student_vle AS v
    JOIN cohort AS c
      USING (code_module, code_presentation, id_student)
    GROUP BY v.code_module, v.code_presentation, v.id_student
)
SELECT
    c.code_module,
    c.code_presentation,
    c.id_student,
    c.date_registration,
    c.course_length,
    c.exposure_start,
    COALESCE(r.in_course_resource_breadth, 0)::BIGINT AS in_course_resource_breadth,
    CASE
        WHEN c.exposure_start IS NULL OR c.exposure_start > c.course_length THEN NULL
        ELSE COALESCE(r.post_registration_resource_breadth, 0)::BIGINT
    END AS post_registration_resource_breadth
FROM cohort AS c
LEFT JOIN resource_counts AS r
  USING (code_module, code_presentation, id_student)
ORDER BY c.code_module, c.code_presentation, c.id_student;

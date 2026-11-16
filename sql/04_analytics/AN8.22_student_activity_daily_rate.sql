-- [AN8.22] Registration-adjusted active-day rate
-- Question: What is each registered student-presentation's active-day rate over its observable in-course registration exposure?
-- Expectation: Count only distinct activity days on/after the registration exposure start and on/before course end. Unknown or non-positive exposure is NULL, not zero.
-- Grain: One row per registered student-presentation (code_module, code_presentation, id_student).
-- Source: staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY SELECT. Preserve R0 source rows; do not deduplicate or modify RAW/QUALITY/STAGING.
-- Runtime: HIGH. One full activity scan/grouping; execute alone with an explicit 600000 ms statement timeout.
-- Read as: Numerator = distinct in-course active days from max(date_registration, 0) through course end. Denominator = inclusive available course days over the same interval. This is recorded activity, not learning quality.
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
activity AS (
    SELECT
        v.code_module,
        v.code_presentation,
        v.id_student,
        COUNT(DISTINCT v.date) FILTER (
            WHERE c.exposure_start IS NOT NULL
              AND v.date BETWEEN c.exposure_start AND c.course_length
        )::BIGINT AS post_registration_in_course_active_days
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
    CASE
        WHEN c.exposure_start IS NULL OR c.exposure_start > c.course_length THEN NULL
        ELSE (c.course_length - c.exposure_start + 1)::BIGINT
    END AS post_registration_in_course_exposure_days,
    COALESCE(a.post_registration_in_course_active_days, 0)::BIGINT
        AS post_registration_in_course_active_days,
    CASE
        WHEN c.exposure_start IS NULL OR c.exposure_start > c.course_length THEN NULL
        ELSE COALESCE(a.post_registration_in_course_active_days, 0)::NUMERIC
             / NULLIF(c.course_length - c.exposure_start + 1, 0)
    END AS post_registration_active_day_rate
FROM cohort AS c
LEFT JOIN activity AS a
  USING (code_module, code_presentation, id_student)
ORDER BY c.code_module, c.code_presentation, c.id_student;

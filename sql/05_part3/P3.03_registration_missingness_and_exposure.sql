-- [P3.03] Registration missingness and exposure context
-- Question: Which registered student-presentations have an unknown registration day, and what do their linked outcome, profile, and VLE records show?
-- Expectation: Every missing/blank/question-mark registration value is listed once at registration grain with linked activity counts and temporal states.
-- Grain: One row per registered student-presentation with missing registration day.
-- Source: source_ref.student_registration, student_info, courses, student_vle.
-- Safety: READ-ONLY SELECT. No imputation or deletion. Student identifiers are retained only for internal reconciliation.
-- Runtime: HIGH; scans student_vle to aggregate activity for the missing-registration cohort.
-- Read as: Missing registration makes registration-relative exposure unknown; it does not imply zero exposure or no activity.

WITH missing_registration AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
           r.date_registration, r.date_unregistration,
           c.module_presentation_length,
           i.final_result, i.gender, i.age_band, i.highest_education,
           i.imd_band, i.disability
    FROM source_ref.student_registration r
    LEFT JOIN source_ref.courses c USING (code_module, code_presentation)
    LEFT JOIN source_ref.student_info i USING (code_module, code_presentation, id_student)
    WHERE r.date_registration IS NULL
       OR BTRIM(r.date_registration) IN ('', '?')
),
activity_rows AS (
    SELECT v.code_module, v.code_presentation, v.id_student,
           CASE WHEN BTRIM(v.date) ~ '^-?[0-9]+
SELECT m.*,
       COALESCE(a.activity_rows, 0)::BIGINT AS activity_rows,
       COALESCE(a.recorded_clicks, 0)::NUMERIC AS recorded_clicks,
       COALESCE(a.pre_course_rows, 0)::BIGINT AS pre_course_rows,
       COALESCE(a.in_course_rows, 0)::BIGINT AS in_course_rows,
       COALESCE(a.post_course_rows, 0)::BIGINT AS post_course_rows,
       CASE WHEN a.activity_rows IS NULL THEN 'NO_RECORDED_VLE_ROW'
            WHEN a.in_course_rows = 0 AND a.pre_course_rows > 0 AND a.post_course_rows = 0 THEN 'PRE_COURSE_ONLY'
            WHEN a.in_course_rows > 0 THEN 'HAS_IN_COURSE_ACTIVITY'
            ELSE 'OTHER_TEMPORAL_ACTIVITY' END AS activity_context
FROM missing_registration m
LEFT JOIN activity a USING (code_module, code_presentation, id_student)
ORDER BY m.code_module, m.code_presentation, m.id_student;
 THEN BTRIM(v.date)::INTEGER END AS relative_day,
           CASE WHEN BTRIM(v.sum_click) ~ '^[0-9]+
SELECT m.*,
       COALESCE(a.activity_rows, 0)::BIGINT AS activity_rows,
       COALESCE(a.recorded_clicks, 0)::NUMERIC AS recorded_clicks,
       COALESCE(a.pre_course_rows, 0)::BIGINT AS pre_course_rows,
       COALESCE(a.in_course_rows, 0)::BIGINT AS in_course_rows,
       COALESCE(a.post_course_rows, 0)::BIGINT AS post_course_rows,
       CASE WHEN a.activity_rows IS NULL THEN 'NO_RECORDED_VLE_ROW'
            WHEN a.in_course_rows = 0 AND a.pre_course_rows > 0 AND a.post_course_rows = 0 THEN 'PRE_COURSE_ONLY'
            WHEN a.in_course_rows > 0 THEN 'HAS_IN_COURSE_ACTIVITY'
            ELSE 'OTHER_TEMPORAL_ACTIVITY' END AS activity_context
FROM missing_registration m
LEFT JOIN activity a USING (code_module, code_presentation, id_student)
ORDER BY m.code_module, m.code_presentation, m.id_student;
 THEN BTRIM(v.sum_click)::NUMERIC END AS numeric_clicks,
           c.module_presentation_length::INTEGER AS course_length
    FROM source_ref.student_vle v
    JOIN missing_registration m USING (code_module, code_presentation, id_student)
    LEFT JOIN source_ref.courses c USING (code_module, code_presentation)
),
activity AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS activity_rows,
           SUM(numeric_clicks) AS recorded_clicks,
           COUNT(*) FILTER (WHERE relative_day < 0)::BIGINT AS pre_course_rows,
           COUNT(*) FILTER (WHERE relative_day BETWEEN 0 AND course_length)::BIGINT AS in_course_rows,
           COUNT(*) FILTER (WHERE relative_day > course_length)::BIGINT AS post_course_rows
    FROM activity_rows
    GROUP BY code_module, code_presentation, id_student
)
SELECT m.*,
       COALESCE(a.activity_rows, 0)::BIGINT AS activity_rows,
       COALESCE(a.recorded_clicks, 0)::NUMERIC AS recorded_clicks,
       COALESCE(a.pre_course_rows, 0)::BIGINT AS pre_course_rows,
       COALESCE(a.in_course_rows, 0)::BIGINT AS in_course_rows,
       COALESCE(a.post_course_rows, 0)::BIGINT AS post_course_rows,
       CASE WHEN a.activity_rows IS NULL THEN 'NO_RECORDED_VLE_ROW'
            WHEN a.in_course_rows = 0 AND a.pre_course_rows > 0 AND a.post_course_rows = 0 THEN 'PRE_COURSE_ONLY'
            WHEN a.in_course_rows > 0 THEN 'HAS_IN_COURSE_ACTIVITY'
            ELSE 'OTHER_TEMPORAL_ACTIVITY' END AS activity_context
FROM missing_registration m
LEFT JOIN activity a USING (code_module, code_presentation, id_student)
ORDER BY m.code_module, m.code_presentation, m.id_student;

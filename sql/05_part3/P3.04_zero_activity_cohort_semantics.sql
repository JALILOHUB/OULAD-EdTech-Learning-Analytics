-- [P3.04] Zero-recorded-activity cohort semantics
-- Question: How does every registered student-presentation partition into no-row, in-course, and outside-course VLE states?
-- Expectation: All registered keys are returned once with row-level activity counts and one mutually exclusive temporal state.
-- Grain: One row per registered student-presentation.
-- Source: source_ref.student_registration, courses, student_vle, student_info.
-- Safety: READ-ONLY SELECT. No cohort exclusion and no interpretation of missing VLE records as absence of learning.
-- Runtime: HIGH; one full student_vle aggregation. Run alone.
-- Read as: The output supports exact record-level reconciliation of the 3,365 no-row and 4,093 no-in-course groups. The 0..L interval is the established AN8 operational convention, not a claim about an official calendar boundary.

-- 1. Aggregate source activity once, then left-join it to the full registered cohort.
WITH activity_rows AS (
    SELECT v.code_module, v.code_presentation, v.id_student,
           CASE
             WHEN BTRIM(v.date) ~ '^-?[0-9]+$'
             THEN BTRIM(v.date)::INTEGER
           END AS relative_day,
           c.module_presentation_length::INTEGER AS course_length
    FROM source_ref.student_vle AS v
    LEFT JOIN source_ref.courses AS c
      USING (code_module, code_presentation)
),
activity AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS all_activity_rows,
           COUNT(*) FILTER (WHERE relative_day < 0)::BIGINT AS pre_rows,
           COUNT(*) FILTER (
               WHERE relative_day BETWEEN 0 AND course_length
           )::BIGINT AS in_rows,
           COUNT(*) FILTER (WHERE relative_day > course_length)::BIGINT AS post_rows,
           COUNT(*) FILTER (
               WHERE relative_day IS NULL OR course_length IS NULL
           )::BIGINT AS unclassified_rows
    FROM activity_rows
    GROUP BY code_module, code_presentation, id_student
),
cohort AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
           r.date_registration, r.date_unregistration,
           c.module_presentation_length,
           i.final_result,
           COALESCE(a.all_activity_rows, 0)::BIGINT AS all_activity_rows,
           COALESCE(a.pre_rows, 0)::BIGINT AS pre_rows,
           COALESCE(a.in_rows, 0)::BIGINT AS in_rows,
           COALESCE(a.post_rows, 0)::BIGINT AS post_rows,
           COALESCE(a.unclassified_rows, 0)::BIGINT AS unclassified_rows,
           CASE
             WHEN a.all_activity_rows IS NULL THEN 'NO_RECORDED_VLE_ROW'
             WHEN a.in_rows > 0 THEN 'HAS_IN_COURSE_ACTIVITY'
             WHEN a.unclassified_rows > 0 THEN 'OUTSIDE_WINDOW_WITH_UNCLASSIFIED_DATE'
             WHEN a.pre_rows > 0 AND a.post_rows = 0 THEN 'PRE_COURSE_ONLY'
             WHEN a.post_rows > 0 AND a.pre_rows = 0 THEN 'POST_COURSE_ONLY'
             ELSE 'MIXED_OUTSIDE_COURSE_ACTIVITY'
           END AS activity_state
    FROM source_ref.student_registration AS r
    LEFT JOIN source_ref.courses AS c
      USING (code_module, code_presentation)
    LEFT JOIN source_ref.student_info AS i
      USING (code_module, code_presentation, id_student)
    LEFT JOIN activity AS a
      USING (code_module, code_presentation, id_student)
)
SELECT *,
       (in_rows = 0) AS no_recorded_in_course_activity,
       (date_registration IS NULL OR BTRIM(date_registration) IN ('', '?'))
           AS registration_exposure_unknown
FROM cohort
ORDER BY code_module, code_presentation, id_student;

-- [P3.04] Zero-recorded-activity cohort semantics
-- Question: How many registered student-presentations have no VLE rows, pre-course-only rows, in-course activity, or other temporal activity?
-- Expectation: All registered keys remain in the denominator and temporal states reconcile to the full registered cohort.
-- Grain: Result set 1 = one row per registered student-presentation; result set 2 = one row per presentation and activity state.
-- Source: source_ref.student_registration, courses, student_vle, student_info.
-- Safety: READ-ONLY SELECT. No cohort exclusion and no interpretation of missing VLE records as absence of learning.
-- Runtime: HIGH; full student_vle aggregation. Run alone.
-- Read as: Distinguish no source row from pre-course-only activity and from no activity inside the analytical course window. The 0..L interval is the established AN8 operational convention pending source-boundary validation.

WITH activity_rows AS (
    SELECT v.code_module, v.code_presentation, v.id_student,
           CASE WHEN BTRIM(v.date) ~ '^-?[0-9]+
cohort AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
           r.date_registration, r.date_unregistration,
           c.module_presentation_length,
           i.final_result,
           a.all_activity_rows, a.pre_rows, a.in_rows, a.post_rows, a.unclassified_rows,
           CASE
             WHEN a.all_activity_rows IS NULL THEN 'NO_RECORDED_VLE_ROW'
             WHEN COALESCE(a.in_rows, 0) > 0 THEN 'HAS_IN_COURSE_ACTIVITY'
             WHEN COALESCE(a.pre_rows, 0) > 0 AND COALESCE(a.post_rows, 0) = 0
                  AND COALESCE(a.unclassified_rows, 0) = 0 THEN 'PRE_COURSE_ONLY'
             WHEN COALESCE(a.post_rows, 0) > 0 AND COALESCE(a.pre_rows, 0) = 0 THEN 'POST_COURSE_ONLY'
             WHEN COALESCE(a.unclassified_rows, 0) > 0 THEN 'UNCLASSIFIED_DATE_ACTIVITY'
             ELSE 'RECORDED_ACTIVITY_OUTSIDE_COURSE_WINDOW'
           END AS activity_state
    FROM source_ref.student_registration r
    LEFT JOIN source_ref.courses c USING (code_module, code_presentation)
    LEFT JOIN source_ref.student_info i USING (code_module, code_presentation, id_student)
    LEFT JOIN activity a USING (code_module, code_presentation, id_student)
)
-- 1. Individual registered records for review.
SELECT *
FROM cohort
WHERE activity_state <> 'HAS_IN_COURSE_ACTIVITY'
ORDER BY activity_state, code_module, code_presentation, id_student;

-- 2. Cohort-state reconciliation by presentation and outcome.
SELECT code_module, code_presentation, final_result, activity_state,
       COUNT(*)::BIGINT AS student_presentations,
       COUNT(*) FILTER (WHERE date_registration IS NULL OR BTRIM(date_registration) IN ('', '?'))::BIGINT
           AS unknown_registration_records
FROM cohort
GROUP BY code_module, code_presentation, final_result, activity_state
ORDER BY code_module, code_presentation, final_result, activity_state;
 THEN BTRIM(v.date)::INTEGER END AS relative_day,
           c.module_presentation_length::INTEGER AS course_length
    FROM source_ref.student_vle v
    LEFT JOIN source_ref.courses c USING (code_module, code_presentation)
),
activity AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS all_activity_rows,
           COUNT(*) FILTER (WHERE relative_day < 0)::BIGINT AS pre_rows,
           COUNT(*) FILTER (WHERE relative_day BETWEEN 0 AND course_length)::BIGINT AS in_rows,
           COUNT(*) FILTER (WHERE relative_day > course_length)::BIGINT AS post_rows,
           COUNT(*) FILTER (WHERE relative_day IS NULL)::BIGINT AS unclassified_rows
    FROM activity_rows
    GROUP BY code_module, code_presentation, id_student
),
cohort AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
           r.date_registration, r.date_unregistration,
           c.module_presentation_length,
           i.final_result,
           a.all_activity_rows, a.pre_rows, a.in_rows, a.post_rows, a.unclassified_rows,
           CASE
             WHEN a.all_activity_rows IS NULL THEN 'NO_RECORDED_VLE_ROW'
             WHEN COALESCE(a.in_rows, 0) > 0 THEN 'HAS_IN_COURSE_ACTIVITY'
             WHEN COALESCE(a.pre_rows, 0) > 0 AND COALESCE(a.post_rows, 0) = 0
                  AND COALESCE(a.unclassified_rows, 0) = 0 THEN 'PRE_COURSE_ONLY'
             WHEN COALESCE(a.post_rows, 0) > 0 AND COALESCE(a.pre_rows, 0) = 0 THEN 'POST_COURSE_ONLY'
             WHEN COALESCE(a.unclassified_rows, 0) > 0 THEN 'UNCLASSIFIED_DATE_ACTIVITY'
             ELSE 'RECORDED_ACTIVITY_OUTSIDE_COURSE_WINDOW'
           END AS activity_state
    FROM source_ref.student_registration r
    LEFT JOIN source_ref.courses c USING (code_module, code_presentation)
    LEFT JOIN source_ref.student_info i USING (code_module, code_presentation, id_student)
    LEFT JOIN activity a USING (code_module, code_presentation, id_student)
)
-- 1. Individual registered records for review.
SELECT *
FROM cohort
WHERE activity_state <> 'HAS_IN_COURSE_ACTIVITY'
ORDER BY activity_state, code_module, code_presentation, id_student;

-- 2. Cohort-state reconciliation by presentation and outcome.
SELECT code_module, code_presentation, final_result, activity_state,
       COUNT(*)::BIGINT AS student_presentations,
       COUNT(*) FILTER (WHERE date_registration IS NULL OR BTRIM(date_registration) IN ('', '?'))::BIGINT
           AS unknown_registration_records
FROM cohort
GROUP BY code_module, code_presentation, final_result, activity_state
ORDER BY code_module, code_presentation, final_result, activity_state;

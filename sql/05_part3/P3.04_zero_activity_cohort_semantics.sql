-- [P3.04] Zero-recorded-activity cohort semantics
-- Question: How do all registered student-presentations partition into no-row, in-course, and outside-course VLE states?
-- Expectation: The registered cohort is retained and the mutually exclusive primary states reconcile to its exact row count.
-- Grain: Result set 1 = one row per registered student-presentation without in-course activity; result set 2 = one row per presentation/outcome/state; result set 3 = overall state totals.
-- Source: source_ref.student_registration, courses, student_vle, student_info.
-- Safety: READ-ONLY SELECT. No cohort exclusion and no interpretation of missing VLE records as absence of learning.
-- Runtime: HIGH; full student_vle aggregation. Run alone.
-- Read as: Distinguish no source row from pre-course-only activity and other outside-window activity. The 0..L interval is the established AN8 operational convention, not a claim about an official calendar boundary.

-- 1. Aggregate activity to the registered student-presentation grain.
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
SELECT *
FROM cohort
WHERE in_rows = 0
ORDER BY activity_state, code_module, code_presentation, id_student;

-- 2. Reconcile activity states by presentation and retrospective outcome.
WITH activity_rows AS (
    SELECT v.code_module, v.code_presentation, v.id_student,
           CASE WHEN BTRIM(v.date) ~ '^-?[0-9]+$'
                THEN BTRIM(v.date)::INTEGER END AS relative_day,
           c.module_presentation_length::INTEGER AS course_length
    FROM source_ref.student_vle AS v
    LEFT JOIN source_ref.courses AS c
      USING (code_module, code_presentation)
),
activity AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS all_activity_rows,
           COUNT(*) FILTER (WHERE relative_day < 0)::BIGINT AS pre_rows,
           COUNT(*) FILTER (WHERE relative_day BETWEEN 0 AND course_length)::BIGINT AS in_rows,
           COUNT(*) FILTER (WHERE relative_day > course_length)::BIGINT AS post_rows,
           COUNT(*) FILTER (WHERE relative_day IS NULL OR course_length IS NULL)::BIGINT
               AS unclassified_rows
    FROM activity_rows
    GROUP BY code_module, code_presentation, id_student
),
cohort AS (
    SELECT r.code_module, r.code_presentation, r.id_student, i.final_result,
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
    LEFT JOIN source_ref.student_info AS i
      USING (code_module, code_presentation, id_student)
    LEFT JOIN activity AS a
      USING (code_module, code_presentation, id_student)
)
SELECT code_module, code_presentation, final_result, activity_state,
       COUNT(*)::BIGINT AS student_presentations
FROM cohort
GROUP BY code_module, code_presentation, final_result, activity_state
ORDER BY code_module, code_presentation, final_result, activity_state;

-- 3. Overall registered-cohort reconciliation, including zero states.
WITH activity_rows AS (
    SELECT v.code_module, v.code_presentation, v.id_student,
           CASE WHEN BTRIM(v.date) ~ '^-?[0-9]+$'
                THEN BTRIM(v.date)::INTEGER END AS relative_day,
           c.module_presentation_length::INTEGER AS course_length
    FROM source_ref.student_vle AS v
    LEFT JOIN source_ref.courses AS c
      USING (code_module, code_presentation)
),
activity AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS all_activity_rows,
           COUNT(*) FILTER (WHERE relative_day < 0)::BIGINT AS pre_rows,
           COUNT(*) FILTER (WHERE relative_day BETWEEN 0 AND course_length)::BIGINT AS in_rows,
           COUNT(*) FILTER (WHERE relative_day > course_length)::BIGINT AS post_rows,
           COUNT(*) FILTER (WHERE relative_day IS NULL OR course_length IS NULL)::BIGINT
               AS unclassified_rows
    FROM activity_rows
    GROUP BY code_module, code_presentation, id_student
),
cohort AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
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
    LEFT JOIN activity AS a
      USING (code_module, code_presentation, id_student)
)
SELECT activity_state, COUNT(*)::BIGINT AS student_presentations
FROM cohort
GROUP BY activity_state
ORDER BY activity_state;

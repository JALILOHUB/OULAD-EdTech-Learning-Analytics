-- [P3.08] Educational indicator baseline for AN9 comparison
-- Question: What do source-faithful platform activity and assessment participation look like by module-presentation and retrospective outcome?
-- Expectation: Registered student-presentations remain the denominator; whole-source and 0..L activity, submission records, and score states remain distinct.
-- Grain: One row per module-presentation and retrospective final_result, including an explicit missing-outcome group if present.
-- Source: source_ref.student_registration, student_info, courses, student_vle, student_assessment, assessments.
-- Safety: READ-ONLY SELECT. No composite engagement score, causal interpretation, early-warning claim, or source correction.
-- Runtime: HIGH; aggregates student_vle and assessment submissions. Run alone after P3.07 join checks.
-- Read as: VLE activity is recorded platform interaction, not direct learning. final_result is retrospective. This is the source-faithful AN9-A baseline; later comparisons must hold grain, cohort, denominator, time window, and definitions constant.

-- 1. Preserve the registration cohort and attach outcome/course context.
WITH cohort AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
           i.final_result,
           c.module_presentation_length::INTEGER AS course_length
    FROM source_ref.student_registration AS r
    LEFT JOIN source_ref.student_info AS i
      USING (code_module, code_presentation, id_student)
    LEFT JOIN source_ref.courses AS c
      USING (code_module, code_presentation)
),
activity_rows AS (
    SELECT v.code_module, v.code_presentation, v.id_student,
           CASE WHEN BTRIM(v.date) ~ '^-?[0-9]+$'
                THEN BTRIM(v.date)::INTEGER END AS relative_day,
           CASE WHEN BTRIM(v.sum_click) ~ '^[0-9]+$'
                THEN BTRIM(v.sum_click)::NUMERIC END AS numeric_clicks,
           c.module_presentation_length::INTEGER AS course_length
    FROM source_ref.student_vle AS v
    LEFT JOIN source_ref.courses AS c
      USING (code_module, code_presentation)
),
activity AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS all_recorded_activity_rows,
           COUNT(numeric_clicks)::BIGINT AS parseable_click_rows,
           SUM(numeric_clicks) AS all_recorded_clicks,
           COUNT(*) FILTER (
               WHERE relative_day BETWEEN 0 AND course_length
           )::BIGINT AS in_course_activity_rows,
           SUM(numeric_clicks) FILTER (
               WHERE relative_day BETWEEN 0 AND course_length
           ) AS in_course_recorded_clicks,
           COUNT(DISTINCT relative_day) FILTER (
               WHERE relative_day BETWEEN 0 AND course_length
           )::BIGINT AS in_course_active_days,
           COUNT(*) FILTER (
               WHERE relative_day IS NULL OR course_length IS NULL
           )::BIGINT AS unclassified_temporal_rows
    FROM activity_rows
    GROUP BY code_module, code_presentation, id_student
),
assessment AS (
    SELECT a.code_module, a.code_presentation, sa.id_student,
           COUNT(*)::BIGINT AS submitted_assessment_records,
           COUNT(*) FILTER (
               WHERE sa.score IS NULL OR BTRIM(sa.score) IN ('', '?')
           )::BIGINT AS null_or_missing_score_records,
           COUNT(*) FILTER (
               WHERE BTRIM(sa.score) ~ '^-?[0-9]+(\\.[0-9]+)?$'
                 AND BTRIM(sa.score)::NUMERIC = 0
           )::BIGINT AS observed_zero_score_records,
           COUNT(*) FILTER (
               WHERE BTRIM(sa.score) ~ '^-?[0-9]+(\\.[0-9]+)?$'
                 AND BTRIM(sa.score)::NUMERIC <> 0
           )::BIGINT AS nonzero_score_records,
           COUNT(*) FILTER (WHERE BTRIM(sa.date_submitted) = '-1')::BIGINT
               AS unresolved_minus_one_submission_days
    FROM source_ref.student_assessment AS sa
    JOIN source_ref.assessments AS a
      USING (id_assessment)
    GROUP BY a.code_module, a.code_presentation, sa.id_student
),
student_level AS (
    SELECT c.*,
           COALESCE(v.all_recorded_activity_rows, 0)::BIGINT AS all_recorded_activity_rows,
           COALESCE(v.parseable_click_rows, 0)::BIGINT AS parseable_click_rows,
           COALESCE(v.all_recorded_clicks, 0)::NUMERIC AS all_recorded_clicks,
           COALESCE(v.in_course_activity_rows, 0)::BIGINT AS in_course_activity_rows,
           COALESCE(v.in_course_recorded_clicks, 0)::NUMERIC AS in_course_recorded_clicks,
           COALESCE(v.in_course_active_days, 0)::BIGINT AS in_course_active_days,
           COALESCE(v.unclassified_temporal_rows, 0)::BIGINT AS unclassified_temporal_rows,
           COALESCE(a.submitted_assessment_records, 0)::BIGINT AS submitted_assessment_records,
           COALESCE(a.null_or_missing_score_records, 0)::BIGINT AS null_or_missing_score_records,
           COALESCE(a.observed_zero_score_records, 0)::BIGINT AS observed_zero_score_records,
           COALESCE(a.nonzero_score_records, 0)::BIGINT AS nonzero_score_records,
           COALESCE(a.unresolved_minus_one_submission_days, 0)::BIGINT
               AS unresolved_minus_one_submission_days
    FROM cohort AS c
    LEFT JOIN activity AS v
      USING (code_module, code_presentation, id_student)
    LEFT JOIN assessment AS a
      USING (code_module, code_presentation, id_student)
)
SELECT code_module, code_presentation, final_result,
       COUNT(*)::BIGINT AS registered_student_presentations,
       COUNT(*) FILTER (WHERE all_recorded_activity_rows > 0)::BIGINT
           AS with_any_recorded_vle_activity,
       COUNT(*) FILTER (WHERE in_course_activity_rows > 0)::BIGINT
           AS with_in_course_vle_activity,
       COUNT(*) FILTER (WHERE submitted_assessment_records > 0)::BIGINT
           AS with_assessment_submission_record,
       SUM(all_recorded_activity_rows)::BIGINT AS all_recorded_vle_rows,
       SUM(parseable_click_rows)::BIGINT AS parseable_click_rows,
       SUM(all_recorded_clicks)::NUMERIC AS all_recorded_clicks,
       SUM(in_course_activity_rows)::BIGINT AS in_course_vle_rows,
       SUM(in_course_recorded_clicks)::NUMERIC AS in_course_recorded_clicks,
       AVG(in_course_active_days)::NUMERIC(12,2) AS mean_in_course_active_days,
       SUM(unclassified_temporal_rows)::BIGINT AS unclassified_temporal_rows,
       SUM(submitted_assessment_records)::BIGINT AS assessment_submission_records,
       SUM(null_or_missing_score_records)::BIGINT AS null_or_missing_score_records,
       SUM(observed_zero_score_records)::BIGINT AS observed_zero_score_records,
       SUM(nonzero_score_records)::BIGINT AS nonzero_score_records,
       SUM(unresolved_minus_one_submission_days)::BIGINT
           AS unresolved_minus_one_submission_days
FROM student_level
GROUP BY code_module, code_presentation, final_result
ORDER BY code_module, code_presentation, final_result;

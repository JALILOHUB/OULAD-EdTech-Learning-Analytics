-- [P3.08] Educational indicator baseline for AN9 comparison
-- Question: What do source-faithful platform activity and assessment participation look like by module-presentation and retrospective outcome, before any approved cleaning transformation?
-- Expectation: Registered student-presentations remain the denominator; recorded access, course-window activity, and assessment submission states are distinct indicators.
-- Grain: One row per module-presentation and retrospective final_result.
-- Source: source_ref.student_registration, student_info, courses, student_vle, student_assessment, assessments.
-- Safety: READ-ONLY SELECT. No composite engagement score, causal interpretation, early-warning claim, or source correction.
-- Runtime: HIGH; aggregates student_vle and assessment submissions. Run alone.
-- Read as: VLE activity is recorded platform interaction, not direct learning. final_result is retrospective. This is the source-faithful AN9-A baseline; later AN9-B comparisons must hold grain, cohort, denominator, time window, and definitions constant.

WITH cohort AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
           i.final_result,
           c.module_presentation_length
    FROM source_ref.student_registration r
    JOIN source_ref.student_info i USING (code_module, code_presentation, id_student)
    JOIN source_ref.courses c USING (code_module, code_presentation)
),
activity AS (
    SELECT v.code_module, v.code_presentation, v.id_student,
           COUNT(*)::BIGINT AS all_recorded_activity_rows,
           SUM(CASE WHEN BTRIM(v.sum_click) ~ '^[0-9]+$' THEN BTRIM(v.sum_click)::NUMERIC END) AS all_recorded_clicks,
           COUNT(*) FILTER (WHERE BTRIM(v.date) ~ '^-?[0-9]+$'
                             AND BTRIM(v.date)::INTEGER BETWEEN 0 AND c.module_presentation_length::INTEGER)::BIGINT AS in_course_activity_rows,
           SUM(CASE WHEN BTRIM(v.date) ~ '^-?[0-9]+$'
                     AND BTRIM(v.date)::INTEGER BETWEEN 0 AND c.module_presentation_length::INTEGER
                    AND BTRIM(v.sum_click) ~ '^[0-9]+$'
                    THEN BTRIM(v.sum_click)::NUMERIC END) AS in_course_recorded_clicks,
           COUNT(DISTINCT BTRIM(v.date)) FILTER (WHERE BTRIM(v.date) ~ '^-?[0-9]+$'
                             AND BTRIM(v.date)::INTEGER BETWEEN 0 AND c.module_presentation_length::INTEGER)::BIGINT AS in_course_active_days
    FROM source_ref.student_vle v
    JOIN source_ref.courses c USING (code_module, code_presentation)
    GROUP BY v.code_module, v.code_presentation, v.id_student
),
assessment AS (
    SELECT a.code_module, a.code_presentation, sa.id_student,
           COUNT(*)::BIGINT AS submitted_assessment_records,
           COUNT(*) FILTER (WHERE sa.score IS NULL OR BTRIM(sa.score) IN ('', '?'))::BIGINT AS null_score_records,
           COUNT(*) FILTER (WHERE BTRIM(sa.score) ~ '^-?[0-9]+(\.[0-9]+)?$' AND BTRIM(sa.score)::NUMERIC = 0)::BIGINT AS observed_zero_score_records,
           COUNT(*) FILTER (WHERE BTRIM(sa.score) ~ '^-?[0-9]+(\.[0-9]+)?$' AND BTRIM(sa.score)::NUMERIC <> 0)::BIGINT AS nonzero_score_records
    FROM source_ref.student_assessment sa
    JOIN source_ref.assessments a USING (id_assessment)
    GROUP BY a.code_module, a.code_presentation, sa.id_student
),
student_level AS (
    SELECT c.*,
           COALESCE(v.all_recorded_activity_rows, 0)::BIGINT AS all_recorded_activity_rows,
           COALESCE(v.all_recorded_clicks, 0)::NUMERIC AS all_recorded_clicks,
           COALESCE(v.in_course_activity_rows, 0)::BIGINT AS in_course_activity_rows,
           COALESCE(v.in_course_recorded_clicks, 0)::NUMERIC AS in_course_recorded_clicks,
           COALESCE(v.in_course_active_days, 0)::BIGINT AS in_course_active_days,
           COALESCE(a.submitted_assessment_records, 0)::BIGINT AS submitted_assessment_records,
           COALESCE(a.null_score_records, 0)::BIGINT AS null_score_records,
           COALESCE(a.observed_zero_score_records, 0)::BIGINT AS observed_zero_score_records,
           COALESCE(a.nonzero_score_records, 0)::BIGINT AS nonzero_score_records
    FROM cohort c
    LEFT JOIN activity v USING (code_module, code_presentation, id_student)
    LEFT JOIN assessment a USING (code_module, code_presentation, id_student)
)
SELECT code_module, code_presentation, final_result,
       COUNT(*)::BIGINT AS registered_student_presentations,
       COUNT(*) FILTER (WHERE all_recorded_activity_rows > 0)::BIGINT AS with_any_recorded_vle_activity,
       COUNT(*) FILTER (WHERE in_course_activity_rows > 0)::BIGINT AS with_in_course_vle_activity,
       COUNT(*) FILTER (WHERE submitted_assessment_records > 0)::BIGINT AS with_assessment_submission_record,
       SUM(all_recorded_activity_rows)::BIGINT AS all_recorded_vle_rows,
       SUM(all_recorded_clicks)::NUMERIC AS all_recorded_clicks,
       SUM(in_course_activity_rows)::BIGINT AS in_course_vle_rows,
       SUM(in_course_recorded_clicks)::NUMERIC AS in_course_recorded_clicks,
       AVG(in_course_active_days)::NUMERIC(12,2) AS mean_in_course_active_days,
       SUM(submitted_assessment_records)::BIGINT AS assessment_submission_records,
       SUM(null_score_records)::BIGINT AS submitted_null_score_records,
       SUM(observed_zero_score_records)::BIGINT AS observed_zero_score_records,
       SUM(nonzero_score_records)::BIGINT AS nonzero_score_records
FROM student_level
GROUP BY code_module, code_presentation, final_result
ORDER BY code_module, code_presentation, final_result;

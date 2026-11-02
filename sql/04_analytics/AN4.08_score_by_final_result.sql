-- Question: How do recorded non-NULL assessment scores vary across final_result, assessment type, and banked-record status?
-- Expectation: No monotonic score pattern is assumed.
-- Grain: One row per final_result, assessment type, and banked status.
-- Source: staging.student_info, staging.assessments, staging.student_assessment.
-- Safety: READ-ONLY
-- Runtime: Moderate.
-- Read as: Scores and final_result are associated and may be mechanically related, especially for exams. This is descriptive only and is not a valid feature set for predicting final_result. Preserve all banked statuses.

SELECT si.final_result,
       a.assessment_type,
       CASE
           WHEN sa.is_banked = 0 THEN 'NOT_BANKED'
           WHEN sa.is_banked = 1 THEN 'BANKED'
           ELSE 'NULL_OR_OTHER'
       END AS banked_status,
       COUNT(*)::BIGINT AS scored_submission_rows,
       COUNT(DISTINCT sa.id_student)::BIGINT AS distinct_students,
       ROUND(AVG(sa.score), 2) AS avg_score,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sa.score) AS median_score
FROM staging.student_assessment AS sa
JOIN staging.assessments AS a
  ON a.id_assessment = sa.id_assessment
JOIN staging.student_info AS si
  ON si.code_module = a.code_module
 AND si.code_presentation = a.code_presentation
 AND si.id_student = sa.id_student
WHERE sa.score IS NOT NULL
GROUP BY si.final_result, a.assessment_type, 3
ORDER BY a.assessment_type, si.final_result, banked_status;

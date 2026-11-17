-- Question: How do assessment participation, missing scores, observed zeros, and score distributions vary by presentation and assessment type?
-- Expectation: Distinguish no submission, NULL score, observed zero, and nonzero score while retaining the registration denominator.
-- Grain: One row per module-presentation, assessment type, and participation/score state.
-- Source: staging.student_registration, staging.assessments, staging.student_assessment.
-- Safety: READ-ONLY SELECT. Scores are retrospective; no score-availability timestamp is inferred.
-- Runtime: MODERATE; aggregates 173.9K assessment records and joins the registered cohort.
-- Read as: Assessment opportunities repeat across assessments; do not sum their denominators as unique students.

WITH assessment_students AS (
 SELECT a.code_module,a.code_presentation,a.id_assessment,a.assessment_type,
        r.id_student,sa.id_student AS submission_student_id,sa.score
 FROM staging.assessments a
 JOIN staging.student_registration r
  ON r.code_module=a.code_module AND r.code_presentation=a.code_presentation
 LEFT JOIN staging.student_assessment sa
  ON sa.id_assessment=a.id_assessment AND sa.id_student=r.id_student
), states AS (
 SELECT code_module,code_presentation,assessment_type,id_assessment,id_student,
        CASE WHEN COUNT(submission_student_id)=0 THEN 'NO_SUBMISSION'
             WHEN COUNT(*) FILTER(WHERE score IS NULL)>0
                  AND COUNT(*) FILTER(WHERE score IS NOT NULL)=0 THEN 'NULL_SCORE_ONLY'
             WHEN COUNT(*) FILTER(WHERE score=0)>0 THEN 'OBSERVED_ZERO_PRESENT'
             ELSE 'NONZERO_SCORE_PRESENT' END score_state,
        COUNT(submission_student_id)::BIGINT submission_rows,
        COUNT(*) FILTER(WHERE score IS NULL AND submission_student_id IS NOT NULL)::BIGINT null_score_rows,
        AVG(score)::NUMERIC mean_student_score
 FROM assessment_students
 GROUP BY code_module,code_presentation,assessment_type,id_assessment,id_student
)
SELECT code_module,code_presentation,assessment_type,score_state,
       COUNT(*)::BIGINT registered_assessment_opportunities,
       COUNT(DISTINCT id_student)::BIGINT distinct_students,
       SUM(submission_rows)::BIGINT submission_rows,SUM(null_score_rows)::BIGINT null_score_rows,
       ROUND(AVG(mean_student_score),2) mean_of_student_scores,
       PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY mean_student_score)::NUMERIC median_student_score
FROM states
GROUP BY code_module,code_presentation,assessment_type,score_state
ORDER BY code_module,code_presentation,assessment_type,score_state;

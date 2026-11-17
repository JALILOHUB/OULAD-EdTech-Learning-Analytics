-- [AN8.35] Assessment coverage and score profile
-- Question: How do assessment participation, missing scores, observed zeros, and score distributions vary by presentation and assessment type?
-- Expectation: Preserve the registered cohort as the denominator; distinguish no submission, NULL score, observed zero, and nonzero score.
-- Grain: One row per module-presentation, assessment type, and participation/score state.
-- Source: staging.student_registration, staging.assessments, staging.student_assessment.
-- Safety: READ-ONLY SELECT. Scores are retrospective; no score availability timestamp is inferred.
-- Runtime: MODERATE; aggregates 173.9K assessment records and joins 32.6K registrations.
-- Read as: A student-presentation may contribute to multiple assessments. Do not sum assessment-level denominators as unique students.

WITH assessment_students AS (
 SELECT a.code_module,a.code_presentation,a.id_assessment,a.assessment_type,
        r.id_student,sa.score
 FROM staging.assessments a
 JOIN staging.student_registration r
   ON r.code_module=a.code_module AND r.code_presentation=a.code_presentation
 LEFT JOIN staging.student_assessment sa
   ON sa.id_assessment=a.id_assessment AND sa.id_student=r.id_student
),
states AS (
 SELECT code_module,code_presentation,assessment_type,id_assessment,id_student,
        CASE WHEN COUNT(score)=0 AND COUNT(*)=1 THEN 'NO_SUBMISSION_OR_NULL_SCORE'
             WHEN COUNT(*) FILTER(WHERE score IS NULL)>0 AND COUNT(*) FILTER(WHERE score IS NOT NULL)=0 THEN 'NULL_SCORE_ONLY'
             WHEN COUNT(*) FILTER(WHERE score=0)>0 THEN 'OBSERVED_ZERO_PRESENT'
             ELSE 'NONZERO_SCORE_PRESENT' END score_state,
        COUNT(*) FILTER(WHERE score IS NOT NULL)::BIGINT scored_submission_rows,
        AVG(score)::NUMERIC mean_student_score,
        MAX(score) max_student_score
 FROM assessment_students
 GROUP BY code_module,code_presentation,assessment_type,id_assessment,id_student
)
SELECT code_module,code_presentation,assessment_type,score_state,
       COUNT(*)::BIGINT student_assessment_opportunities,
       COUNT(DISTINCT id_student)::BIGINT distinct_students,
       SUM(scored_submission_rows)::BIGINT scored_submission_rows,
       ROUND(AVG(mean_student_score),2) mean_of_student_scores,
       PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY mean_student_score)::NUMERIC median_student_score
FROM states
GROUP BY code_module,code_presentation,assessment_type,score_state
ORDER BY code_module,code_presentation,assessment_type,score_state;

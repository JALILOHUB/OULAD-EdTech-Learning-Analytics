-- [AN8.35] Assessment participation and score-state coverage
-- Question: How do assessment participation, missing scores, observed zeros, nonzero scores, and mixed score states vary by presentation and assessment type?
-- Expectation: Distinguish no submission, NULL-only, zero-only, nonzero-only, and mixed score states while retaining the registration denominator.
-- Grain: One row per module-presentation, assessment type, and student-assessment state.
-- Source: staging.student_registration, staging.assessments, staging.student_assessment.
-- Safety: READ-ONLY SELECT. Scores are retrospective; no score-availability timestamp is inferred.
-- Runtime: MODERATE; aggregates the assessment opportunity population and joins the registered cohort.
-- Read as: Assessment opportunities repeat across assessments; do not sum their denominators as unique students. Mixed states remain explicit.

WITH assessment_students AS (
    SELECT
        a.code_module,
        a.code_presentation,
        a.id_assessment,
        a.assessment_type,
        r.id_student,
        sa.id_student AS submission_student_id,
        sa.score
    FROM staging.assessments a
    JOIN staging.student_registration r
      ON r.code_module = a.code_module
     AND r.code_presentation = a.code_presentation
    LEFT JOIN staging.student_assessment sa
      ON sa.id_assessment = a.id_assessment
     AND sa.id_student = r.id_student
),
student_assessment_state AS (
    SELECT
        code_module,
        code_presentation,
        assessment_type,
        id_assessment,
        id_student,
        COUNT(submission_student_id)::BIGINT AS submission_rows,
        COUNT(*) FILTER (
            WHERE score IS NULL
              AND submission_student_id IS NOT NULL
        )::BIGINT AS null_score_rows,
        BOOL_OR(score IS NULL AND submission_student_id IS NOT NULL) AS has_null_score,
        BOOL_OR(score = 0) AS has_observed_zero,
        BOOL_OR(score <> 0) AS has_nonzero_score,
        AVG(score)::NUMERIC AS mean_student_score,
        CASE
            WHEN COUNT(submission_student_id) = 0 THEN 'NO_SUBMISSION'
            WHEN BOOL_OR(score IS NULL AND submission_student_id IS NOT NULL)
             AND (BOOL_OR(score = 0) OR BOOL_OR(score <> 0)) THEN 'MIXED_SCORE_STATES'
            WHEN BOOL_OR(score IS NULL AND submission_student_id IS NOT NULL) THEN 'NULL_SCORE_ONLY'
            WHEN BOOL_OR(score = 0) AND BOOL_OR(score <> 0) THEN 'MIXED_SCORE_STATES'
            WHEN BOOL_OR(score = 0) THEN 'OBSERVED_ZERO_ONLY'
            ELSE 'NONZERO_SCORE_ONLY'
        END AS score_state
    FROM assessment_students
    GROUP BY
        code_module,
        code_presentation,
        assessment_type,
        id_assessment,
        id_student
)
SELECT
    code_module,
    code_presentation,
    assessment_type,
    score_state,
    COUNT(*)::BIGINT AS registered_assessment_opportunities,
    COUNT(DISTINCT id_student)::BIGINT AS distinct_students,
    SUM(submission_rows)::BIGINT AS submission_rows,
    SUM(null_score_rows)::BIGINT AS null_score_rows,
    COUNT(*) FILTER (WHERE has_observed_zero)::BIGINT AS opportunities_with_observed_zero,
    COUNT(*) FILTER (WHERE has_nonzero_score)::BIGINT AS opportunities_with_nonzero_score,
    ROUND(AVG(mean_student_score), 2) AS mean_of_student_scores,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY mean_student_score
    )::NUMERIC AS median_student_score
FROM student_assessment_state
GROUP BY
    code_module,
    code_presentation,
    assessment_type,
    score_state
ORDER BY
    code_module,
    code_presentation,
    assessment_type,
    score_state;

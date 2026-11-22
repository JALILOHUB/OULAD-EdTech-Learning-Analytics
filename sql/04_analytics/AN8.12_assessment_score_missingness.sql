-- [AN8.12] Assessment score missingness
-- Question: How many assessment records have NULL, zero, and nonzero scores?
-- Expectation: Keep NULL scores distinct from observed zero scores.
-- Grain: One row per score state.
-- Source: staging.student_assessment.
-- Safety: READ-ONLY SELECT.
-- Runtime: LOW.
-- Read as: Retrospective assessment coverage, not an early feature.
SELECT CASE WHEN score IS NULL THEN 'NULL_SCORE' WHEN score=0 THEN 'OBSERVED_ZERO' ELSE 'NONZERO_SCORE' END score_state,
 COUNT(*)::BIGINT student_assessment_rows FROM staging.student_assessment GROUP BY 1 ORDER BY 1;
-- Question: How are student_assessment records distributed across observed is_banked values and assessment types?
-- Expectation: No prevalence, origin, validity, or timing pattern is assumed.
-- Grain: One row per raw is_banked value (including NULL) and assessment type.
-- Source: staging.student_assessment and staging.assessments.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: This is a descriptive profile of the stored flag. It does not establish why a record is banked or whether it should be excluded. Review this query before AN4.03. Preserve all statuses in downstream profiles until a separate evidence-based decision is approved.

SELECT sa.is_banked,
       a.assessment_type,
       COUNT(*)::BIGINT AS submission_rows,
       COUNT(DISTINCT sa.id_student)::BIGINT AS distinct_students,
       COUNT(*) FILTER (WHERE sa.score IS NOT NULL)::BIGINT AS scored_submission_rows,
       COUNT(*) FILTER (WHERE sa.score IS NULL)::BIGINT AS null_score_rows,
       COUNT(*) FILTER (WHERE sa.date_submitted IS NULL)::BIGINT AS missing_submission_date_rows,
       MIN(sa.date_submitted) AS min_date_submitted,
       MAX(sa.date_submitted) AS max_date_submitted,
       ROUND(AVG(sa.score), 2) AS avg_score
FROM staging.student_assessment AS sa
JOIN staging.assessments AS a
  ON a.id_assessment = sa.id_assessment
GROUP BY sa.is_banked, a.assessment_type
ORDER BY sa.is_banked NULLS LAST, a.assessment_type;

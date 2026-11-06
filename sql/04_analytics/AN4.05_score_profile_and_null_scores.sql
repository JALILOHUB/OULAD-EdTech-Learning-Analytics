-- Question: What is the score distribution, including NULL and zero scores, across assessment types and banked-record statuses?
-- Expectation: No score distribution or banked-status pattern is assumed. The historical 173 NULL-score rows are a reconciliation reference only.
-- Grain: Statement 1 = one row per assessment type and banked status; statement 2 = one row per assessment with NULL scores and banked status.
-- Source: staging.student_assessment and staging.assessments.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: A NULL score means not recorded, not zero. Keep zero scores separate. Preserve all banked statuses and do not exclude records before AN4.06 is interpreted.

-- 1. Score profile by assessment type and banked status.
SELECT a.assessment_type,
       CASE
           WHEN sa.is_banked = 0 THEN 'NOT_BANKED'
           WHEN sa.is_banked = 1 THEN 'BANKED'
           ELSE 'NULL_OR_OTHER'
       END AS banked_status,
       COUNT(*)::BIGINT AS submission_rows,
       COUNT(*) FILTER (WHERE sa.score IS NULL)::BIGINT AS null_score_rows,
       COUNT(*) FILTER (WHERE sa.score = 0)::BIGINT AS zero_score_rows,
       COUNT(*) FILTER (WHERE sa.score < 0 OR sa.score > 100)::BIGINT AS out_of_range_rows,
       COUNT(*) FILTER (WHERE sa.score IS NOT NULL)::BIGINT AS scored_rows,
       MIN(sa.score) AS min_score,
       ROUND(AVG(sa.score), 2) AS avg_score,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sa.score) AS median_score,
       MAX(sa.score) AS max_score
FROM staging.student_assessment AS sa
JOIN staging.assessments AS a
  ON a.id_assessment = sa.id_assessment
GROUP BY a.assessment_type, 2
ORDER BY a.assessment_type, banked_status;

-- 2. Assessment-level location of NULL scores, retaining banked status.
SELECT a.code_module,
       a.code_presentation,
       a.id_assessment,
       a.assessment_type,
       CASE
           WHEN sa.is_banked = 0 THEN 'NOT_BANKED'
           WHEN sa.is_banked = 1 THEN 'BANKED'
           ELSE 'NULL_OR_OTHER'
       END AS banked_status,
       COUNT(*)::BIGINT AS null_score_rows,
       COUNT(DISTINCT sa.id_student)::BIGINT AS distinct_students
FROM staging.student_assessment AS sa
JOIN staging.assessments AS a
  ON a.id_assessment = sa.id_assessment
WHERE sa.score IS NULL
GROUP BY a.code_module, a.code_presentation, a.id_assessment,
         a.assessment_type, 5
ORDER BY null_score_rows DESC, a.id_assessment, banked_status;

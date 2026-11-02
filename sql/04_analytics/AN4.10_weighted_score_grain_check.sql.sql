-- Question: How much assessment weight is represented by recorded submission rows per student-presentation, and how does coverage vary by banked status?
-- Expectation: No coverage level is assumed. The output tests whether a weighted score would have comparable assessment-weight coverage.
-- Grain: One row per module, presentation, and banked status; student-presentation is the unit used to calculate each student's coverage.
-- Source: staging.student_info, staging.assessments, staging.student_assessment.
-- Safety: READ-ONLY
-- Runtime: Moderate.
-- Read as: Weight is counted once per student-assessment-status combination after collapsing repeated physical rows at that combination. This is a metric sensitivity diagnostic, not a final weighted-score definition. A student may occur in more than one status group. Do not infer score validity from coverage alone.

WITH offered AS (
    SELECT code_module, code_presentation,
           SUM(weight)::NUMERIC AS total_weight_offered
    FROM staging.assessments
    GROUP BY code_module, code_presentation
),
submission_presence AS (
    SELECT DISTINCT
           a.code_module,
           a.code_presentation,
           sa.id_student,
           a.id_assessment,
           a.weight,
           CASE
               WHEN sa.is_banked = 0 THEN 'NOT_BANKED'
               WHEN sa.is_banked = 1 THEN 'BANKED'
               ELSE 'NULL_OR_OTHER'
           END AS banked_status
    FROM staging.student_assessment AS sa
    JOIN staging.assessments AS a
      ON a.id_assessment = sa.id_assessment
),
per_student_status AS (
    SELECT sp.code_module,
           sp.code_presentation,
           sp.id_student,
           sp.banked_status,
           SUM(sp.weight)::NUMERIC AS submitted_weight
    FROM submission_presence AS sp
    GROUP BY sp.code_module, sp.code_presentation, sp.id_student, sp.banked_status
),
presentation_sizes AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS student_presentation_rows
    FROM staging.student_info
    GROUP BY code_module, code_presentation
)
SELECT p.code_module,
       p.code_presentation,
       p.banked_status,
       COUNT(*)::BIGINT AS student_presentations_with_status,
       ps.student_presentation_rows,
       o.total_weight_offered,
       ROUND(AVG(p.submitted_weight / NULLIF(o.total_weight_offered, 0)), 3)
           AS avg_submitted_weight_share_for_status,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
           (ORDER BY p.submitted_weight / NULLIF(o.total_weight_offered, 0))::NUMERIC, 3)
           AS median_submitted_weight_share_for_status
FROM per_student_status AS p
JOIN offered AS o USING (code_module, code_presentation)
JOIN presentation_sizes AS ps USING (code_module, code_presentation)
GROUP BY p.code_module, p.code_presentation, p.banked_status,
         ps.student_presentation_rows, o.total_weight_offered
ORDER BY p.code_module, p.code_presentation, p.banked_status;

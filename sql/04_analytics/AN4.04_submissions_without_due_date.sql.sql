-- Question: How many submission rows are linked to assessments without a recorded due date, and how are they distributed?
-- Expectation: No assessment type, module, presentation, or shared grouping pattern is assumed. The historical total of 2,865 is a reconciliation reference only.
-- Grain: One row per module, presentation, assessment type, and banked-record status; include distinct assessment count.
-- Source: staging.student_assessment and staging.assessments.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: Reconcile the total submission rows with AN4.02. Do not infer that all rows share one assessment type. Preserve NULL/other banked status. A missing due date prevents direct due-date timing calculation; do not substitute course end.

SELECT a.code_module,
       a.code_presentation,
       a.assessment_type,
       CASE
           WHEN sa.is_banked = 0 THEN 'NOT_BANKED'
           WHEN sa.is_banked = 1 THEN 'BANKED'
           ELSE 'NULL_OR_OTHER'
       END AS banked_status,
       COUNT(DISTINCT a.id_assessment)::BIGINT AS assessment_count,
       COUNT(*)::BIGINT AS submission_rows,
       COUNT(DISTINCT sa.id_student)::BIGINT AS distinct_students,
       MIN(sa.date_submitted) AS min_date_submitted,
       MAX(sa.date_submitted) AS max_date_submitted,
       SUM(COUNT(*)) OVER ()::BIGINT AS total_without_due_date
FROM staging.student_assessment AS sa
JOIN staging.assessments AS a
  ON a.id_assessment = sa.id_assessment
WHERE a.date IS NULL
GROUP BY a.code_module, a.code_presentation, a.assessment_type, 4
ORDER BY a.code_module, a.code_presentation, a.assessment_type, banked_status;

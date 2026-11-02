-- Question: Which assessment records have no recorded due date, and what are their observed types and submission counts?
-- Expectation: No assessment type or presentation pattern is assumed. The historical count of 11 is a reconciliation reference only.
-- Grain: One row per assessment with a NULL due date.
-- Source: staging.assessments and staging.student_assessment.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: Treat assessment_type as observed data, not as a precondition. Reconcile the number of assessments separately from the number of linked submission rows. Preserve any NULL assessment_type value.

SELECT a.code_module,
       a.code_presentation,
       a.id_assessment,
       a.assessment_type,
       a.weight,
       COUNT(sa.id_assessment)::BIGINT AS submission_rows,
       COUNT(DISTINCT sa.id_student)::BIGINT AS distinct_students_with_submission
FROM staging.assessments AS a
LEFT JOIN staging.student_assessment AS sa
  ON sa.id_assessment = a.id_assessment
WHERE a.date IS NULL
GROUP BY a.code_module, a.code_presentation, a.id_assessment,
         a.assessment_type, a.weight
ORDER BY a.code_module, a.code_presentation, a.id_assessment;

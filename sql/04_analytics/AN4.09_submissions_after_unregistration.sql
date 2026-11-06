-- Question: How do recorded submission dates compare with the registration record's unregistration day, by banked status?
-- Expectation: No timing prevalence is assumed.
-- Grain: One row per module, presentation, assessment type, banked status, and timing category.
-- Source: staging.student_assessment, staging.assessments, staging.student_registration.
-- Safety: READ-ONLY
-- Runtime: Moderate.
-- Read as: This is a date comparison, not proof that a submission was accepted after withdrawal. Preserve all banked statuses. Keep missing unregistration dates, missing submission dates, and missing registration matches separate. Do not report only the after-unregistration category.

WITH compared AS (
    SELECT a.code_module,
           a.code_presentation,
           a.assessment_type,
           CASE
               WHEN sa.is_banked = 0 THEN 'NOT_BANKED'
               WHEN sa.is_banked = 1 THEN 'BANKED'
               ELSE 'NULL_OR_OTHER'
           END AS banked_status,
           CASE
               WHEN sr.id_student IS NULL THEN '0_NO_REGISTRATION_MATCH'
               WHEN sr.date_unregistration IS NULL THEN '1_NO_UNREGISTRATION_DATE'
               WHEN sa.date_submitted IS NULL THEN '2_NO_SUBMISSION_DATE'
               WHEN sa.date_submitted < sr.date_unregistration THEN '3_BEFORE_UNREGISTRATION'
               WHEN sa.date_submitted = sr.date_unregistration THEN '4_SAME_DAY'
               ELSE '5_AFTER_UNREGISTRATION'
           END AS timing_category
    FROM staging.student_assessment AS sa
    JOIN staging.assessments AS a
      ON a.id_assessment = sa.id_assessment
    LEFT JOIN staging.student_registration AS sr
      ON sr.code_module = a.code_module
     AND sr.code_presentation = a.code_presentation
     AND sr.id_student = sa.id_student
)
SELECT code_module,
       code_presentation,
       assessment_type,
       banked_status,
       timing_category,
       COUNT(*)::BIGINT AS submission_rows,
       ROUND(100.0 * COUNT(*) /
             NULLIF(SUM(COUNT(*)) OVER
                 (PARTITION BY code_module, code_presentation, assessment_type, banked_status), 0), 2)
             AS pct_within_type_and_status
FROM compared
GROUP BY code_module, code_presentation, assessment_type, banked_status, timing_category
ORDER BY code_module, code_presentation, assessment_type, banked_status, timing_category;

-- Question: How early or late are submissions relative to the recorded assessment due date, and how does timing vary by banked-record status?
-- Expectation: No timing distribution or banked-status prevalence is assumed.
-- Grain: One row per assessment type, banked-record status, and timing category.
-- Source: staging.student_assessment joined to staging.assessments on id_assessment.
-- Safety: READ-ONLY
-- Runtime: Moderate.
-- Read as: days_late = date_submitted - due date. Assessments with NULL due dates are profiled separately in AN4.04. Keep is_banked as a dimension, including NULL/other values. Keep missing submission dates as a separate timing category. AN4.06 must be reviewed first; do not infer that banked rows are invalid or exclude them automatically.

WITH classified AS (
    SELECT a.assessment_type,
           CASE
               WHEN sa.is_banked = 0 THEN 'NOT_BANKED'
               WHEN sa.is_banked = 1 THEN 'BANKED'
               ELSE 'NULL_OR_OTHER'
           END AS banked_status,
           CASE
               WHEN sa.date_submitted IS NULL THEN '0_MISSING_SUBMISSION_DATE'
               WHEN sa.date_submitted - a.date < -14 THEN '1_MORE_THAN_14_DAYS_EARLY'
               WHEN sa.date_submitted - a.date < 0 THEN '2_1_TO_14_DAYS_EARLY'
               WHEN sa.date_submitted - a.date = 0 THEN '3_ON_DUE_DAY'
               WHEN sa.date_submitted - a.date <= 7 THEN '4_1_TO_7_DAYS_LATE'
               ELSE '5_MORE_THAN_7_DAYS_LATE'
           END AS timing_category
    FROM staging.student_assessment AS sa
    JOIN staging.assessments AS a
      ON a.id_assessment = sa.id_assessment
    WHERE a.date IS NOT NULL
)
SELECT assessment_type,
       banked_status,
       timing_category,
       COUNT(*)::BIGINT AS submission_rows,
       ROUND(100.0 * COUNT(*) /
             NULLIF(SUM(COUNT(*)) OVER (PARTITION BY assessment_type, banked_status), 0), 2)
             AS pct_within_type_and_banked_status
FROM classified
GROUP BY assessment_type, banked_status, timing_category
ORDER BY assessment_type, banked_status, timing_category;

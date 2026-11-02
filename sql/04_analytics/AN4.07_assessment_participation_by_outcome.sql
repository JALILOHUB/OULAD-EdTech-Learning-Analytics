-- Question: How many assessment submission rows are recorded per student-presentation, by final_result and banked-record status, including students with no submission row?
-- Expectation: No outcome ordering or banked-status prevalence is assumed.
-- Grain: One row per final_result, banked status (including no-submission), and submission-count bucket; student-presentation is the counting unit.
-- Source: staging.student_info, staging.assessments, staging.student_assessment.
-- Safety: READ-ONLY
-- Runtime: Moderate.
-- Read as: Submission counts are grouped by the assessment's own module-presentation and student. A student-presentation may appear in more than one banked-status group if its records carry more than one status. Zero-submission student-presentations are explicitly retained.

WITH submission_counts AS (
    SELECT a.code_module,
           a.code_presentation,
           sa.id_student,
           CASE
               WHEN sa.is_banked = 0 THEN 'NOT_BANKED'
               WHEN sa.is_banked = 1 THEN 'BANKED'
               ELSE 'NULL_OR_OTHER'
           END AS banked_status,
           COUNT(*)::BIGINT AS submissions
    FROM staging.student_assessment AS sa
    JOIN staging.assessments AS a
      ON a.id_assessment = sa.id_assessment
    GROUP BY a.code_module, a.code_presentation, sa.id_student, 4
),
per_student_status AS (
    SELECT si.code_module,
           si.code_presentation,
           si.id_student,
           si.final_result,
           COALESCE(sc.banked_status, 'NO_SUBMISSION_RECORD') AS banked_status,
           COALESCE(sc.submissions, 0)::BIGINT AS submissions
    FROM staging.student_info AS si
    LEFT JOIN submission_counts AS sc
      ON sc.code_module = si.code_module
     AND sc.code_presentation = si.code_presentation
     AND sc.id_student = si.id_student
)
SELECT final_result,
       banked_status,
       CASE
           WHEN submissions = 0 THEN '0'
           WHEN submissions <= 3 THEN '1_TO_3'
           WHEN submissions <= 7 THEN '4_TO_7'
           ELSE '8_PLUS'
       END AS submission_bucket,
       COUNT(*)::BIGINT AS student_presentation_rows,
       ROUND(100.0 * COUNT(*) /
             NULLIF(SUM(COUNT(*)) OVER (PARTITION BY final_result, banked_status), 0), 2)
             AS pct_within_final_result_and_status
FROM per_student_status
GROUP BY final_result, banked_status, 3
ORDER BY final_result, banked_status, submission_bucket;

-- Question: How many student-presentation registrations have no recorded student_vle activity?
-- Expectation: Some registrations may have no matching activity; counts must be based on the full composite student-presentation key.
-- Grain: One row per registered module presentation.
-- Source: staging.student_registration and staging.student_vle.
-- Safety: READ-ONLY
-- Runtime: Moderate to high; scans and deduplicates activity keys from the 10.6M-row student_vle table. Run alone with statement_timeout_ms=600000.
-- Read as: No recorded activity is not proof of disengagement or withdrawal; it means no matching row exists in the available activity table.

-- 1. Build only distinct activity keys in PostgreSQL and anti-join registrations at their declared grain.
WITH activity_keys AS (
    SELECT DISTINCT code_module, code_presentation, id_student
    FROM staging.student_vle
),
registration_flags AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
           CASE WHEN a.id_student IS NULL THEN 1 ELSE 0 END AS no_activity_flag
    FROM staging.student_registration AS r
    LEFT JOIN activity_keys AS a
      ON a.code_module = r.code_module
     AND a.code_presentation = r.code_presentation
     AND a.id_student = r.id_student
)
SELECT code_module, code_presentation,
       COUNT(*)::BIGINT AS registration_rows,
       COUNT(*) FILTER (WHERE no_activity_flag = 0)::BIGINT AS registrations_with_activity,
       COUNT(*) FILTER (WHERE no_activity_flag = 1)::BIGINT AS registrations_without_activity,
       ROUND(100.0 * COUNT(*) FILTER (WHERE no_activity_flag = 1) / NULLIF(COUNT(*), 0), 2) AS pct_registrations_without_activity
FROM registration_flags
GROUP BY code_module, code_presentation
ORDER BY code_module, code_presentation;

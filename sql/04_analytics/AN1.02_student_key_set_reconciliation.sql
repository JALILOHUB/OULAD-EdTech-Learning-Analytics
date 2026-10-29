-- Question: Do student_info and student_registration contain the same complete student-presentation keys?
-- Expectation: Both key sets match; distinct student counts may differ from row counts only if keys repeat or are incomplete.
-- Grain: One row per reconciliation metric.
-- Source: staging.student_info and staging.student_registration.
-- Safety: READ-ONLY
-- Runtime: Low; operates on the two student-presentation tables.
-- Read as: Interpret set differences only after reviewing AN1.01 key completeness and uniqueness.

-- 1. Compare distinct student IDs and complete composite keys in both directions.
WITH info_keys AS (
    SELECT DISTINCT code_module, code_presentation, id_student
    FROM staging.student_info
    WHERE code_module IS NOT NULL AND code_presentation IS NOT NULL AND id_student IS NOT NULL
),
registration_keys AS (
    SELECT DISTINCT code_module, code_presentation, id_student
    FROM staging.student_registration
    WHERE code_module IS NOT NULL AND code_presentation IS NOT NULL AND id_student IS NOT NULL
),
info_only AS (
    SELECT code_module, code_presentation, id_student FROM info_keys
    EXCEPT
    SELECT code_module, code_presentation, id_student FROM registration_keys
),
registration_only AS (
    SELECT code_module, code_presentation, id_student FROM registration_keys
    EXCEPT
    SELECT code_module, code_presentation, id_student FROM info_keys
),
shared_keys AS (
    SELECT i.code_module, i.code_presentation, i.id_student
    FROM info_keys AS i
    INNER JOIN registration_keys AS r
      USING (code_module, code_presentation, id_student)
),
metrics AS (
    SELECT 'student_info_distinct_student_ids'::TEXT AS metric_name,
           COUNT(DISTINCT id_student)::BIGINT AS metric_value
    FROM staging.student_info
    UNION ALL
    SELECT 'student_registration_distinct_student_ids', COUNT(DISTINCT id_student)::BIGINT
    FROM staging.student_registration
    UNION ALL
    SELECT 'student_info_only_complete_keys', COUNT(*)::BIGINT FROM info_only
    UNION ALL
    SELECT 'student_registration_only_complete_keys', COUNT(*)::BIGINT FROM registration_only
    UNION ALL
    SELECT 'shared_complete_keys', COUNT(*)::BIGINT FROM shared_keys
)
SELECT metric_name, metric_value
FROM metrics
ORDER BY metric_name;

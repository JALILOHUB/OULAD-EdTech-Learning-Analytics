-- Question: Are the three-column student keys complete and unique in both STAGING student tables?
-- Expectation: Zero null-key rows and zero duplicate-key groups; row counts should equal distinct complete keys.
-- Grain: One row per student table.
-- Source: staging.student_info and staging.student_registration.
-- Safety: READ-ONLY
-- Runtime: Low; scans the two approximately 32.6K-row tables.
-- Read as: Do not run AN2 presentation profiles unless both tables pass the completeness and uniqueness checks.

-- 1. Compare total rows, incomplete keys, distinct complete keys, duplicate groups, and excess rows.
WITH source_rows AS (
    SELECT 'student_info'::TEXT AS table_name,
           code_module, code_presentation, id_student
    FROM staging.student_info
    UNION ALL
    SELECT 'student_registration', code_module, code_presentation, id_student
    FROM staging.student_registration
),
table_summary AS (
    SELECT table_name,
           COUNT(*)::BIGINT AS total_rows,
           COUNT(*) FILTER (
               WHERE code_module IS NULL
                  OR code_presentation IS NULL
                  OR id_student IS NULL
           )::BIGINT AS null_key_rows,
           COUNT(DISTINCT (code_module, code_presentation, id_student)) FILTER (
               WHERE code_module IS NOT NULL
                 AND code_presentation IS NOT NULL
                 AND id_student IS NOT NULL
           )::BIGINT AS distinct_key_values
    FROM source_rows
    GROUP BY table_name
),
duplicate_groups AS (
    SELECT table_name, code_module, code_presentation, id_student, COUNT(*) AS group_size
    FROM source_rows
    WHERE code_module IS NOT NULL
      AND code_presentation IS NOT NULL
      AND id_student IS NOT NULL
    GROUP BY table_name, code_module, code_presentation, id_student
    HAVING COUNT(*) > 1
),
duplicate_summary AS (
    SELECT table_name,
           COUNT(*)::BIGINT AS duplicate_key_groups,
           SUM(group_size - 1)::BIGINT AS excess_rows
    FROM duplicate_groups
    GROUP BY table_name
)
SELECT s.table_name,
       s.total_rows,
       s.null_key_rows,
       s.distinct_key_values,
       COALESCE(d.duplicate_key_groups, 0) AS duplicate_key_groups,
       COALESCE(d.excess_rows, 0) AS excess_rows,
       CASE
           WHEN s.null_key_rows = 0
            AND s.total_rows = s.distinct_key_values
            AND COALESCE(d.duplicate_key_groups, 0) = 0
           THEN 'PASS'
           ELSE 'PAUSE_AND_INVESTIGATE'
       END AS gate_status
FROM table_summary AS s
LEFT JOIN duplicate_summary AS d USING (table_name)
ORDER BY s.table_name;

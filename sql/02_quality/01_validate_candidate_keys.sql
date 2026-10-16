-- Purpose: Validate candidate-key completeness and uniqueness across the six RAW tables
-- that have established unique keys, then separately check the proposed student_vle key.
-- Execute each SELECT separately in pgAdmin if you need to inspect every result set.

-- B2.1: Candidate-key checks for tables other than student_vle.
WITH key_rows AS (
    SELECT 'courses'::text AS table_name,
           code_module || '|' || code_presentation AS key_value,
           (code_module IS NULL OR code_presentation IS NULL) AS has_null_key
    FROM raw.courses
    UNION ALL
    SELECT 'assessments', id_assessment::text, id_assessment IS NULL
    FROM raw.assessments
    UNION ALL
    SELECT 'student_info', code_module || '|' || code_presentation || '|' || id_student::text,
           (code_module IS NULL OR code_presentation IS NULL OR id_student IS NULL)
    FROM raw.student_info
    UNION ALL
    SELECT 'student_registration', code_module || '|' || code_presentation || '|' || id_student::text,
           (code_module IS NULL OR code_presentation IS NULL OR id_student IS NULL)
    FROM raw.student_registration
    UNION ALL
    SELECT 'student_assessment', id_assessment::text || '|' || id_student::text,
           (id_assessment IS NULL OR id_student IS NULL)
    FROM raw.student_assessment
    UNION ALL
    SELECT 'vle', id_site::text, id_site IS NULL
    FROM raw.vle
), key_summary AS (
    SELECT table_name, COUNT(*) AS total_rows,
           COUNT(*) FILTER (WHERE has_null_key) AS null_key_rows
    FROM key_rows
    GROUP BY table_name
), duplicate_groups AS (
    SELECT table_name, key_value, COUNT(*) AS group_size
    FROM key_rows
    WHERE NOT has_null_key
    GROUP BY table_name, key_value
    HAVING COUNT(*) > 1
), duplicate_summary AS (
    SELECT table_name, COUNT(*) AS duplicate_key_groups,
           SUM(group_size - 1) AS excess_rows
    FROM duplicate_groups
    GROUP BY table_name
)
SELECT k.table_name, k.total_rows, k.null_key_rows,
       COALESCE(d.duplicate_key_groups, 0) AS duplicate_key_groups,
       COALESCE(d.excess_rows, 0) AS excess_rows,
       CASE WHEN k.null_key_rows = 0
              AND COALESCE(d.duplicate_key_groups, 0) = 0
            THEN 'PASS' ELSE 'REVIEW' END AS test_status
FROM key_summary AS k
LEFT JOIN duplicate_summary AS d USING (table_name)
ORDER BY k.table_name;

-- B2.2: This query is expected to return REVIEW for the current OULAD source.
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT (code_module, code_presentation, id_student, id_site, date))
           AS distinct_candidate_keys,
       COUNT(*) - COUNT(DISTINCT
           (code_module, code_presentation, id_student, id_site, date)) AS excess_rows,
       'REVIEW'::text AS test_status
FROM raw.student_vle;

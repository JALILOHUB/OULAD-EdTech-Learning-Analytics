-- [AN8.02] Student-presentation grain and key-set reconciliation
-- Question: Are student_info and student_registration complete and unique at student-presentation grain, and do their key sets match?
-- Expectation: Report row counts, distinct composite keys, duplicate groups, NULL key rows, and bidirectional key differences.
-- Grain: Two source-grain rows plus two key-difference rows.
-- Source: staging.student_info, staging.student_registration.
-- Safety: READ-ONLY SELECT. Preserve every source row; no deduplication or correction.
-- Runtime: LOW; grouping approximately 32.6K rows per source.
-- Read as: Duplicate groups, NULL key components, or non-zero key differences block AN8.03 and all activity extraction. Counts are observed diagnostics, not hard-coded targets.
WITH si AS (
    SELECT code_module, code_presentation, id_student, COUNT(*) AS n
    FROM staging.student_info
    GROUP BY 1, 2, 3
),
sr AS (
    SELECT code_module, code_presentation, id_student, COUNT(*) AS n
    FROM staging.student_registration
    GROUP BY 1, 2, 3
),
stats AS (
    SELECT
        'student_info'::TEXT AS source_table,
        COUNT(*)::BIGINT AS source_rows,
        COUNT(DISTINCT (code_module, code_presentation, id_student))::BIGINT AS distinct_keys,
        (SELECT COUNT(*)::BIGINT FROM si WHERE n > 1) AS duplicate_key_groups,
        COUNT(*) FILTER (
            WHERE code_module IS NULL OR code_presentation IS NULL OR id_student IS NULL
        )::BIGINT AS null_key_rows
    FROM staging.student_info
    UNION ALL
    SELECT
        'student_registration',
        COUNT(*)::BIGINT,
        COUNT(DISTINCT (code_module, code_presentation, id_student))::BIGINT,
        (SELECT COUNT(*)::BIGINT FROM sr WHERE n > 1),
        COUNT(*) FILTER (
            WHERE code_module IS NULL OR code_presentation IS NULL OR id_student IS NULL
        )::BIGINT
    FROM staging.student_registration
),
diffs AS (
    SELECT
        'INFO_NOT_REGISTRATION'::TEXT AS difference,
        COUNT(*)::BIGINT AS key_count
    FROM si
    LEFT JOIN sr USING (code_module, code_presentation, id_student)
    WHERE sr.id_student IS NULL
    UNION ALL
    SELECT
        'REGISTRATION_NOT_INFO',
        COUNT(*)::BIGINT
    FROM sr
    LEFT JOIN si USING (code_module, code_presentation, id_student)
    WHERE si.id_student IS NULL
)
SELECT
    'SOURCE_GRAIN'::TEXT AS check_type,
    source_table AS check_name,
    source_rows,
    distinct_keys,
    duplicate_key_groups,
    null_key_rows,
    NULL::BIGINT AS key_count
FROM stats
UNION ALL
SELECT
    'KEY_DIFFERENCE',
    difference,
    NULL::BIGINT,
    NULL::BIGINT,
    NULL::BIGINT,
    NULL::BIGINT,
    key_count
FROM diffs
ORDER BY 1, 2;

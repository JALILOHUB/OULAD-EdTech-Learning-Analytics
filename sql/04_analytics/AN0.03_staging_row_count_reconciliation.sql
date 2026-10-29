-- Question: Do the current STAGING row counts match the documented engineering baseline?
-- Expectation: Counts match the historical baseline for all seven STAGING tables.
-- Grain: One row per STAGING table.
-- Source: staging.courses, staging.assessments, staging.student_info, staging.student_registration, staging.student_assessment, staging.vle, staging.student_vle.
-- Safety: READ-ONLY
-- Runtime: May scan student_vle (over 10 million rows); statement timeout is 120 seconds.
-- Read as: Exact COUNT(*) is intentional. Results are aggregated in PostgreSQL; no source rows are loaded into Pandas.

-- 1. Compare exact current row counts with the documented historical counts.
WITH actual_counts AS (
    SELECT 'courses'::TEXT AS table_name, COUNT(*)::BIGINT AS actual_rows FROM staging.courses
    UNION ALL
    SELECT 'assessments', COUNT(*)::BIGINT FROM staging.assessments
    UNION ALL
    SELECT 'student_info', COUNT(*)::BIGINT FROM staging.student_info
    UNION ALL
    SELECT 'student_registration', COUNT(*)::BIGINT FROM staging.student_registration
    UNION ALL
    SELECT 'student_assessment', COUNT(*)::BIGINT FROM staging.student_assessment
    UNION ALL
    SELECT 'vle', COUNT(*)::BIGINT FROM staging.vle
    UNION ALL
    SELECT 'student_vle', COUNT(*)::BIGINT FROM staging.student_vle
),
expected_counts AS (
    SELECT *
    FROM (VALUES
        ('courses'::TEXT, 22::BIGINT),
        ('assessments', 206::BIGINT),
        ('student_info', 32593::BIGINT),
        ('student_registration', 32593::BIGINT),
        ('student_assessment', 173912::BIGINT),
        ('vle', 6364::BIGINT),
        ('student_vle', 10655280::BIGINT)
    ) AS expected(table_name, expected_rows)
)
SELECT a.table_name,
       e.expected_rows,
       a.actual_rows,
       a.actual_rows - e.expected_rows AS row_count_difference,
       CASE WHEN a.actual_rows = e.expected_rows THEN 'MATCH' ELSE 'REVIEW' END AS reconciliation_status
FROM actual_counts AS a
JOIN expected_counts AS e USING (table_name)
ORDER BY a.table_name;

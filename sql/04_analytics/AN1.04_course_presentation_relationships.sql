-- Question: Do student-presentation records map to exactly one row in staging.courses?
-- Expectation: The course presentation key is unique and all student rows match exactly one course row.
-- Grain: One row for course-key diagnostics and one row per student source table.
-- Source: staging.courses, staging.student_info, staging.student_registration.
-- Safety: READ-ONLY; no persistent database changes.
-- Runtime: Low; scans two student tables and the small courses table.
-- Read as: source_rows is counted before the join. matched_join_rows and joined_rows reflect join output; a multiplier above 1 signals fan-out. Unmatched rows remain one per unmatched source row.

-- 1. Count physical course rows separately from distinct key groups.
WITH course_key_groups AS (
    SELECT code_module, code_presentation, COUNT(*)::BIGINT AS group_rows
    FROM staging.courses
    GROUP BY code_module, code_presentation
),
course_key_summary AS (
    SELECT (SELECT COUNT(*) FROM staging.courses)::BIGINT AS course_source_rows,
           COUNT(*)::BIGINT AS distinct_course_keys,
           COUNT(*) FILTER (WHERE group_rows > 1)::BIGINT AS duplicate_key_groups,
           COALESCE(SUM(group_rows - 1) FILTER (WHERE group_rows > 1), 0)::BIGINT AS duplicate_excess_rows
    FROM course_key_groups
),
student_sources AS (
    SELECT 'student_info'::TEXT AS table_name, code_module, code_presentation
    FROM staging.student_info
    UNION ALL
    SELECT 'student_registration'::TEXT, code_module, code_presentation
    FROM staging.student_registration
),
student_source_counts AS (
    SELECT table_name, COUNT(*)::BIGINT AS source_rows
    FROM student_sources
    GROUP BY table_name
),
student_join_summary AS (
    SELECT s.table_name,
           COUNT(c.code_module)::BIGINT AS matched_join_rows,
           COUNT(*) FILTER (WHERE c.code_module IS NULL)::BIGINT AS unmatched_rows,
           COUNT(*)::BIGINT AS joined_rows
    FROM student_sources AS s
    LEFT JOIN staging.courses AS c
      ON c.code_module = s.code_module
     AND c.code_presentation = s.code_presentation
    GROUP BY s.table_name
)
SELECT 'COURSE_KEY'::TEXT AS diagnostic,
       'courses'::TEXT AS table_name,
       k.course_source_rows AS source_rows,
       k.distinct_course_keys,
       NULL::BIGINT AS matched_join_rows,
       NULL::BIGINT AS unmatched_rows,
       k.duplicate_key_groups,
       k.duplicate_excess_rows,
       NULL::BIGINT AS joined_rows,
       NULL::NUMERIC AS join_multiplier
FROM course_key_summary AS k
UNION ALL
SELECT 'STUDENT_COURSE_JOIN', s.table_name, s.source_rows,
       NULL::BIGINT, j.matched_join_rows, j.unmatched_rows,
       NULL::BIGINT, NULL::BIGINT, j.joined_rows,
       ROUND(j.joined_rows::NUMERIC / NULLIF(s.source_rows, 0), 4)
FROM student_source_counts AS s
JOIN student_join_summary AS j USING (table_name)
ORDER BY diagnostic, table_name;

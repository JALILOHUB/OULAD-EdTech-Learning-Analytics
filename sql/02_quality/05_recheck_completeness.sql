-- Purpose: Audit missingness representations in RAW without modifying source data.
-- Execute this SELECT separately in pgAdmin.

SELECT 'raw.assessments' AS table_name, 'date' AS column_name,
       COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE date IS NULL) AS null_rows,
       COUNT(*) FILTER (WHERE date IS NOT NULL AND BTRIM(date) = '') AS blank_rows,
       COUNT(*) FILTER (WHERE BTRIM(COALESCE(date, '')) = '?') AS question_mark_rows
FROM raw.assessments
UNION ALL
SELECT 'raw.student_info', 'imd_band', COUNT(*),
       COUNT(*) FILTER (WHERE imd_band IS NULL),
       COUNT(*) FILTER (WHERE imd_band IS NOT NULL AND BTRIM(imd_band) = ''),
       COUNT(*) FILTER (WHERE BTRIM(COALESCE(imd_band, '')) = '?')
FROM raw.student_info
UNION ALL
SELECT 'raw.student_registration', 'date_registration', COUNT(*),
       COUNT(*) FILTER (WHERE date_registration IS NULL),
       COUNT(*) FILTER (WHERE date_registration IS NOT NULL AND BTRIM(date_registration) = ''),
       COUNT(*) FILTER (WHERE BTRIM(COALESCE(date_registration, '')) = '?')
FROM raw.student_registration
UNION ALL
SELECT 'raw.student_registration', 'date_unregistration', COUNT(*),
       COUNT(*) FILTER (WHERE date_unregistration IS NULL),
       COUNT(*) FILTER (WHERE date_unregistration IS NOT NULL AND BTRIM(date_unregistration) = ''),
       COUNT(*) FILTER (WHERE BTRIM(COALESCE(date_unregistration, '')) = '?')
FROM raw.student_registration
UNION ALL
SELECT 'raw.student_assessment', 'score', COUNT(*),
       COUNT(*) FILTER (WHERE score IS NULL),
       COUNT(*) FILTER (WHERE score IS NOT NULL AND BTRIM(score) = ''),
       COUNT(*) FILTER (WHERE BTRIM(COALESCE(score, '')) = '?')
FROM raw.student_assessment
UNION ALL
SELECT 'raw.vle', 'week_from', COUNT(*),
       COUNT(*) FILTER (WHERE week_from IS NULL),
       COUNT(*) FILTER (WHERE week_from IS NOT NULL AND BTRIM(week_from) = ''),
       COUNT(*) FILTER (WHERE BTRIM(COALESCE(week_from, '')) = '?')
FROM raw.vle
UNION ALL
SELECT 'raw.vle', 'week_to', COUNT(*),
       COUNT(*) FILTER (WHERE week_to IS NULL),
       COUNT(*) FILTER (WHERE week_to IS NOT NULL AND BTRIM(week_to) = ''),
       COUNT(*) FILTER (WHERE BTRIM(COALESCE(week_to, '')) = '?')
FROM raw.vle
ORDER BY table_name, column_name;

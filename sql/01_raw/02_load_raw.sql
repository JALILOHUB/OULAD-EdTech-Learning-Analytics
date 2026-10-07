-- ============================================================================
-- File: 02_load_raw.sql
-- Purpose: Load validated OULAD CSV files into PostgreSQL RAW tables
-- Method: PostgreSQL COPY
-- Project Owner & Lead Analyst: Abdeljalil El Khyati
-- Date: 2026-10-06
-- ============================================================================

-- IMPORTANT: Adjust the local path for another machine/environment.
-- Windows example:
-- G:/OULAD-EdTech-Learning-Analytics-starter/OULAD-EdTech-Learning-Analytics/data/raw/

COPY raw.courses
FROM 'G:/OULAD-EdTech-Learning-Analytics-starter/OULAD-EdTech-Learning-Analytics/data/raw/courses.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY raw.assessments
FROM 'G:/OULAD-EdTech-Learning-Analytics-starter/OULAD-EdTech-Learning-Analytics/data/raw/assessments.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY raw.student_info
FROM 'G:/OULAD-EdTech-Learning-Analytics-starter/OULAD-EdTech-Learning-Analytics/data/raw/studentInfo.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY raw.student_registration
FROM 'G:/OULAD-EdTech-Learning-Analytics-starter/OULAD-EdTech-Learning-Analytics/data/raw/studentRegistration.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY raw.student_assessment
FROM 'G:/OULAD-EdTech-Learning-Analytics-starter/OULAD-EdTech-Learning-Analytics/data/raw/studentAssessment.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY raw.vle
FROM 'G:/OULAD-EdTech-Learning-Analytics-starter/OULAD-EdTech-Learning-Analytics/data/raw/vle.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

COPY raw.student_vle
FROM 'G:/OULAD-EdTech-Learning-Analytics-starter/OULAD-EdTech-Learning-Analytics/data/raw/studentVle.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Row-count reconciliation
SELECT 'courses' AS table_name, COUNT(*) AS raw_row_count FROM raw.courses
UNION ALL SELECT 'assessments', COUNT(*) FROM raw.assessments
UNION ALL SELECT 'student_info', COUNT(*) FROM raw.student_info
UNION ALL SELECT 'student_registration', COUNT(*) FROM raw.student_registration
UNION ALL SELECT 'student_assessment', COUNT(*) FROM raw.student_assessment
UNION ALL SELECT 'vle', COUNT(*) FROM raw.vle
UNION ALL SELECT 'student_vle', COUNT(*) FROM raw.student_vle
ORDER BY table_name;

-- Validated source row counts:
-- courses: 22
-- assessments: 206
-- student_info: 32,593
-- student_registration: 32,593
-- student_assessment: 173,912
-- vle: 6,364
-- student_vle: 10,655,280

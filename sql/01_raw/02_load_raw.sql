-- Purpose: Load the seven OULAD CSV source files into empty RAW tables.
-- Method: PostgreSQL server-side COPY.
-- IMPORTANT: Update the paths for another machine. This script is not idempotent;
-- run only once after creating empty RAW tables, or loading will fail on primary keys.
-- Project Owner & Lead Analyst: Abdeljalil El Khyati
-- Date: 2026-10-06

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

-- Execute this SELECT separately after COPY to reconcile loaded row counts.
SELECT 'assessments' AS table_name, COUNT(*) AS raw_row_count FROM raw.assessments
UNION ALL SELECT 'courses', COUNT(*) FROM raw.courses
UNION ALL SELECT 'student_assessment', COUNT(*) FROM raw.student_assessment
UNION ALL SELECT 'student_info', COUNT(*) FROM raw.student_info
UNION ALL SELECT 'student_registration', COUNT(*) FROM raw.student_registration
UNION ALL SELECT 'student_vle', COUNT(*) FROM raw.student_vle
UNION ALL SELECT 'vle', COUNT(*) FROM raw.vle
ORDER BY table_name;

-- Validated source row counts:
-- courses: 22
-- assessments: 206
-- student_info: 32,593
-- student_registration: 32,593
-- student_assessment: 173,912
-- vle: 6,364
-- student_vle: 10,655,280
-- Total: 10,900,970

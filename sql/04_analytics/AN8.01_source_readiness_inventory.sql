-- Question: Are required staging sources present at expected broad scale?
-- Expectation: One row per source table; compare with historical baselines.
-- Grain: One row per source table.
-- Source: staging.courses, staging.assessments, staging.student_info, staging.student_registration, staging.student_assessment, staging.vle, staging.student_vle.
-- Safety: READ-ONLY SELECT; no DDL/DML or persistent objects.
-- Runtime: MODERATE; COUNT(*) on student_vle scans a large table.
-- Read as: Count differences are diagnostics, not automatic failures.
SELECT 'courses' AS source_table,COUNT(*)::BIGINT AS row_count FROM staging.courses
UNION ALL SELECT 'assessments',COUNT(*)::BIGINT FROM staging.assessments
UNION ALL SELECT 'student_info',COUNT(*)::BIGINT FROM staging.student_info
UNION ALL SELECT 'student_registration',COUNT(*)::BIGINT FROM staging.student_registration
UNION ALL SELECT 'student_assessment',COUNT(*)::BIGINT FROM staging.student_assessment
UNION ALL SELECT 'vle',COUNT(*)::BIGINT FROM staging.vle
UNION ALL SELECT 'student_vle',COUNT(*)::BIGINT FROM staging.student_vle;
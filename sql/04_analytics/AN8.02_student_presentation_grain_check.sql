-- Question: Are student_info and student_registration unique at student-presentation grain, and do their key sets reconcile?
-- Expectation: Report row counts, distinct keys, duplicate groups, and key differences.
-- Grain: One summary row per source plus key-difference rows.
-- Source: staging.student_info, staging.student_registration.
-- Safety: READ-ONLY SELECT; preserve all source rows.
-- Runtime: LOW; approximately 32.6K rows per source.
-- Read as: Unexpected duplicate groups or key differences block downstream metrics.
WITH si AS (SELECT code_module,code_presentation,id_student,COUNT(*) n FROM staging.student_info GROUP BY 1,2,3),
sr AS (SELECT code_module,code_presentation,id_student,COUNT(*) n FROM staging.student_registration GROUP BY 1,2,3),
stats AS (
 SELECT 'student_info'::TEXT source_table,COUNT(*)::BIGINT source_rows,
 COUNT(DISTINCT (code_module,code_presentation,id_student))::BIGINT distinct_keys,
 (SELECT COUNT(*)::BIGINT FROM si WHERE n>1) duplicate_key_groups FROM staging.student_info
 UNION ALL
 SELECT 'student_registration',COUNT(*)::BIGINT,
 COUNT(DISTINCT (code_module,code_presentation,id_student))::BIGINT,
 (SELECT COUNT(*)::BIGINT FROM sr WHERE n>1) FROM staging.student_registration
), diffs AS (
 SELECT 'INFO_NOT_REGISTRATION'::TEXT difference,COUNT(*)::BIGINT key_count
 FROM si LEFT JOIN sr USING(code_module,code_presentation,id_student) WHERE sr.id_student IS NULL
 UNION ALL SELECT 'REGISTRATION_NOT_INFO',COUNT(*)::BIGINT
 FROM sr LEFT JOIN si USING(code_module,code_presentation,id_student) WHERE si.id_student IS NULL
)
SELECT 'SOURCE_GRAIN' check_type,source_table check_name,source_rows,distinct_keys,duplicate_key_groups,NULL::BIGINT key_count FROM stats
UNION ALL SELECT 'KEY_DIFFERENCE',difference,NULL,NULL,NULL,key_count FROM diffs;
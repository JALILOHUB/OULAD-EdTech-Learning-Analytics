-- [P3.00] Source inventory and field profile
-- Question: Are all seven source-faithful relations present with the expected columns, and do their exact row counts reconcile to the imported working-copy snapshot?
-- Expectation: Seven relations and their column metadata are returned; exact row counts are available for all seven, including the high-volume student_vle relation.
-- Grain: Result set 1 = one row per source column; result set 2 = one row per source relation.
-- Source: oulad_an8_work.source_ref.{courses, assessments, student_info, student_registration, student_assessment, vle, student_vle}.
-- Safety: READ-ONLY SELECT. Full COUNT(*) scans may be expensive. No DDL/DML and no writes to source files.
-- Runtime: HIGH; exact counts scan all seven relations. Run once after import, not repeatedly.
-- Read as: This is an import reconciliation, not a data-quality verdict. Source values must remain unchanged. Missing/extra columns or row-count differences must be investigated before proceeding.

-- 1. Inspect imported source column names, types, and order.
SELECT table_name, ordinal_position, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'source_ref'
  AND table_name IN (
      'courses', 'assessments', 'student_info', 'student_registration',
      'student_assessment', 'vle', 'student_vle'
  )
ORDER BY table_name, ordinal_position;

-- 2. Exact imported row counts. student_vle is a full-table scan.
SELECT 'courses' AS source_table, COUNT(*)::BIGINT AS exact_rows FROM source_ref.courses
UNION ALL SELECT 'assessments', COUNT(*)::BIGINT FROM source_ref.assessments
UNION ALL SELECT 'student_info', COUNT(*)::BIGINT FROM source_ref.student_info
UNION ALL SELECT 'student_registration', COUNT(*)::BIGINT FROM source_ref.student_registration
UNION ALL SELECT 'student_assessment', COUNT(*)::BIGINT FROM source_ref.student_assessment
UNION ALL SELECT 'vle', COUNT(*)::BIGINT FROM source_ref.vle
UNION ALL SELECT 'student_vle', COUNT(*)::BIGINT FROM source_ref.student_vle
ORDER BY source_table;

-- 3. Confirm source_ref contains no unexpected relations beyond the seven imported source tables.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'source_ref'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

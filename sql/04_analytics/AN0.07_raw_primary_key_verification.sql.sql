-- Question: Do the primary-key constraints that actually exist in the RAW schema match the keys documented in docs/data_dictionary.md?
-- Expectation: Verify whether six RAW tables have validated primary keys on exactly the documented columns, in the documented order. Inspect the actual constraints and all indexes on raw.student_vle without assuming that the absence of a primary key implies the absence of indexes.
-- Grain: Statement 1 returns one row per RAW table; statement 2 returns one row per constraint type; statement 3 returns one row per index on raw.student_vle.
-- Source: PostgreSQL catalogs pg_constraint, pg_class, pg_namespace, pg_attribute, pg_indexes (metadata only; no table data is scanned).
-- Safety: READ-ONLY
-- Runtime: Very low; catalog metadata only.
-- Read as: key_status must be MATCH for six tables and EXPECTED_NO_PK for student_vle. Any other value is an observation to investigate, not a reason to alter RAW. This check does not establish uniqueness of student_vle rows; that question is handled under AN5.

-- 1. Compare documented keys with the primary keys defined in the RAW catalog.
WITH documented AS (
    SELECT *
    FROM (VALUES
        ('courses',              'code_module, code_presentation'),
        ('assessments',          'id_assessment'),
        ('student_info',         'code_module, code_presentation, id_student'),
        ('student_registration','code_module, code_presentation, id_student'),
        ('student_assessment',   'id_assessment, id_student'),
        ('vle',                  'id_site'),
        ('student_vle',          NULL)
    ) AS d(table_name, documented_key)
),
actual AS (
    SELECT c.relname AS table_name,
           con.conname AS constraint_name,
           con.convalidated AS is_validated,
           (SELECT STRING_AGG(a.attname, ', ' ORDER BY k.ord)
            FROM UNNEST(con.conkey) WITH ORDINALITY AS k(attnum, ord)
            JOIN pg_attribute AS a
              ON a.attrelid = con.conrelid AND a.attnum = k.attnum) AS actual_key
    FROM pg_constraint AS con
    JOIN pg_class AS c ON c.oid = con.conrelid
    JOIN pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname = 'raw'
      AND con.contype = 'p'
)
SELECT d.table_name,
       d.documented_key,
       a.constraint_name,
       a.actual_key,
       a.is_validated,
       CASE
           WHEN d.documented_key IS NULL AND a.actual_key IS NULL THEN 'EXPECTED_NO_PK'
           WHEN d.documented_key IS NULL AND a.actual_key IS NOT NULL THEN 'UNEXPECTED_PK'
           WHEN a.actual_key IS NULL THEN 'MISSING_PK'
           WHEN d.documented_key = a.actual_key AND a.is_validated THEN 'MATCH'
           ELSE 'DIFFERENT'
       END AS key_status
FROM documented AS d
LEFT JOIN actual AS a ON a.table_name = d.table_name
ORDER BY d.table_name;

-- 2. Count RAW constraints by type, including explicit zero counts.
-- contype: p = primary key, u = unique, f = foreign key, c = check.
WITH constraint_types(constraint_type) AS (
    VALUES ('p'::CHAR), ('u'::CHAR), ('f'::CHAR), ('c'::CHAR)
), actual_counts AS (
    SELECT con.contype AS constraint_type,
           COUNT(*)::BIGINT AS constraint_count
    FROM pg_constraint AS con
    JOIN pg_class AS c ON c.oid = con.conrelid
    JOIN pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname = 'raw'
    GROUP BY con.contype
)
SELECT t.constraint_type,
       COALESCE(a.constraint_count, 0)::BIGINT AS constraint_count
FROM constraint_types AS t
LEFT JOIN actual_counts AS a USING (constraint_type)
ORDER BY t.constraint_type;

-- 3. List every index on raw.student_vle. A non-unique candidate key does not imply that ordinary indexes are absent; interpret each returned index definition on its own terms.
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'raw'
  AND tablename = 'student_vle'
ORDER BY indexname;

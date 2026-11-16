-- [AN8.01] Source relation readiness inventory
-- Question: Are the required typed STAGING relations present, and what does PostgreSQL currently estimate about their size?
-- Expectation: Return one metadata row per required relation without scanning the 10.6M-row activity table.
-- Grain: One row per required STAGING relation.
-- Source: PostgreSQL catalogs (pg_class, pg_namespace); expected relations are the established STAGING layer.
-- Safety: READ-ONLY catalog SELECT. No source rows or database objects are changed.
-- Runtime: LOW; catalog lookup only. Estimated row counts depend on the freshness of PostgreSQL statistics.
-- Read as: estimated_rows is a planner estimate, not an exact count. Use the historical AN0.03 evidence or an explicitly approved count query when exact reconciliation is required.
WITH expected(relation_name) AS (
    VALUES
        ('courses'),
        ('assessments'),
        ('student_info'),
        ('student_registration'),
        ('student_assessment'),
        ('vle'),
        ('student_vle')
)
SELECT
    'staging.' || e.relation_name AS source_relation,
    (c.oid IS NOT NULL) AS relation_exists,
    CASE WHEN c.oid IS NULL THEN NULL ELSE GREATEST(c.reltuples, 0)::BIGINT END AS estimated_rows,
    CASE WHEN c.oid IS NULL THEN NULL ELSE s.last_analyze END AS last_analyze,
    CASE WHEN c.oid IS NULL THEN NULL ELSE s.last_autoanalyze END AS last_autoanalyze
FROM expected AS e
LEFT JOIN pg_namespace AS n
  ON n.nspname = 'staging'
LEFT JOIN pg_class AS c
  ON c.relnamespace = n.oid
 AND c.relname = e.relation_name
 AND c.relkind IN ('r', 'p')
LEFT JOIN pg_stat_all_tables AS s
  ON s.relid = c.oid
ORDER BY e.relation_name;

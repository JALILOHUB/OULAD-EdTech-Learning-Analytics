-- Question: What are the current physical sizes and index definitions of STAGING tables?
-- Expectation: STAGING may have no indexes because it was created with CREATE TABLE AS SELECT; inspect rather than assume.
-- Grain: One row per ordinary or partitioned STAGING table.
-- Source: PostgreSQL catalogs pg_class, pg_namespace, and pg_indexes.
-- Safety: READ-ONLY
-- Runtime: Very low; catalog metadata only.
-- Read as: Use sizes and index inventory to inform later performance decisions; do not create indexes in WO-1.

-- 1. Report table and total relation sizes, plus existing index names.
SELECT n.nspname AS schema_name,
       c.relname AS table_name,
       pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size_including_indexes,
       COALESCE(index_info.index_count, 0) AS index_count,
       COALESCE(index_info.index_names, '(none)') AS index_names
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
LEFT JOIN LATERAL (
    SELECT COUNT(*)::INTEGER AS index_count,
           STRING_AGG(indexname, ', ' ORDER BY indexname) AS index_names
    FROM pg_indexes AS i
    WHERE i.schemaname = n.nspname
      AND i.tablename = c.relname
) AS index_info ON TRUE
WHERE n.nspname = 'staging'
  AND c.relkind IN ('r', 'p')
ORDER BY pg_total_relation_size(c.oid) DESC, c.relname;

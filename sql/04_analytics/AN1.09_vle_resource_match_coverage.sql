-- Question: Do student_vle activity rows reference a VLE resource in the same module presentation?
-- Expectation: Quantify exact presentation matches, cross-presentation site IDs, and site IDs absent from metadata.
-- Grain: One metadata-key diagnostic row plus one row per activity match status.
-- Source: staging.student_vle, staging.vle.
-- Safety: READ-ONLY; EXISTS predicates prevent activity-row multiplication.
-- Runtime: High; scans 10.6M activity rows. Run alone with statement_timeout_ms=600000.
-- Read as: metadata_source_rows is the physical row count; distinct_site_ids and duplicate excess are separate key diagnostics.

-- 1. Keep physical row counts and distinct resource-key counts explicit.
WITH vle_key_groups AS (
    SELECT id_site, COUNT(*)::BIGINT AS group_rows
    FROM staging.vle
    GROUP BY id_site
),
vle_key_summary AS (
    SELECT (SELECT COUNT(*) FROM staging.vle)::BIGINT AS metadata_source_rows,
           COUNT(*)::BIGINT AS distinct_site_ids,
           COUNT(*) FILTER (WHERE group_rows > 1)::BIGINT AS duplicate_site_id_groups,
           COALESCE(SUM(group_rows - 1) FILTER (WHERE group_rows > 1), 0)::BIGINT AS duplicate_site_id_excess_rows
    FROM vle_key_groups
),
activity_classified AS (
    SELECT CASE
             WHEN EXISTS (
                 SELECT 1 FROM staging.vle AS v
                 WHERE v.id_site = sv.id_site
                   AND v.code_module = sv.code_module
                   AND v.code_presentation = sv.code_presentation
             ) THEN 'EXACT_PRESENTATION_MATCH'
             WHEN EXISTS (SELECT 1 FROM staging.vle AS v WHERE v.id_site = sv.id_site)
               THEN 'SITE_EXISTS_OTHER_PRESENTATION'
             ELSE 'SITE_ID_NOT_FOUND'
           END AS match_status
    FROM staging.student_vle AS sv
),
match_counts AS (
    SELECT match_status, COUNT(*)::BIGINT AS activity_rows
    FROM activity_classified
    GROUP BY match_status
)
SELECT 'VLE_KEY'::TEXT AS diagnostic, NULL::TEXT AS match_status,
       k.metadata_source_rows AS row_count,
       k.distinct_site_ids,
       k.duplicate_site_id_groups AS duplicate_groups,
       k.duplicate_site_id_excess_rows AS duplicate_excess_rows
FROM vle_key_summary AS k
UNION ALL
SELECT 'ACTIVITY_RESOURCE_MATCH', m.match_status, m.activity_rows,
       NULL::BIGINT, NULL::BIGINT, NULL::BIGINT
FROM match_counts AS m
ORDER BY diagnostic, match_status NULLS FIRST;

-- [P3.01] Repeated student_vle event semantics
-- Question: What do repeated five-column event keys represent, how often do their click values conflict, and where is their impact concentrated?
-- Expectation: R0, exact-six-column R1, and five-key MAX R2 totals reconcile; conflicting groups and representative raw rows are exposed for source-led interpretation.
-- Grain: Result set 1 = scenario totals; result set 2 = presentation-level impact; result set 3 = repeated five-key group profile; result set 4 = representative source rows.
-- Source: source_ref.student_vle; presentation context from source_ref.courses.
-- Safety: READ-ONLY SELECT. No deduplication or source modification. R1/R2 are sensitivity calculations only.
-- Runtime: HIGH; multiple full scans/groupings of the 10.6M-row relation. Run alone.
-- Read as: Repeated five-key rows are not automatically duplicates. A group with multiple sum_click values requires provenance investigation; MAX is not an approved correction.

-- 1. Compare source-faithful R0 with two explicitly hypothetical sensitivity scenarios.
WITH r1 AS (
    SELECT DISTINCT code_module, code_presentation, id_student, id_site, date, sum_click
    FROM source_ref.student_vle
),
r2 AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           MAX(CASE WHEN BTRIM(sum_click) ~ '^[0-9]+$' THEN BTRIM(sum_click)::BIGINT END) AS max_sum_click
    FROM source_ref.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
),
totals AS (
    SELECT 'R0_SOURCE'::TEXT AS scenario, COUNT(*)::BIGINT AS rows,
           SUM(CASE WHEN BTRIM(sum_click) ~ '^[0-9]+$' THEN BTRIM(sum_click)::NUMERIC END) AS clicks
    FROM source_ref.student_vle
    UNION ALL
    SELECT 'R1_EXACT_SIX_COLUMN_DISTINCT', COUNT(*)::BIGINT,
           SUM(CASE WHEN BTRIM(sum_click) ~ '^[0-9]+$' THEN BTRIM(sum_click)::NUMERIC END)
    FROM r1
    UNION ALL
    SELECT 'R2_FIVE_KEY_MAX_SENSITIVITY', COUNT(*)::BIGINT, SUM(max_sum_click)::NUMERIC
    FROM r2
)
SELECT scenario, rows, clicks FROM totals ORDER BY scenario;

-- 2. Concentration of repeated rows and click impact by module-presentation.
WITH group_profile AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           COUNT(*)::BIGINT AS group_rows,
           COUNT(DISTINCT sum_click)::BIGINT AS distinct_click_values,
           SUM(CASE WHEN BTRIM(sum_click) ~ '^[0-9]+$' THEN BTRIM(sum_click)::NUMERIC END) AS group_clicks,
           MAX(CASE WHEN BTRIM(sum_click) ~ '^[0-9]+$' THEN BTRIM(sum_click)::NUMERIC END) AS max_group_clicks
    FROM source_ref.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
)
SELECT code_module, code_presentation,
       COUNT(*) FILTER (WHERE group_rows > 1)::BIGINT AS repeated_five_key_groups,
       SUM(group_rows - 1) FILTER (WHERE group_rows > 1)::BIGINT AS excess_rows,
       COUNT(*) FILTER (WHERE distinct_click_values > 1)::BIGINT AS conflicting_click_groups,
       SUM(group_clicks - max_group_clicks) FILTER (WHERE group_rows > 1)::NUMERIC AS clicks_above_group_max
FROM group_profile
GROUP BY code_module, code_presentation
ORDER BY code_module, code_presentation;

-- 3. Distribution of repeated-group sizes and click-value conflicts.
WITH group_profile AS (
    SELECT COUNT(*)::BIGINT AS group_rows,
           COUNT(DISTINCT sum_click)::BIGINT AS distinct_click_values
    FROM source_ref.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
)
SELECT group_rows, distinct_click_values, COUNT(*)::BIGINT AS five_key_groups
FROM group_profile
WHERE group_rows > 1
GROUP BY group_rows, distinct_click_values
ORDER BY group_rows, distinct_click_values;

-- 4. Representative conflicting groups with their original source rows. Review these before proposing any event rule.
WITH conflicts AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           COUNT(*)::BIGINT AS group_rows,
           COUNT(DISTINCT sum_click)::BIGINT AS distinct_click_values
    FROM source_ref.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
    HAVING COUNT(*) > 1 AND COUNT(DISTINCT sum_click) > 1
    ORDER BY COUNT(*) DESC, code_module, code_presentation, id_student, id_site, date
    LIMIT 50
)
SELECT s.code_module, s.code_presentation, s.id_student, s.id_site, s.date,
       s.sum_click, c.group_rows, c.distinct_click_values
FROM source_ref.student_vle AS s
JOIN conflicts AS c
  USING (code_module, code_presentation, id_student, id_site, date)
ORDER BY c.group_rows DESC, s.code_module, s.code_presentation,
         s.id_student, s.id_site, s.date, s.sum_click;

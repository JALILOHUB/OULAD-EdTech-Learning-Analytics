-- [P3.01] Repeated student_vle source-row semantics
-- Question: What original source values occur inside representative repeated five-column groups whose sum_click values conflict?
-- Expectation: A bounded sample exposes every original row in the largest conflicting groups, with group-level value counts and numeric range.
-- Grain: One row per original student_vle source row belonging to a selected conflicting five-key group.
-- Source: source_ref.student_vle.
-- Safety: READ-ONLY SELECT. No deduplication, aggregation replacement, or source modification. R0/R1/R2 sensitivity results are retained from AN8.30 and are not recomputed here.
-- Runtime: HIGH; one full student_vle grouping and a source-row lookup. Run alone.
-- Read as: This query adds source-row examples for semantic review. It does not establish why repeated rows exist or approve SUM, MAX, DISTINCT, or another correction rule.

-- 1. Select a bounded set of the largest conflicting five-key groups and return their untouched source rows.
WITH group_profile AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           COUNT(*)::BIGINT AS group_rows,
           COUNT(DISTINCT sum_click)::BIGINT AS distinct_nonnull_click_values,
           COUNT(*) FILTER (WHERE sum_click IS NULL)::BIGINT AS null_click_rows,
           COUNT(*) FILTER (WHERE BTRIM(sum_click) = '')::BIGINT AS blank_click_rows,
           COUNT(*) FILTER (WHERE BTRIM(sum_click) = '?')::BIGINT AS question_mark_click_rows,
           MIN(CASE WHEN BTRIM(sum_click) ~ '^[0-9]+$'
                    THEN BTRIM(sum_click)::BIGINT END) AS minimum_numeric_clicks,
           MAX(CASE WHEN BTRIM(sum_click) ~ '^[0-9]+$'
                    THEN BTRIM(sum_click)::BIGINT END) AS maximum_numeric_clicks
    FROM source_ref.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
    HAVING COUNT(*) > 1
       AND (
           COUNT(DISTINCT sum_click) > 1
           OR COUNT(*) FILTER (WHERE sum_click IS NULL) > 0
       )
),
selected_groups AS (
    SELECT *
    FROM group_profile
    ORDER BY group_rows DESC, distinct_nonnull_click_values DESC,
             code_module, code_presentation, id_student, id_site, date
    LIMIT 50
)
SELECT s.code_module, s.code_presentation, s.id_student, s.id_site, s.date,
       s.sum_click AS original_sum_click,
       g.group_rows, g.distinct_nonnull_click_values,
       g.null_click_rows, g.blank_click_rows, g.question_mark_click_rows,
       g.minimum_numeric_clicks, g.maximum_numeric_clicks
FROM source_ref.student_vle AS s
JOIN selected_groups AS g
  USING (code_module, code_presentation, id_student, id_site, date)
ORDER BY g.group_rows DESC, s.code_module, s.code_presentation,
         s.id_student, s.id_site, s.date, s.sum_click NULLS FIRST;

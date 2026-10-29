-- Question: Does imd_band missingness differ by recorded final_result category?
-- Expectation: Each outcome category, including NULL, has a complete denominator and missingness percentage.
-- Grain: One row per observed final_result category, including NULL.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low; aggregates 32.6K rows.
-- Read as: This is a missingness cross-tab, not an outcome model. Differences can reflect presentation mix or other population differences.

-- 1. Retain missing outcomes and calculate imd_band missingness by category.
SELECT COALESCE(final_result, '<NULL>') AS final_result_category,
       COUNT(*)::BIGINT AS student_presentation_rows,
       COUNT(*) FILTER (WHERE imd_band IS NULL)::BIGINT AS imd_missing_rows,
       COUNT(*) FILTER (WHERE imd_band IS NOT NULL)::BIGINT AS imd_present_rows,
       ROUND(100.0 * COUNT(*) FILTER (WHERE imd_band IS NULL) / NULLIF(COUNT(*), 0), 2) AS pct_imd_missing
FROM staging.student_info
GROUP BY COALESCE(final_result, '<NULL>')
ORDER BY pct_imd_missing DESC, student_presentation_rows DESC;

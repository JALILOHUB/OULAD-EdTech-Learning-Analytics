-- Question: Does imd_band missingness vary across recorded regions?
-- Expectation: Each region reports its full population, missing count, and missing percentage; NULL region is retained explicitly.
-- Grain: One row per observed region value, including a NULL category.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low; aggregates 32.6K rows.
-- Read as: Compare missing percentages alongside group sizes. Association with region does not establish the reason for missingness.

-- 1. Calculate regional missingness without dropping records with a missing region.
SELECT COALESCE(region, '<NULL>') AS region_category,
       COUNT(*)::BIGINT AS student_presentation_rows,
       COUNT(*) FILTER (WHERE imd_band IS NULL)::BIGINT AS imd_missing_rows,
       COUNT(*) FILTER (WHERE imd_band IS NOT NULL)::BIGINT AS imd_present_rows,
       ROUND(100.0 * COUNT(*) FILTER (WHERE imd_band IS NULL) / NULLIF(COUNT(*), 0), 2) AS pct_imd_missing
FROM staging.student_info
GROUP BY COALESCE(region, '<NULL>')
ORDER BY pct_imd_missing DESC, student_presentation_rows DESC;

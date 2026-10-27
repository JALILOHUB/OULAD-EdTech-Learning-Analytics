-- Question: Is missing imd_band concentrated in particular module presentations?
-- Expectation: Missing and non-missing counts sum to the complete presentation population.
-- Grain: One row per module presentation.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low; aggregates 32.6K rows.
-- Read as: Missingness concentration is descriptive and does not explain why IMD data are absent.

-- 1. Quantify imd_band missingness with explicit denominators.
SELECT code_module, code_presentation,
       COUNT(*)::BIGINT AS presentation_rows,
       COUNT(*) FILTER (WHERE imd_band IS NULL)::BIGINT AS imd_missing_rows,
       COUNT(*) FILTER (WHERE imd_band IS NOT NULL)::BIGINT AS imd_present_rows,
       ROUND(100.0 * COUNT(*) FILTER (WHERE imd_band IS NULL) / NULLIF(COUNT(*), 0), 2) AS pct_imd_missing
FROM staging.student_info
GROUP BY code_module, code_presentation
ORDER BY pct_imd_missing DESC, code_module, code_presentation;

-- Question: How do final_result shares vary with num_of_prev_attempts and highest_education?
-- Expectation: No directional association is assumed. Small cells (n < 100) require cautious interpretation.
-- Grain: One row per dimension, category and final_result.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: Shares use the category total as the denominator. This is a student-presentation grain: repeat students appear once per presentation, so rows are not independent people. Association, not causation.
WITH base AS (
    SELECT 'num_of_prev_attempts' AS dimension_name,
           CASE WHEN num_of_prev_attempts >= 3 THEN '3+' ELSE num_of_prev_attempts::TEXT END AS category_value,
           final_result
    FROM staging.student_info
    UNION ALL
    SELECT 'highest_education', highest_education, final_result
    FROM staging.student_info
)
SELECT dimension_name,
       category_value,
       final_result,
       COUNT(*)::BIGINT AS rows_in_cell,
       SUM(COUNT(*)) OVER (PARTITION BY dimension_name, category_value)::BIGINT AS category_rows,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY dimension_name, category_value), 2) AS pct_within_category,
       SUM(COUNT(*)) OVER (PARTITION BY dimension_name, category_value) < 100 AS small_category_flag
FROM base
GROUP BY dimension_name, category_value, final_result
ORDER BY dimension_name, category_value, final_result;

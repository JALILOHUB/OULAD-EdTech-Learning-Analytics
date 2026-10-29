-- Question: What are the distributions of previous attempts and studied credits by presentation?
-- Expectation: Counts, missingness, central tendency, and range describe numeric fields without assuming a normal distribution.
-- Grain: One row per presentation and numeric variable.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low; aggregates 32.6K rows.
-- Read as: Median and range complement the mean. These are descriptive measures; no relationship with outcomes is inferred here.

-- 1. Summarize two numeric attributes at presentation grain.
WITH numeric_values AS (
    SELECT code_module, code_presentation, 'num_of_prev_attempts'::TEXT AS metric_name,
           num_of_prev_attempts::NUMERIC AS metric_value
    FROM staging.student_info
    UNION ALL
    SELECT code_module, code_presentation, 'studied_credits', studied_credits::NUMERIC
    FROM staging.student_info
)
SELECT code_module, code_presentation, metric_name,
       COUNT(*)::BIGINT AS total_rows,
       COUNT(metric_value)::BIGINT AS non_null_rows,
       COUNT(*) FILTER (WHERE metric_value IS NULL)::BIGINT AS null_rows,
       MIN(metric_value) AS minimum_value,
       ROUND(AVG(metric_value), 2) AS mean_value,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY metric_value) AS median_value,
       MAX(metric_value) AS maximum_value
FROM numeric_values
GROUP BY code_module, code_presentation, metric_name
ORDER BY metric_name, code_module, code_presentation;

-- Question: How are region and highest-education categories distributed within each presentation?
-- Expectation: Counts and percentages use the complete student_info population in each presentation, retaining NULL categories.
-- Grain: One row per presentation, dimension, and observed category.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low; aggregates 32.6K rows.
-- Read as: This is a descriptive composition profile. Small categories and unequal presentation sizes should be considered before comparisons.

-- 1. Compare regional and educational composition in a common output structure.
WITH categories AS (
    SELECT code_module, code_presentation, 'region'::TEXT AS dimension_name,
           COALESCE(region, '<NULL>') AS category_value
    FROM staging.student_info
    UNION ALL
    SELECT code_module, code_presentation, 'highest_education', COALESCE(highest_education, '<NULL>')
    FROM staging.student_info
),
category_counts AS (
    SELECT code_module, code_presentation, dimension_name, category_value,
           COUNT(*)::BIGINT AS category_rows
    FROM categories
    GROUP BY code_module, code_presentation, dimension_name, category_value
),
presentation_totals AS (
    SELECT code_module, code_presentation, COUNT(*)::BIGINT AS presentation_rows
    FROM staging.student_info
    GROUP BY code_module, code_presentation
)
SELECT c.code_module, c.code_presentation, c.dimension_name, c.category_value,
       c.category_rows, p.presentation_rows,
       ROUND(100.0 * c.category_rows / NULLIF(p.presentation_rows, 0), 2) AS pct_within_presentation
FROM category_counts AS c
JOIN presentation_totals AS p USING (code_module, code_presentation)
ORDER BY c.dimension_name, c.code_module, c.code_presentation, c.category_value;

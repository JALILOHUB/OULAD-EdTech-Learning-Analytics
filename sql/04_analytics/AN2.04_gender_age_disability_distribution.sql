-- Question: How are gender, age band, and disability categories distributed within each presentation?
-- Expectation: Counts and percentages use all student_info rows in each presentation; NULL categories remain explicit.
-- Grain: One row per presentation, demographic dimension, and observed category.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low; aggregates 32.6K rows.
-- Read as: Compare percentages as well as counts because presentation sizes differ. Categories are descriptive and must not be interpreted causally.

-- 1. Standardize three categorical distributions into one long result set.
WITH categories AS (
    SELECT code_module, code_presentation, 'gender'::TEXT AS dimension_name,
           COALESCE(gender, '<NULL>') AS category_value
    FROM staging.student_info
    UNION ALL
    SELECT code_module, code_presentation, 'age_band', COALESCE(age_band, '<NULL>')
    FROM staging.student_info
    UNION ALL
    SELECT code_module, code_presentation, 'disability', COALESCE(disability, '<NULL>')
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

-- Question: How are recorded final_result categories distributed within each module presentation?
-- Expectation: Percentages within each presentation should sum to approximately 100%, including the explicit NULL category.
-- Grain: One row per module presentation and observed final_result category.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low; groups approximately 32.6K rows.
-- Read as: The denominator includes every student_info row in that presentation; this is descriptive, not causal.

-- 1. Report category counts and within-presentation percentages without dropping NULL outcomes.
WITH category_counts AS (
    SELECT code_module,
           code_presentation,
           CASE WHEN final_result IS NULL THEN '<NULL>' ELSE final_result END AS final_result_category,
           COUNT(*)::BIGINT AS student_rows
    FROM staging.student_info
    GROUP BY code_module, code_presentation,
             CASE WHEN final_result IS NULL THEN '<NULL>' ELSE final_result END
)
SELECT code_module,
       code_presentation,
       final_result_category,
       student_rows,
       SUM(student_rows) OVER (
           PARTITION BY code_module, code_presentation
       ) AS presentation_student_rows,
       ROUND(
           100.0 * student_rows
           / NULLIF(SUM(student_rows) OVER (
               PARTITION BY code_module, code_presentation
           ), 0),
           2
       ) AS percentage_within_presentation
FROM category_counts
ORDER BY code_module, code_presentation, final_result_category;

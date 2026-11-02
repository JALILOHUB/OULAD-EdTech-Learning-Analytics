-- Question: Which module-presentations have unusually high or low withdrawal?
-- Expectation: Withdrawal ranges roughly from the teens to over 40% across presentations; later (J) vs earlier (B) starts may differ.
-- Grain: One row per module and presentation.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: Differences between presentations can reflect cohort size and module design, not quality. Check the denominator before ranking.
SELECT code_module,
       code_presentation,
       COUNT(*)::BIGINT AS student_rows,
       COUNT(*) FILTER (WHERE final_result = 'Withdrawn')::BIGINT AS withdrawn_rows,
       ROUND(100.0 * COUNT(*) FILTER (WHERE final_result = 'Withdrawn') / COUNT(*), 2) AS pct_withdrawn,
       ROUND(100.0 * COUNT(*) FILTER (WHERE final_result IN ('Pass', 'Distinction')) / COUNT(*), 2) AS pct_pass_or_distinction
FROM staging.student_info
GROUP BY code_module, code_presentation
ORDER BY pct_withdrawn DESC, code_module, code_presentation;

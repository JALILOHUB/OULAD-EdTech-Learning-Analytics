-- Question: How consistent is final_result = 'Withdrawn' with the presence of date_unregistration?
-- Expectation: Historical counts (10,072 rows with an unregistration date and 10,156 Withdrawn rows) are reconciliation references only; the current cross-tab must be read without forcing those values.
-- Grain: One row per final_result and unregistration-date presence.
-- Source: staging.student_info joined to staging.student_registration on the full three-column key.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: The join is one-to-one (AN1.01). Non-zero off-diagonal cells are real data conflicts: do not define withdrawal from one field until they are explained.

SELECT si.final_result,
       (sr.date_unregistration IS NOT NULL) AS has_unregistration_date,
       COUNT(*)::BIGINT AS student_presentation_rows,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY si.final_result), 2) AS pct_within_final_result
FROM staging.student_info AS si
JOIN staging.student_registration AS sr
  ON sr.code_module = si.code_module
 AND sr.code_presentation = si.code_presentation
 AND sr.id_student = si.id_student
GROUP BY si.final_result, (sr.date_unregistration IS NOT NULL)
ORDER BY si.final_result, has_unregistration_date;

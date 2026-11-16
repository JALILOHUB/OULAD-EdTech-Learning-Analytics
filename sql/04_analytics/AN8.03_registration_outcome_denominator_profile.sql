-- [AN8.03] Registration outcome denominator profile
-- Question: How does the registered student-presentation population distribute across retrospective final-result categories?
-- Expectation: Return one row per final_result category; registration match counts must reconcile after AN8.02 passes.
-- Grain: One row per final_result category, based on student_info student-presentations.
-- Source: staging.student_info, staging.student_registration.
-- Safety: READ-ONLY SELECT. final_result is retrospective context, not a predictor.
-- Runtime: LOW; approximately 32.6K source rows after the AN8.02 one-to-one key gate.
-- Read as: student_presentation_rows is the category denominator; registration_matched_rows is the matched count. Distinct student IDs are category-level counts and are not additive across presentations.
SELECT
    COALESCE(si.final_result, '[NULL]') AS final_result,
    COUNT(*)::BIGINT AS student_presentation_rows,
    COUNT(sr.id_student)::BIGINT AS registration_matched_rows,
    COUNT(DISTINCT si.id_student)::BIGINT AS distinct_student_ids_in_category
FROM staging.student_info AS si
LEFT JOIN staging.student_registration AS sr
  ON sr.code_module = si.code_module
 AND sr.code_presentation = si.code_presentation
 AND sr.id_student = si.id_student
GROUP BY 1
ORDER BY 1;

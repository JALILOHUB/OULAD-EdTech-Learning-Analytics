-- Question: What denominator and outcome categories are present at student-presentation grain?
-- Expectation: Reconcile registration matches and report outcome counts without deriving risk labels.
-- Grain: One row per final_result.
-- Source: staging.student_info, staging.student_registration.
-- Safety: READ-ONLY SELECT; final_result is retrospective context only.
-- Runtime: LOW.
-- Read as: Denominator profile, not an approved KPI.
SELECT COALESCE(si.final_result,'[NULL]') final_result,COUNT(*)::BIGINT student_presentation_rows,
 COUNT(sr.id_student)::BIGINT registration_matched_rows,COUNT(DISTINCT si.id_student)::BIGINT distinct_people
FROM staging.student_info si LEFT JOIN staging.student_registration sr
 ON sr.code_module=si.code_module AND sr.code_presentation=si.code_presentation AND sr.id_student=si.id_student
GROUP BY 1 ORDER BY 1;
-- [AN8.11] Withdrawal-date reconciliation
-- Question: How do final outcomes and unregistration-date presence reconcile?
-- Expectation: Preserve Withdrawn-without-date and non-Withdrawn-with-date anomalies.
-- Grain: One row per outcome and unregistration state.
-- Source: staging.student_info, staging.student_registration.
-- Safety: READ-ONLY SELECT; do not infer missing dates.
-- Runtime: LOW.
-- Read as: Report anomalies, do not correct them.
SELECT si.final_result,CASE WHEN sr.id_student IS NULL THEN 'NO_REGISTRATION_MATCH'
 WHEN sr.date_unregistration IS NULL THEN 'NO_UNREGISTRATION_DATE' ELSE 'HAS_UNREGISTRATION_DATE' END unregistration_state,
 COUNT(*)::BIGINT student_presentations
FROM staging.student_info si LEFT JOIN staging.student_registration sr
 ON sr.code_module=si.code_module AND sr.code_presentation=si.code_presentation AND sr.id_student=si.id_student
GROUP BY 1,2 ORDER BY 1,2;
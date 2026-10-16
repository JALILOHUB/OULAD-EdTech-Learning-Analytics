-- Purpose: Register the fifteen B5 findings already validated from supplied query outputs.
-- This version is rerun-safe: it inserts only test codes not already present in the registry.
-- Do not treat historical executed_at as known; those values remain NULL.

INSERT INTO quality.test_results
    (test_code, table_name, test_description, expected_result, actual_result,
     failed_rows, status, executed_at, notes)
SELECT v.test_code, v.table_name, v.test_description, v.expected_result,
       v.actual_result, v.failed_rows, v.status, v.executed_at::timestamptz, v.notes
FROM (VALUES
    ('B5.1_ASSESSMENTS_DATE_COMPLETENESS', 'raw.assessments', 'Count source missing tokens in date.', 'Known source-token count documented; RAW unchanged.', '206 rows; 11 ? tokens; 0 NULL; 0 blank.', 0, 'PASS', NULL, '? is observed source missingness, not automatically a source defect.'),
    ('B5.1_STUDENT_ASSESSMENT_SCORE_COMPLETENESS', 'raw.student_assessment', 'Count source missing tokens in score.', 'Known source-token count documented; RAW unchanged.', '173912 rows; 173 ? tokens; 0 NULL; 0 blank.', 0, 'PASS', NULL, 'RAW retains the source token.'),
    ('B5.1_STUDENT_INFO_IMD_COMPLETENESS', 'raw.student_info', 'Count source missing tokens in imd_band.', 'Known source-token count documented; RAW unchanged.', '32593 rows; 1111 ? tokens; 0 NULL; 0 blank.', 0, 'PASS', NULL, 'Records observed missingness, not necessarily a source defect.'),
    ('B5.1_REGISTRATION_DATE_COMPLETENESS', 'raw.student_registration', 'Count source missing tokens in date_registration.', 'Known source-token count documented; RAW unchanged.', '32593 rows; 45 ? tokens; 0 NULL; 0 blank.', 0, 'PASS', NULL, 'RAW remains unchanged.'),
    ('B5.1_UNREGISTRATION_DATE_COMPLETENESS', 'raw.student_registration', 'Count source missing tokens in date_unregistration.', 'Known source-token count documented; RAW unchanged.', '32593 rows; 22521 ? tokens; 0 NULL; 0 blank.', 0, 'PASS', NULL, 'Missing unregistration date does not prove no withdrawal.'),
    ('B5.1_VLE_WEEK_FROM_COMPLETENESS', 'raw.vle', 'Count source missing tokens in week_from.', 'Known source-token count documented; RAW unchanged.', '6364 rows; 5243 ? tokens; 0 NULL; 0 blank.', 0, 'PASS', NULL, 'Range checks apply only to parseable values.'),
    ('B5.1_VLE_WEEK_TO_COMPLETENESS', 'raw.vle', 'Count source missing tokens in week_to.', 'Known source-token count documented; RAW unchanged.', '6364 rows; 5243 ? tokens; 0 NULL; 0 blank.', 0, 'PASS', NULL, 'Range checks apply only to parseable values.'),
    ('B5.2_STUDENT_ASSESSMENT_SCORE_RANGE', 'raw.student_assessment', 'Validate parseable scores against 0–100.', 'No parseable scores outside 0–100; ? tokens documented.', '173912 rows; 173 ?; no other nonnumeric; min 0; max 100; 0 out of range.', 0, 'PASS', NULL, 'Numeric bounds only.'),
    ('B5.2_STUDENT_VLE_SUM_CLICK_NUMERIC', 'raw.student_vle', 'Check NULL, negative, zero, and positive sum_click values.', 'No NULL, negative, or zero values under tested rule.', '10655280 rows; 0 NULL/negative/zero; min 1; max 6977; sum 39605099.', 0, 'PASS', NULL, 'Does not explain repeated keys.'),
    ('B5.2_ASSESSMENT_WEIGHT_RANGE', 'raw.assessments', 'Check assessment weight bounds.', 'No NULL, negative, or above-100 values.', '206 rows; min 0; max 100; sum 4300.0 across table.', 0, 'PASS', NULL, 'Table-wide sum is descriptive; no global sum-to-100 rule.'),
    ('B5.2_CATEGORICAL_VALUES_REVIEW', 'raw.student_info', 'Capture observed categorical values.', 'Compare observed values with documented domains used for this project.', 'Categories captured for gender, age_band, disability, final_result, highest_education, region, code_module.', NULL, 'REVIEW', NULL, 'Distribution alone does not prove allowed-value compliance.'),
    ('B5.3_REGISTRATION_DATE_ORDER', 'raw.student_registration', 'Check registration/unregistration day ordering.', 'No unregistration before registration.', '32593 rows; 0 earlier; 19 same-day; 45 registration and 22521 unregistration tokens nonnumeric.', 0, 'PASS', NULL, 'Same-day values are not automatically invalid.'),
    ('B5.3_SUBMISSION_VS_ASSESSMENT_DATE', 'raw.student_assessment', 'Describe submission timing against listed assessment day.', 'Diagnostic only; no automatic rejection rule.', '173912 rows; 49318 after; 29469 on; 92260 before; 2865 unavailable assessment day.', NULL, 'REVIEW', NULL, 'After-date submissions may be late; source semantics need confirmation.'),
    ('B5.3_STUDENT_VLE_RELATIVE_DAY', 'raw.student_vle', 'Compare relative activity day with presentation length.', 'No values beyond length; interpret negative days.', '10655280 rows; 688988 negative; 0 beyond; date range -25 to 269.', NULL, 'REVIEW', NULL, 'Negative relative days are not automatically invalid.'),
    ('B5.3_VLE_WEEK_RANGE', 'raw.vle', 'Check numeric week_from/week_to ordering.', 'No reversed ranges among parseable values.', '6364 rows; 5243 missing/non-numeric in each; 0 reversed; numeric ranges 0–29.', 0, 'PASS', NULL, 'Missingness is recorded separately.')
) AS v(test_code, table_name, test_description, expected_result, actual_result,
        failed_rows, status, executed_at, notes)
WHERE NOT EXISTS (
    SELECT 1 FROM quality.test_results existing
    WHERE existing.test_code = v.test_code
);

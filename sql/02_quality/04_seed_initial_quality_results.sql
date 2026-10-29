-- Purpose: Seed the initial B2/B3 findings into the quality registry.
-- The original insert was a one-time operation. This version checks test_code first,
-- so existing records are not duplicated when the script is re-run.
-- Historical executed_at values remain NULL because exact execution timestamps
-- were not captured at the time of the original tests.

INSERT INTO quality.test_results
    (test_code, table_name, test_description, expected_result, actual_result,
     failed_rows, status, executed_at, notes)
SELECT v.test_code, v.table_name, v.test_description, v.expected_result,
       v.actual_result, v.failed_rows, v.status, v.executed_at::timestamptz, v.notes
FROM (VALUES
    ('B2.1_ASSESSMENTS_KEY', 'raw.assessments', 'Validate uniqueness and completeness of the candidate key.', 'No NULL key rows and no duplicate candidate-key groups.', '206 rows; 0 NULL key rows; 0 duplicate key groups.', 0, 'PASS', NULL, 'Result supplied from the completed B2.1 query.'),
    ('B2.1_COURSES_KEY', 'raw.courses', 'Validate uniqueness and completeness of the candidate key.', 'No NULL key rows and no duplicate candidate-key groups.', '22 rows; 0 NULL key rows; 0 duplicate key groups.', 0, 'PASS', NULL, 'Result supplied from the completed B2.1 query.'),
    ('B2.1_STUDENT_ASSESSMENT_KEY', 'raw.student_assessment', 'Validate uniqueness and completeness of the candidate key.', 'No NULL key rows and no duplicate candidate-key groups.', '173912 rows; 0 NULL key rows; 0 duplicate key groups.', 0, 'PASS', NULL, 'Result supplied from the completed B2.1 query.'),
    ('B2.1_STUDENT_INFO_KEY', 'raw.student_info', 'Validate uniqueness and completeness of the candidate key.', 'No NULL key rows and no duplicate candidate-key groups.', '32593 rows; 0 NULL key rows; 0 duplicate key groups.', 0, 'PASS', NULL, 'Result supplied from the completed B2.1 query.'),
    ('B2.1_STUDENT_REGISTRATION_KEY', 'raw.student_registration', 'Validate uniqueness and completeness of the candidate key.', 'No NULL key rows and no duplicate candidate-key groups.', '32593 rows; 0 NULL key rows; 0 duplicate key groups.', 0, 'PASS', NULL, 'Result supplied from the completed B2.1 query.'),
    ('B2.1_VLE_KEY', 'raw.vle', 'Validate uniqueness and completeness of the candidate key.', 'No NULL key rows and no duplicate candidate-key groups.', '6364 rows; 0 NULL key rows; 0 duplicate key groups.', 0, 'PASS', NULL, 'Result supplied from the completed B2.1 query.'),
    ('B2.2_STUDENT_VLE_KEY', 'raw.student_vle', 'Recheck the proposed five-column candidate key.', 'Candidate key uniqueness must be established before accepting it.', '10655280 rows; 8459320 distinct candidate keys; 2195960 excess rows.', 2195960, 'REVIEW', NULL, 'Do not delete or aggregate rows until the repeated-key patterns are explained.'),
    ('B3.1_ASSESSMENTS_COURSES', 'raw.assessments', 'Check assessment references to courses.', 'No unmatched parent references.', '0 unmatched rows.', 0, 'PASS', NULL, 'Result supplied from the completed B3.1 query.'),
    ('B3.1_STUDENT_ASSESSMENT_ASSESSMENTS', 'raw.student_assessment', 'Check student assessment references to assessments.', 'No unmatched parent references.', '0 unmatched rows.', 0, 'PASS', NULL, 'Result supplied from the completed B3.1 query.'),
    ('B3.1_STUDENT_INFO_COURSES', 'raw.student_info', 'Check student information references to courses.', 'No unmatched parent references.', '0 unmatched rows.', 0, 'PASS', NULL, 'Result supplied from the completed B3.1 query.'),
    ('B3.1_STUDENT_REGISTRATION_COURSES', 'raw.student_registration', 'Check student registration references to courses.', 'No unmatched parent references.', '0 unmatched rows.', 0, 'PASS', NULL, 'Result supplied from the completed B3.1 query.'),
    ('B3.1_STUDENT_VLE_VLE', 'raw.student_vle', 'Check student VLE activity references to VLE resources.', 'No unmatched parent references.', '0 unmatched rows.', 0, 'PASS', NULL, 'Result supplied from the completed B3.1 query.'),
    ('B3.2_ASSESSMENT_REFERENCE', 'raw.student_assessment', 'Check student assessment references to assessment definitions.', 'No unmatched assessment references.', '173912 rows; 0 unmatched assessment rows.', 0, 'PASS', NULL, 'Result supplied from the completed B3.2 query.'),
    ('B3.2_STUDENT_COURSE_REFERENCE', 'raw.student_assessment', 'Check assessment records against the corresponding student-course record.', 'No unmatched student-course references for matched assessments.', '173912 rows; 0 unmatched student-course rows.', 0, 'PASS', NULL, 'Result supplied from the completed B3.2 query.')
) AS v(test_code, table_name, test_description, expected_result, actual_result,
        failed_rows, status, executed_at, notes)
WHERE NOT EXISTS (
    SELECT 1 FROM quality.test_results existing
    WHERE existing.test_code = v.test_code
);

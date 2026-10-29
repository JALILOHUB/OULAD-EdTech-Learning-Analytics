-- Purpose: Validate tested numeric rules and document categorical values in RAW.
-- Execute each SELECT separately in pgAdmin.

-- B5.2.1: Assessment score parsing and numeric bounds.
WITH parsed_scores AS (
    SELECT score,
           CASE WHEN BTRIM(COALESCE(score, '')) ~ '^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$'
                THEN BTRIM(score)::numeric ELSE NULL END AS score_numeric
    FROM raw.student_assessment
)
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE score IS NULL) AS null_scores,
       COUNT(*) FILTER (WHERE BTRIM(COALESCE(score, '')) = '') AS blank_scores,
       COUNT(*) FILTER (WHERE BTRIM(COALESCE(score, '')) = '?') AS question_mark_scores,
       COUNT(*) FILTER (WHERE score IS NOT NULL AND BTRIM(score) <> ''
                          AND BTRIM(score) <> '?'
                          AND score_numeric IS NULL) AS other_nonnumeric_scores,
       COUNT(*) FILTER (WHERE score_numeric < 0 OR score_numeric > 100) AS out_of_range_scores,
       MIN(score_numeric) AS minimum_score,
       MAX(score_numeric) AS maximum_score
FROM parsed_scores;

-- B5.2.2: Numeric validity of student VLE click counts; this does not explain repeated keys.
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE sum_click IS NULL) AS null_values,
       COUNT(*) FILTER (WHERE sum_click < 0) AS negative_values,
       COUNT(*) FILTER (WHERE sum_click = 0) AS zero_values,
       COUNT(*) FILTER (WHERE sum_click > 0) AS positive_values,
       MIN(sum_click) AS minimum_value,
       MAX(sum_click) AS maximum_value,
       SUM(sum_click) AS total_sum_click
FROM raw.student_vle;

-- B5.2.3: Assessment weight bounds. The table-wide sum is descriptive, not a sum-to-100 rule.
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE weight IS NULL) AS null_weights,
       COUNT(*) FILTER (WHERE weight < 0) AS negative_weights,
       COUNT(*) FILTER (WHERE weight > 100) AS weights_above_100,
       MIN(weight) AS minimum_weight,
       MAX(weight) AS maximum_weight,
       SUM(weight) AS table_wide_weight_sum
FROM raw.assessments;

-- B5.2.4: Capture observed categorical values.
SELECT 'gender' AS column_name, gender AS observed_value, COUNT(*) AS row_count
FROM raw.student_info GROUP BY gender
UNION ALL
SELECT 'age_band', age_band, COUNT(*) FROM raw.student_info GROUP BY age_band
UNION ALL
SELECT 'disability', disability, COUNT(*) FROM raw.student_info GROUP BY disability
UNION ALL
SELECT 'final_result', final_result, COUNT(*) FROM raw.student_info GROUP BY final_result
UNION ALL
SELECT 'highest_education', highest_education, COUNT(*)
FROM raw.student_info GROUP BY highest_education
UNION ALL
SELECT 'region', region, COUNT(*) FROM raw.student_info GROUP BY region
UNION ALL
SELECT 'code_module', code_module, COUNT(*)
FROM raw.student_registration GROUP BY code_module
ORDER BY column_name, observed_value;

-- B5.2.5: Check the observed values against the documented domains used for this project.
-- A zero-row result means no values outside these listed domains were found.
SELECT 'gender' AS column_name, gender AS observed_value, COUNT(*) AS row_count
FROM raw.student_info
WHERE gender NOT IN ('F', 'M') OR gender IS NULL
GROUP BY gender
UNION ALL
SELECT 'age_band', age_band, COUNT(*)
FROM raw.student_info
WHERE age_band NOT IN ('0-35', '35-55', '55<=') OR age_band IS NULL
GROUP BY age_band
UNION ALL
SELECT 'disability', disability, COUNT(*)
FROM raw.student_info
WHERE disability NOT IN ('N', 'Y') OR disability IS NULL
GROUP BY disability
UNION ALL
SELECT 'final_result', final_result, COUNT(*)
FROM raw.student_info
WHERE final_result NOT IN ('Distinction', 'Fail', 'Pass', 'Withdrawn') OR final_result IS NULL
GROUP BY final_result
UNION ALL
SELECT 'highest_education', highest_education, COUNT(*)
FROM raw.student_info
WHERE highest_education NOT IN (
    'A Level or Equivalent', 'HE Qualification', 'Lower Than A Level',
    'No Formal quals', 'Post Graduate Qualification'
) OR highest_education IS NULL
GROUP BY highest_education
UNION ALL
SELECT 'region', region, COUNT(*)
FROM raw.student_info
WHERE region NOT IN (
    'East Anglian Region', 'East Midlands Region', 'Ireland', 'London Region',
    'North Region', 'North Western Region', 'Scotland', 'South East Region',
    'South Region', 'South West Region', 'Wales', 'West Midlands Region',
    'Yorkshire Region'
) OR region IS NULL
GROUP BY region
UNION ALL
SELECT 'code_module', code_module, COUNT(*)
FROM raw.student_info
WHERE code_module NOT IN ('AAA', 'BBB', 'CCC', 'DDD', 'EEE', 'FFF', 'GGG')
   OR code_module IS NULL
GROUP BY code_module
ORDER BY column_name, observed_value;

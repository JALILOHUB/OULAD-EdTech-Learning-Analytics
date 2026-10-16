-- Purpose: Validate proposed type conversions and missing-token patterns in RAW before STAGING creation.
-- Execute each SELECT separately in pgAdmin. Do not execute table creation here.

-- C2.1: Validate integer conversion of assessment day values in RAW.
WITH parsed AS (
    SELECT date,
           CASE WHEN BTRIM(COALESCE(date, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(date)::INTEGER END AS day_value
    FROM raw.assessments
)
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE date IS NULL OR BTRIM(date) = '?') AS missing_tokens,
       COUNT(*) FILTER (WHERE date IS NOT NULL AND BTRIM(date) <> '?'
                          AND day_value IS NULL) AS non_integer_tokens,
       MIN(day_value) AS minimum_day,
       MAX(day_value) AS maximum_day
FROM parsed;

-- C2.2: Validate integer conversion of registration day values in RAW.
WITH parsed AS (
    SELECT date_registration, date_unregistration,
           CASE WHEN BTRIM(COALESCE(date_registration, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(date_registration)::INTEGER END AS registration_day,
           CASE WHEN BTRIM(COALESCE(date_unregistration, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(date_unregistration)::INTEGER END AS unregistration_day
    FROM raw.student_registration
)
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE date_registration IS NULL OR BTRIM(date_registration) = '?') AS missing_registration_tokens,
       COUNT(*) FILTER (WHERE date_registration IS NOT NULL AND BTRIM(date_registration) <> '?'
                          AND registration_day IS NULL) AS invalid_registration_tokens,
       COUNT(*) FILTER (WHERE date_unregistration IS NULL OR BTRIM(date_unregistration) = '?') AS missing_unregistration_tokens,
       COUNT(*) FILTER (WHERE date_unregistration IS NOT NULL AND BTRIM(date_unregistration) <> '?'
                          AND unregistration_day IS NULL) AS invalid_unregistration_tokens,
       MIN(registration_day) AS minimum_registration_day,
       MAX(registration_day) AS maximum_registration_day,
       MIN(unregistration_day) AS minimum_unregistration_day,
       MAX(unregistration_day) AS maximum_unregistration_day
FROM parsed;

-- C2.3: Validate conversion of assessment score to NUMERIC in STAGING.
WITH parsed AS (
    SELECT score,
           CASE WHEN BTRIM(COALESCE(score, '')) ~ '^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$'
                THEN BTRIM(score)::NUMERIC END AS score_numeric
    FROM raw.student_assessment
)
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE score IS NULL OR BTRIM(score) = '?') AS missing_tokens,
       COUNT(*) FILTER (WHERE score IS NOT NULL AND BTRIM(score) <> '?'
                          AND score_numeric IS NULL) AS invalid_numeric_tokens,
       COUNT(*) FILTER (WHERE score_numeric < 0) AS negative_scores,
       COUNT(*) FILTER (WHERE score_numeric > 100) AS scores_above_100,
       MIN(score_numeric) AS minimum_score,
       MAX(score_numeric) AS maximum_score
FROM parsed;

-- C2.4: Validate integer conversion of VLE week values in RAW.
WITH parsed AS (
    SELECT week_from, week_to,
           CASE WHEN BTRIM(COALESCE(week_from, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(week_from)::INTEGER END AS week_from_num,
           CASE WHEN BTRIM(COALESCE(week_to, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(week_to)::INTEGER END AS week_to_num
    FROM raw.vle
)
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE week_from IS NULL OR BTRIM(week_from) = '?') AS missing_week_from,
       COUNT(*) FILTER (WHERE week_from IS NOT NULL AND BTRIM(week_from) <> '?'
                          AND week_from_num IS NULL) AS invalid_week_from,
       COUNT(*) FILTER (WHERE week_to IS NULL OR BTRIM(week_to) = '?') AS missing_week_to,
       COUNT(*) FILTER (WHERE week_to IS NOT NULL AND BTRIM(week_to) <> '?'
                          AND week_to_num IS NULL) AS invalid_week_to,
       MIN(week_from_num) AS minimum_week_from,
       MAX(week_from_num) AS maximum_week_from,
       MIN(week_to_num) AS minimum_week_to,
       MAX(week_to_num) AS maximum_week_to
FROM parsed;

-- C2.5: Profile imd_band before mapping the source missing token in STAGING.
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE imd_band IS NULL OR BTRIM(imd_band) = '?') AS missing_tokens,
       COUNT(*) FILTER (WHERE imd_band IS NOT NULL AND BTRIM(imd_band) = '') AS blank_values,
       COUNT(*) FILTER (WHERE imd_band IS NOT NULL AND BTRIM(imd_band) <> ''
                          AND BTRIM(imd_band) <> '?') AS populated_text_values,
       COUNT(DISTINCT BTRIM(imd_band)) FILTER (WHERE imd_band IS NOT NULL
                          AND BTRIM(imd_band) <> '' AND BTRIM(imd_band) <> '?') AS distinct_populated_values
FROM raw.student_info;

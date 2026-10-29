-- Purpose: Describe temporal relationships and relative-day ranges without imposing
-- undocumented rejection rules. Execute each SELECT separately in pgAdmin.

-- B5.3.1: Registration and unregistration day ordering.
WITH parsed_dates AS (
    SELECT date_registration, date_unregistration,
           CASE WHEN BTRIM(COALESCE(date_registration, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(date_registration)::integer END AS registration_day,
           CASE WHEN BTRIM(COALESCE(date_unregistration, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(date_unregistration)::integer END AS unregistration_day
    FROM raw.student_registration
)
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE registration_day IS NULL) AS unavailable_registration_day,
       COUNT(*) FILTER (WHERE unregistration_day IS NULL) AS unavailable_unregistration_day,
       COUNT(*) FILTER (WHERE registration_day IS NOT NULL AND unregistration_day IS NOT NULL
                          AND unregistration_day < registration_day) AS unregistration_before_registration,
       COUNT(*) FILTER (WHERE registration_day IS NOT NULL AND unregistration_day IS NOT NULL
                          AND unregistration_day = registration_day) AS same_day_registration
FROM parsed_dates;

-- B5.3.2: Compare submission day with the listed assessment day.
WITH assessment_days AS (
    SELECT id_assessment,
           CASE WHEN BTRIM(COALESCE(date, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(date)::integer END AS assessment_day
    FROM raw.assessments
)
SELECT COUNT(*) AS matched_rows,
       COUNT(*) FILTER (WHERE a.assessment_day IS NOT NULL
                          AND sa.date_submitted > a.assessment_day) AS submissions_after_assessment_day,
       COUNT(*) FILTER (WHERE a.assessment_day IS NOT NULL
                          AND sa.date_submitted = a.assessment_day) AS submissions_on_assessment_day,
       COUNT(*) FILTER (WHERE a.assessment_day IS NOT NULL
                          AND sa.date_submitted < a.assessment_day) AS submissions_before_assessment_day,
       COUNT(*) FILTER (WHERE a.assessment_day IS NULL) AS unavailable_assessment_day
FROM raw.student_assessment sa
JOIN assessment_days a USING (id_assessment);

-- B5.3.3: Compare VLE activity days with module presentation lengths.
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE sv.date < 0) AS negative_relative_days,
       COUNT(*) FILTER (WHERE sv.date > c.module_presentation_length) AS days_beyond_presentation_length,
       MIN(sv.date) AS minimum_relative_day,
       MAX(sv.date) AS maximum_relative_day,
       MIN(c.module_presentation_length) AS minimum_presentation_length,
       MAX(c.module_presentation_length) AS maximum_presentation_length
FROM raw.student_vle sv
JOIN raw.courses c
  ON c.code_module = sv.code_module
 AND c.code_presentation = sv.code_presentation;

-- B5.3.4: Validate parseable VLE week ranges.
WITH parsed_weeks AS (
    SELECT week_from, week_to,
           CASE WHEN BTRIM(COALESCE(week_from, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(week_from)::integer END AS week_from_num,
           CASE WHEN BTRIM(COALESCE(week_to, '')) ~ '^-?[0-9]+$'
                THEN BTRIM(week_to)::integer END AS week_to_num
    FROM raw.vle
)
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE week_from_num IS NULL) AS missing_or_nonnumeric_week_from,
       COUNT(*) FILTER (WHERE week_to_num IS NULL) AS missing_or_nonnumeric_week_to,
       COUNT(*) FILTER (WHERE week_from_num IS NOT NULL AND week_to_num IS NOT NULL
                          AND week_from_num > week_to_num) AS reversed_numeric_ranges,
       MIN(week_from_num) AS minimum_week_from,
       MAX(week_from_num) AS maximum_week_from,
       MIN(week_to_num) AS minimum_week_to,
       MAX(week_to_num) AS maximum_week_to
FROM parsed_weeks;

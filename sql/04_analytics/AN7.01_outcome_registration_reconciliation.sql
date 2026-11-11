-- Question: How do final_result, registration dates, and unregistration dates relate at student-presentation grain?
-- Expectation: Reproduce the documented outcome/date conflicts (93 Withdrawn without a date and 9 non-Withdrawn with a date) as reconciliation references, not forced targets.
-- Grain: Result set 1 = final_result × registration/unregistration timing; result set 2 = presentation-level anomaly groups; result set 3 = presentation-level registration-date quality.
-- Source: staging.student_info, staging.student_registration, staging.courses.
-- Safety: READ-ONLY. No source changes, DDL, temporary tables, or persistent objects.
-- Runtime: LOW. Aggregates approximately 32.6K student-presentation rows.
-- Read as: Keep final_result and date_unregistration separate. Timing is relative to course start/end, not personal registration. Report anomalies; do not correct them.

-- 1. Outcome and date-timing reconciliation.
WITH base AS (
    SELECT si.code_module, si.code_presentation, si.id_student, si.final_result,
           sr.id_student AS registration_match, sr.date_registration,
           sr.date_unregistration, c.module_presentation_length
    FROM staging.student_info AS si
    LEFT JOIN staging.student_registration AS sr
      ON sr.code_module=si.code_module
     AND sr.code_presentation=si.code_presentation
     AND sr.id_student=si.id_student
    LEFT JOIN staging.courses AS c
      ON c.code_module=si.code_module
     AND c.code_presentation=si.code_presentation
)
SELECT final_result,
       CASE
         WHEN registration_match IS NULL THEN 'NO_REGISTRATION_MATCH'
         WHEN date_unregistration IS NULL THEN 'NO_UNREGISTRATION_DATE'
         WHEN module_presentation_length IS NULL THEN 'COURSE_WINDOW_MISSING'
         WHEN date_unregistration < 0 THEN 'BEFORE_COURSE_START'
         WHEN date_unregistration <= module_presentation_length THEN 'WITHIN_COURSE_WINDOW'
         ELSE 'AFTER_COURSE_WINDOW'
       END AS unregistration_timing,
       CASE
         WHEN registration_match IS NULL THEN 'NO_REGISTRATION_MATCH'
         WHEN date_registration IS NULL THEN 'REGISTRATION_DATE_MISSING'
         WHEN date_registration < 0 THEN 'REGISTERED_BEFORE_START'
         WHEN date_registration = 0 THEN 'REGISTERED_ON_START'
         ELSE 'REGISTERED_AFTER_START'
       END AS registration_timing,
       COUNT(*)::BIGINT AS student_presentation_rows
FROM base
GROUP BY 1,2,3;

-- 2. Outcome/unregistration conflicts by module-presentation.
WITH base AS (
    SELECT si.code_module, si.code_presentation, si.id_student, si.final_result,
           sr.id_student AS registration_match, sr.date_unregistration
    FROM staging.student_info AS si
    LEFT JOIN staging.student_registration AS sr
      ON sr.code_module=si.code_module
     AND sr.code_presentation=si.code_presentation
     AND sr.id_student=si.id_student
)
SELECT code_module, code_presentation,
       CASE
         WHEN final_result IS NULL THEN 'MISSING_FINAL_RESULT'
         WHEN final_result='Withdrawn' AND registration_match IS NULL
           THEN 'WITHDRAWN_WITHOUT_REGISTRATION_MATCH'
         WHEN final_result='Withdrawn' AND date_unregistration IS NULL
           THEN 'WITHDRAWN_WITHOUT_UNREGISTRATION_DATE'
         WHEN final_result <> 'Withdrawn' AND date_unregistration IS NOT NULL
           THEN 'NON_WITHDRAWN_WITH_UNREGISTRATION_DATE'
       END AS anomaly_group,
       final_result,
       COUNT(*)::BIGINT AS student_presentation_rows,
       MIN(date_unregistration) AS min_unregistration_day,
       MAX(date_unregistration) AS max_unregistration_day
FROM base
WHERE final_result IS NULL
   OR (final_result='Withdrawn'
       AND (registration_match IS NULL OR date_unregistration IS NULL))
   OR (final_result <> 'Withdrawn' AND date_unregistration IS NOT NULL)
GROUP BY 1,2,3,4;

-- 3. Registration-date completeness by module-presentation.
SELECT code_module, code_presentation,
       COUNT(*)::BIGINT AS registration_rows,
       COUNT(*) FILTER (WHERE date_registration IS NULL)::BIGINT AS missing_registration_date_rows,
       COUNT(*) FILTER (WHERE date_registration < 0)::BIGINT AS registrations_before_start,
       COUNT(*) FILTER (WHERE date_registration = 0)::BIGINT AS registrations_on_start,
       COUNT(*) FILTER (WHERE date_registration > 0)::BIGINT AS registrations_after_start,
       COUNT(*) FILTER (WHERE date_unregistration IS NULL)::BIGINT AS missing_unregistration_date_rows,
       COUNT(*) FILTER (WHERE date_unregistration IS NOT NULL)::BIGINT AS rows_with_unregistration_date
FROM staging.student_registration
GROUP BY code_module, code_presentation;

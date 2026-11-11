-- Question: Which registered student-presentations are eligible at each proposed landmark?
-- Expectation: One row per student-presentation. Missing registration dates and undated Withdrawn outcomes remain explicit.
-- Grain: One row per student-presentation: (code_module, code_presentation, id_student).
-- Source: staging.student_info, staging.student_registration, staging.courses.
-- Safety: READ-ONLY. No source changes, DDL, temporary tables, or persistent objects.
-- Runtime: LOW. Joins and classifies approximately 32.6K student-presentation rows.
-- Read as: final_result is retrospective and is an outcome, never a feature. AT_RISK requires a known registration date by L, no unregistration on/before L, and no undated Withdrawn conflict.

WITH base AS (
    SELECT si.code_module,si.code_presentation,si.id_student,si.final_result,
           si.gender,si.region,si.highest_education,si.imd_band,si.age_band,
           si.num_of_prev_attempts,si.studied_credits,si.disability,
           (sr.id_student IS NOT NULL) AS registration_match,
           sr.date_registration,sr.date_unregistration,
           CASE WHEN sr.date_registration IS NULL THEN NULL
                ELSE GREATEST(0,sr.date_registration) END AS registered_activity_start_day,
           c.module_presentation_length,
           (c.code_module IS NOT NULL) AS course_window_match
    FROM staging.student_info si
    LEFT JOIN staging.student_registration sr
      ON sr.code_module=si.code_module
     AND sr.code_presentation=si.code_presentation
     AND sr.id_student=si.id_student
    LEFT JOIN staging.courses c
      ON c.code_module=si.code_module AND c.code_presentation=si.code_presentation
),
classified AS (
    SELECT b.*,
      CASE
        WHEN NOT course_window_match THEN 'NO_COURSE_WINDOW'
        WHEN module_presentation_length < 27 THEN 'LANDMARK_OUTSIDE_COURSE'
        WHEN NOT registration_match THEN 'NO_REGISTRATION_MATCH'
        WHEN date_registration IS NULL THEN 'REGISTRATION_DATE_MISSING'
        WHEN date_registration > 27 THEN 'NOT_REGISTERED_BY_LANDMARK'
        WHEN final_result='Withdrawn' AND date_unregistration IS NULL THEN 'INDETERMINATE_WITHDRAWAL_TIMING'
        WHEN date_unregistration IS NOT NULL AND date_unregistration <= 27 THEN 'UNREGISTERED_BY_LANDMARK'
        ELSE 'AT_RISK'
      END AS risk_status_l28,
      CASE
        WHEN NOT course_window_match THEN 'NO_COURSE_WINDOW'
        WHEN module_presentation_length < 55 THEN 'LANDMARK_OUTSIDE_COURSE'
        WHEN NOT registration_match THEN 'NO_REGISTRATION_MATCH'
        WHEN date_registration IS NULL THEN 'REGISTRATION_DATE_MISSING'
        WHEN date_registration > 55 THEN 'NOT_REGISTERED_BY_LANDMARK'
        WHEN final_result='Withdrawn' AND date_unregistration IS NULL THEN 'INDETERMINATE_WITHDRAWAL_TIMING'
        WHEN date_unregistration IS NOT NULL AND date_unregistration <= 55 THEN 'UNREGISTERED_BY_LANDMARK'
        ELSE 'AT_RISK'
      END AS risk_status_l56,
      CASE
        WHEN NOT course_window_match THEN 'NO_COURSE_WINDOW'
        WHEN module_presentation_length < 83 THEN 'LANDMARK_OUTSIDE_COURSE'
        WHEN NOT registration_match THEN 'NO_REGISTRATION_MATCH'
        WHEN date_registration IS NULL THEN 'REGISTRATION_DATE_MISSING'
        WHEN date_registration > 83 THEN 'NOT_REGISTERED_BY_LANDMARK'
        WHEN final_result='Withdrawn' AND date_unregistration IS NULL THEN 'INDETERMINATE_WITHDRAWAL_TIMING'
        WHEN date_unregistration IS NOT NULL AND date_unregistration <= 83 THEN 'UNREGISTERED_BY_LANDMARK'
        ELSE 'AT_RISK'
      END AS risk_status_l84
    FROM base b
)
SELECT code_module,code_presentation,id_student,final_result,
       gender,region,highest_education,imd_band,age_band,num_of_prev_attempts,
       studied_credits,disability,registration_match,course_window_match,
       date_registration,date_unregistration,registered_activity_start_day,
       module_presentation_length,
       risk_status_l28,(risk_status_l28='AT_RISK') AS at_risk_l28,
       risk_status_l56,(risk_status_l56='AT_RISK') AS at_risk_l56,
       risk_status_l84,(risk_status_l84='AT_RISK') AS at_risk_l84
FROM classified;

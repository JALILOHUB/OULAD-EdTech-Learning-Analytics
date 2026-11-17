-- [AN8.32] Registration and exposure profile
-- Question: How much course exposure is available after registration, and which records have unknown, zero, or late-start exposure?
-- Expectation: Keep missing registration dates separate; calculate inclusive exposure from max(registration day, 0) through course length.
-- Grain: One row per module-presentation and registration/exposure state.
-- Source: staging.student_registration, staging.courses.
-- Safety: READ-ONLY SELECT. No missing-date imputation.
-- Runtime: LOW; approximately 32.6K registration rows.
-- Read as: Exposure days are opportunity-to-observe denominators, not proof of actual engagement or attendance.

WITH classified AS (
 SELECT r.code_module,r.code_presentation,r.id_student,r.date_registration,
        c.module_presentation_length,
        CASE WHEN r.date_registration IS NULL THEN 'MISSING_REGISTRATION_DATE'
             WHEN r.date_registration<0 THEN 'BEFORE_COURSE_START'
             WHEN r.date_registration=0 THEN 'ON_COURSE_START'
             ELSE 'AFTER_COURSE_START' END registration_state,
        CASE WHEN r.date_registration IS NULL THEN NULL
             WHEN GREATEST(r.date_registration,0)>c.module_presentation_length THEN 0
             ELSE c.module_presentation_length-GREATEST(r.date_registration,0)+1 END exposure_days
 FROM staging.student_registration r
 JOIN staging.courses c USING(code_module,code_presentation)
)
SELECT code_module,code_presentation,registration_state,
       COUNT(*)::BIGINT registered_student_presentations,
       COUNT(*) FILTER(WHERE exposure_days IS NULL)::BIGINT unknown_exposure_count,
       COUNT(*) FILTER(WHERE exposure_days=0)::BIGINT zero_exposure_count,
       COUNT(*) FILTER(WHERE exposure_days>0)::BIGINT positive_exposure_count,
       MIN(exposure_days) min_exposure_days,
       PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY exposure_days)::NUMERIC median_exposure_days,
       PERCENTILE_CONT(0.9) WITHIN GROUP(ORDER BY exposure_days)::NUMERIC p90_exposure_days,
       MAX(exposure_days) max_exposure_days
FROM classified
GROUP BY code_module,code_presentation,registration_state
ORDER BY code_module,code_presentation,registration_state;

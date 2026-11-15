-- Question: How are registration dates distributed relative to course start?
-- Expectation: Separate missing, before, on, and after-start registrations.
-- Grain: One row per timing category.
-- Source: staging.student_registration.
-- Safety: READ-ONLY SELECT.
-- Runtime: LOW.
-- Read as: Registration timing is not unregistration timing or activity exposure.
SELECT CASE WHEN date_registration IS NULL THEN 'MISSING' WHEN date_registration<0 THEN 'BEFORE_START'
 WHEN date_registration=0 THEN 'ON_START' ELSE 'AFTER_START' END registration_timing,
 COUNT(*)::BIGINT registrations FROM staging.student_registration GROUP BY 1 ORDER BY 1;
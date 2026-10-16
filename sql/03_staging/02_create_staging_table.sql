-- Purpose: Create typed STAGING tables from the unchanged RAW layer.
-- This script preserves all source rows and does not deduplicate data.
-- Documented source missing tokens are mapped to NULL only in selected STAGING columns.
-- Run once after the RAW layer exists and the staging schema has been created.

BEGIN;

CREATE TABLE staging.courses AS
SELECT code_module, code_presentation, module_presentation_length
FROM raw.courses;

CREATE TABLE staging.assessments AS
SELECT code_module, code_presentation, id_assessment, assessment_type,
       NULLIF(BTRIM(date), '?')::INTEGER AS date,
       weight
FROM raw.assessments;

CREATE TABLE staging.student_info AS
SELECT code_module, code_presentation, id_student, gender, region,
       highest_education, NULLIF(BTRIM(imd_band), '?') AS imd_band,
       age_band, num_of_prev_attempts, studied_credits, disability, final_result
FROM raw.student_info;

CREATE TABLE staging.student_registration AS
SELECT code_module, code_presentation, id_student,
       NULLIF(BTRIM(date_registration), '?')::INTEGER AS date_registration,
       NULLIF(BTRIM(date_unregistration), '?')::INTEGER AS date_unregistration
FROM raw.student_registration;

CREATE TABLE staging.student_assessment AS
SELECT id_assessment, id_student, date_submitted, is_banked,
       NULLIF(BTRIM(score), '?')::NUMERIC AS score
FROM raw.student_assessment;

CREATE TABLE staging.vle AS
SELECT id_site, code_module, code_presentation, activity_type,
       NULLIF(BTRIM(week_from), '?')::INTEGER AS week_from,
       NULLIF(BTRIM(week_to), '?')::INTEGER AS week_to
FROM raw.vle;

CREATE TABLE staging.student_vle AS
SELECT id_student, code_module, code_presentation, id_site, date, sum_click
FROM raw.student_vle;

COMMIT;

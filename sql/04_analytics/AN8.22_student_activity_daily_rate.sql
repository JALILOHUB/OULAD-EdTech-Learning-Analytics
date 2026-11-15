-- Question: What are active-day rates after accounting for available registered exposure?
-- Expectation: Keep active days and exposure separate; unknown/zero exposure rates remain NULL.
-- Grain: One row per registered student-presentation.
-- Source: staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY SELECT; do not impute missing registration dates.
-- Runtime: HIGH; full scan/grouping. Run alone.
-- Read as: In-course active days / available exposure days; not a learning-quality measure.
WITH cohort AS (
 SELECT r.code_module,r.code_presentation,r.id_student,r.date_registration,c.module_presentation_length course_length,
 CASE WHEN r.date_registration IS NULL THEN NULL ELSE GREATEST(r.date_registration,0) END exposure_start
 FROM staging.student_registration r JOIN staging.courses c USING(code_module,code_presentation)
), a AS (
 SELECT v.code_module,v.code_presentation,v.id_student,
 COUNT(DISTINCT v.date) FILTER(WHERE v.date BETWEEN 0 AND c.course_length) in_course_active_days
 FROM staging.student_vle v JOIN cohort c USING(code_module,code_presentation,id_student) GROUP BY 1,2,3
)
SELECT c.code_module,c.code_presentation,c.id_student,c.date_registration,c.course_length,
 CASE WHEN c.exposure_start IS NULL THEN NULL ELSE GREATEST(c.course_length-c.exposure_start+1,0)::BIGINT END exposure_days,
 COALESCE(a.in_course_active_days,0)::BIGINT in_course_active_days,
 CASE WHEN c.exposure_start IS NULL OR c.exposure_start>c.course_length THEN NULL
 ELSE COALESCE(a.in_course_active_days,0)::NUMERIC/NULLIF(c.course_length-c.exposure_start+1,0) END active_day_rate
FROM cohort c LEFT JOIN a USING(code_module,code_presentation,id_student);
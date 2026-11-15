-- Question: How many distinct resources were recorded per student-presentation?
-- Expectation: Count distinct non-NULL id_site values within course windows.
-- Grain: One row per registered student-presentation.
-- Source: staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY SELECT; preserve R0 source rows.
-- Runtime: HIGH; full scan/grouping. Run alone.
-- Read as: Resource breadth is not exposure-normalized and remains a secondary candidate.
WITH a AS (
 SELECT v.code_module,v.code_presentation,v.id_student,COUNT(DISTINCT v.id_site)::BIGINT in_course_resources
 FROM staging.student_vle v JOIN staging.courses c USING(code_module,code_presentation)
 WHERE v.date BETWEEN 0 AND c.module_presentation_length GROUP BY 1,2,3
)
SELECT r.code_module,r.code_presentation,r.id_student,COALESCE(a.in_course_resources,0)::BIGINT in_course_resources
FROM staging.student_registration r LEFT JOIN a USING(code_module,code_presentation,id_student);
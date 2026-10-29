-- Question: How large is each module presentation, and what is its documented duration?
-- Expectation: One row per presentation; student counts reconcile with the student-presentation grain and course metadata.
-- Grain: One row per code_module and code_presentation.
-- Source: staging.student_info and staging.courses.
-- Safety: READ-ONLY
-- Runtime: Low; aggregates 32.6K student rows and joins 22 course rows.
-- Read as: Count student-presentation records, not distinct people across the whole dataset. Review AN1.04 if course joins are not 1:1.

-- 1. Profile presentation population and course length.
WITH presentation_counts AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS student_presentation_rows,
           COUNT(DISTINCT id_student)::BIGINT AS distinct_students_in_presentation
    FROM staging.student_info
    GROUP BY code_module, code_presentation
)
SELECT p.code_module, p.code_presentation,
       c.module_presentation_length,
       p.student_presentation_rows,
       p.distinct_students_in_presentation,
       CASE WHEN p.student_presentation_rows = p.distinct_students_in_presentation THEN 'MATCH' ELSE 'REVIEW' END AS within_presentation_key_status
FROM presentation_counts AS p
LEFT JOIN staging.courses AS c
  ON c.code_module = p.code_module
 AND c.code_presentation = p.code_presentation
ORDER BY p.code_module, p.code_presentation;

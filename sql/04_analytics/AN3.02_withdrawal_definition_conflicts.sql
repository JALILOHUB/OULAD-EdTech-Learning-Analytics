-- Question: Which rows break the equivalence Withdrawn <=> has date_unregistration, and how large is each conflict group by presentation?
-- Expectation: Potential conflict groups are Withdrawn without a date and non-Withdrawn with a date; their prevalence and timing must be established from the returned output.
-- Grain: One row per conflict group, module and presentation.
-- Source: staging.student_info, staging.student_registration, staging.courses.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: NULL-safe comparison is used although final_result is NOT NULL in RAW. Do not label any group erroneous without context. Compare date_unregistration with module_presentation_length for the non-Withdrawn group. A date after the length suggests a post-course action rather than a withdrawal.

SELECT CASE
           WHEN si.final_result IS NOT DISTINCT FROM 'Withdrawn' AND sr.date_unregistration IS NULL THEN 'WITHDRAWN_NO_DATE'
           WHEN si.final_result IS DISTINCT FROM 'Withdrawn' AND sr.date_unregistration IS NOT NULL THEN 'NOT_WITHDRAWN_WITH_DATE'
       END AS conflict_group,
       si.code_module,
       si.code_presentation,
       COUNT(*)::BIGINT AS rows_in_group,
       MIN(sr.date_unregistration) AS min_unregistration_day,
       MAX(sr.date_unregistration) AS max_unregistration_day,
       COUNT(*) FILTER (WHERE sr.date_unregistration > c.module_presentation_length)::BIGINT AS after_course_end_rows
FROM staging.student_info AS si
JOIN staging.student_registration AS sr
  ON sr.code_module = si.code_module AND sr.code_presentation = si.code_presentation AND sr.id_student = si.id_student
JOIN staging.courses AS c
  ON c.code_module = si.code_module AND c.code_presentation = si.code_presentation
WHERE (si.final_result IS NOT DISTINCT FROM 'Withdrawn' AND sr.date_unregistration IS NULL)
   OR (si.final_result IS DISTINCT FROM 'Withdrawn' AND sr.date_unregistration IS NOT NULL)
GROUP BY 1, si.code_module, si.code_presentation
ORDER BY conflict_group, si.code_module, si.code_presentation;

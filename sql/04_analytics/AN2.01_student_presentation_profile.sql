-- Question: Do student_info and student_registration reconcile by module presentation?
-- Expectation: Counts should agree when both tables have the same unique student-presentation population.
-- Grain: One row per code_module and code_presentation.
-- Source: staging.student_info and staging.student_registration.
-- Safety: READ-ONLY
-- Runtime: Low; aggregates two approximately 32.6K-row tables.
-- Read as: Run only after AN1.01 confirms complete unique keys in both student tables.

-- 1. Compare student and registration row counts at the module-presentation grain.
WITH info_counts AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS student_info_rows,
           COUNT(DISTINCT id_student)::BIGINT AS student_info_distinct_students
    FROM staging.student_info
    GROUP BY code_module, code_presentation
),
registration_counts AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS registration_rows,
           COUNT(DISTINCT id_student)::BIGINT AS registration_distinct_students
    FROM staging.student_registration
    GROUP BY code_module, code_presentation
)
SELECT COALESCE(i.code_module, r.code_module) AS code_module,
       COALESCE(i.code_presentation, r.code_presentation) AS code_presentation,
       COALESCE(i.student_info_rows, 0) AS student_info_rows,
       COALESCE(r.registration_rows, 0) AS registration_rows,
       COALESCE(i.student_info_distinct_students, 0) AS student_info_distinct_students,
       COALESCE(r.registration_distinct_students, 0) AS registration_distinct_students,
       COALESCE(i.student_info_rows, 0) - COALESCE(r.registration_rows, 0) AS row_count_difference
FROM info_counts AS i
FULL OUTER JOIN registration_counts AS r
  USING (code_module, code_presentation)
ORDER BY code_module, code_presentation;

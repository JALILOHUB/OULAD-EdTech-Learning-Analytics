-- Question: How much can joining student_assessment to student_info by id_student alone inflate rows?
-- Expectation: The id_student-only join may multiply rows across presentations; the correct path uses assessments to recover module and presentation.
-- Grain: One summary row for the complete student_assessment source population.
-- Source: staging.student_assessment, staging.assessments, and staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low to moderate; joins the assessment table to the student-presentation table.
-- Read as: Compare row counts and unmatched records. A multiplier above 1 indicates row fan-out, not additional source submissions. If AN1.01 finds duplicate student keys, even the correct-path join may fan out.

-- 1. Compare a student-only join with the correct assessment-to-presentation join path.
WITH source_summary AS (
    SELECT COUNT(*)::BIGINT AS source_rows
    FROM staging.student_assessment
),
naive_summary AS (
    SELECT COUNT(*)::BIGINT AS naive_join_rows
    FROM staging.student_assessment AS sa
    LEFT JOIN staging.student_info AS si
      ON si.id_student = sa.id_student
),
correct_summary AS (
    SELECT COUNT(*)::BIGINT AS correct_join_rows,
           COUNT(*) FILTER (WHERE a.id_assessment IS NULL)::BIGINT AS unmatched_assessment_rows,
           COUNT(*) FILTER (
               WHERE a.id_assessment IS NOT NULL AND si.code_module IS NULL
           )::BIGINT AS unmatched_student_presentation_rows,
           COUNT(*) FILTER (WHERE si.code_module IS NOT NULL)::BIGINT AS matched_student_presentation_rows
    FROM staging.student_assessment AS sa
    LEFT JOIN staging.assessments AS a
      ON a.id_assessment = sa.id_assessment
    LEFT JOIN staging.student_info AS si
      ON si.id_student = sa.id_student
     AND si.code_module = a.code_module
     AND si.code_presentation = a.code_presentation
)
SELECT s.source_rows,
       n.naive_join_rows,
       c.correct_join_rows,
       ROUND(n.naive_join_rows::NUMERIC / NULLIF(s.source_rows, 0), 4) AS naive_join_multiplier,
       ROUND(c.correct_join_rows::NUMERIC / NULLIF(s.source_rows, 0), 4) AS correct_join_multiplier,
       c.unmatched_assessment_rows,
       c.unmatched_student_presentation_rows,
       c.matched_student_presentation_rows
FROM source_summary AS s
CROSS JOIN naive_summary AS n
CROSS JOIN correct_summary AS c;

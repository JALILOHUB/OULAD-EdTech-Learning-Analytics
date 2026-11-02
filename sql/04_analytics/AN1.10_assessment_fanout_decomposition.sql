-- Question: Which students and presentations explain the 33,407-row increase in the id_student-only join from AN1.03?
-- Expectation: The excess equals SUM(submissions * (presentations_of_student - 1)) and comes only from students registered in more than one presentation.
-- Grain: Statement 1 = one row per presentation count of the student; statement 2 = one row per module and presentation; statement 3 = one reconciliation row.
-- Source: staging.student_assessment, staging.assessments, staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low to moderate.
-- Read as: The fan-out is explained only if reconciles = TRUE AND submissions_without_student_info = 0 AND unmatched_on_correct_path = 0. A different total from the historical baseline is a finding to investigate, not an error. Never join student_assessment to student_info on id_student alone.

-- 1. Submissions and excess join rows by how many presentations the student has.
WITH student_presentations AS (
    SELECT id_student, COUNT(*)::BIGINT AS presentation_count
    FROM staging.student_info
    GROUP BY id_student
),
student_submissions AS (
    SELECT id_student, COUNT(*)::BIGINT AS submission_rows
    FROM staging.student_assessment
    GROUP BY id_student
)
SELECT sp.presentation_count,
       COUNT(*)::BIGINT AS submitting_students,
       SUM(ss.submission_rows)::BIGINT AS submission_rows,
       SUM(ss.submission_rows * sp.presentation_count)::BIGINT AS naive_join_rows,
       SUM(ss.submission_rows * (sp.presentation_count - 1))::BIGINT AS excess_join_rows
FROM student_submissions AS ss
JOIN student_presentations AS sp USING (id_student)
GROUP BY sp.presentation_count
ORDER BY sp.presentation_count;

-- 2. Where the submissions of repeat students sit, by presentation.
WITH student_presentations AS (
    SELECT id_student, COUNT(*)::BIGINT AS presentation_count
    FROM staging.student_info
    GROUP BY id_student
)
SELECT a.code_module,
       a.code_presentation,
       COUNT(*)::BIGINT AS submission_rows,
       COUNT(*) FILTER (WHERE sp.presentation_count > 1)::BIGINT AS submissions_by_repeat_students,
       ROUND(100.0 * COUNT(*) FILTER (WHERE sp.presentation_count > 1) / COUNT(*), 2) AS pct_by_repeat_students
FROM staging.student_assessment AS sa
JOIN staging.assessments AS a ON a.id_assessment = sa.id_assessment
LEFT JOIN student_presentations AS sp ON sp.id_student = sa.id_student
GROUP BY a.code_module, a.code_presentation
ORDER BY a.code_module, a.code_presentation;

-- 3. Reconcile the excess with the AN1.03 figure (historical baseline 33,407) and report match status.
WITH student_presentations AS (
    SELECT id_student, COUNT(*)::BIGINT AS presentation_count
    FROM staging.student_info
    GROUP BY id_student
),
submissions_per_student AS (
    SELECT id_student, COUNT(*)::BIGINT AS submission_rows
    FROM staging.student_assessment
    GROUP BY id_student
),
explained AS (
    SELECT SUM(x.submission_rows * (sp.presentation_count - 1))::BIGINT AS explained_excess,
           SUM(x.submission_rows)::BIGINT AS submissions_with_student_info
    FROM submissions_per_student AS x
    JOIN student_presentations AS sp USING (id_student)
),
naive AS (
    SELECT COUNT(*)::BIGINT AS naive_rows
    FROM staging.student_assessment AS sa
    LEFT JOIN staging.student_info AS si ON si.id_student = sa.id_student
),
src AS (
    SELECT COUNT(*)::BIGINT AS source_rows FROM staging.student_assessment
),
correct_path AS (
    SELECT COUNT(*)::BIGINT AS correct_path_rows,
           COUNT(*) FILTER (WHERE a.id_assessment IS NULL OR si.id_student IS NULL)::BIGINT AS unmatched_on_correct_path
    FROM staging.student_assessment AS sa
    LEFT JOIN staging.assessments AS a ON a.id_assessment = sa.id_assessment
    LEFT JOIN staging.student_info AS si
      ON si.code_module = a.code_module
     AND si.code_presentation = a.code_presentation
     AND si.id_student = sa.id_student
)
SELECT src.source_rows,
       naive.naive_rows,
       naive.naive_rows - src.source_rows AS observed_excess,
       explained.explained_excess,
       (naive.naive_rows - src.source_rows) = explained.explained_excess AS reconciles,
       src.source_rows - explained.submissions_with_student_info AS submissions_without_student_info,
       correct_path.correct_path_rows,
       correct_path.unmatched_on_correct_path,
       (naive.naive_rows - src.source_rows) = 33407 AS equals_historical_baseline
FROM src
CROSS JOIN naive
CROSS JOIN explained
CROSS JOIN correct_path;

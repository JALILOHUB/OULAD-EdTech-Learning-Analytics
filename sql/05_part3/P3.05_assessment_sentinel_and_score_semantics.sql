-- [P3.05] Assessment submission sentinel, score, and opportunity semantics
-- Question: What do date_submitted=-1 records look like when linked to banked state, score, due date, assessment type, presentation, and retrospective outcome?
-- Expectation: All -1 rows and their linked context are inspectable; score states, candidate keys, and missing-due-date submission links are separately reconciled.
-- Grain: Result set 1 = one row per -1 submission record; result set 2 = score/date state by assessment type and banked token; result set 3 = duplicate assessment-student key groups; result set 4 = missing-due-date assessments and linked submissions.
-- Source: source_ref.student_assessment, assessments, student_info.
-- Safety: READ-ONLY SELECT. Do not recode -1, impute scores, or equate NULL, zero, and no submission.
-- Runtime: MEDIUM; scans assessment and student-profile relations only.
-- Read as: The relative-day definition alone does not establish whether -1 is a valid pre-course day or a sentinel. Preserve it as unresolved until linked evidence and source documentation support a decision.

-- 1. All date_submitted=-1 records with linked assessment and learner context.
SELECT sa.id_assessment, sa.id_student, sa.date_submitted, sa.is_banked, sa.score,
       a.code_module, a.code_presentation, a.assessment_type,
       a.date AS assessment_due_relative_day, a.weight, i.final_result
FROM source_ref.student_assessment sa
LEFT JOIN source_ref.assessments a USING (id_assessment)
LEFT JOIN source_ref.student_info i
  ON i.code_module = a.code_module
 AND i.code_presentation = a.code_presentation
 AND i.id_student = sa.id_student
WHERE BTRIM(sa.date_submitted) = '-1'
ORDER BY a.code_module, a.code_presentation, a.assessment_type, sa.id_assessment, sa.id_student;

-- 2. Distinguish score and date states by assessment type and banked token.
SELECT a.assessment_type, sa.is_banked,
       CASE
         WHEN sa.score IS NULL OR BTRIM(sa.score) IN ('', '?') THEN 'NULL_OR_MISSING_SCORE'
         WHEN BTRIM(sa.score) ~ '^-?[0-9]+(\.[0-9]+)?$' AND BTRIM(sa.score)::NUMERIC = 0 THEN 'OBSERVED_ZERO_SCORE'
         WHEN BTRIM(sa.score) ~ '^-?[0-9]+(\.[0-9]+)?$' THEN 'NONZERO_NUMERIC_SCORE'
         ELSE 'UNPARSEABLE_SCORE'
       END AS score_state,
       CASE
         WHEN sa.date_submitted IS NULL OR BTRIM(sa.date_submitted) IN ('', '?') THEN 'MISSING_SUBMISSION_DAY'
         WHEN BTRIM(sa.date_submitted) = '-1' THEN 'DAY_MINUS_ONE_UNRESOLVED'
         WHEN BTRIM(sa.date_submitted) ~ '^-?[0-9]+$' AND BTRIM(sa.date_submitted)::INTEGER < -1 THEN 'OTHER_NEGATIVE_DAY'
         WHEN BTRIM(sa.date_submitted) ~ '^-?[0-9]+$' AND BTRIM(sa.date_submitted)::INTEGER = 0 THEN 'DAY_ZERO'
         WHEN BTRIM(sa.date_submitted) ~ '^-?[0-9]+$' THEN 'POSITIVE_RELATIVE_DAY'
         ELSE 'UNPARSEABLE_SUBMISSION_DAY'
       END AS submission_day_state,
       COUNT(*)::BIGINT AS submission_records
FROM source_ref.student_assessment sa
LEFT JOIN source_ref.assessments a USING (id_assessment)
GROUP BY a.assessment_type, sa.is_banked, score_state, submission_day_state
ORDER BY a.assessment_type, sa.is_banked, score_state, submission_day_state;

-- 3. Check whether the expected assessment-student candidate key is unique.
SELECT id_assessment, id_student, COUNT(*)::BIGINT AS rows_per_key
FROM source_ref.student_assessment
GROUP BY id_assessment, id_student
HAVING COUNT(*) > 1
ORDER BY rows_per_key DESC, id_assessment, id_student;

-- 4. Reconcile missing assessment due dates to their linked submissions.
WITH missing_due_dates AS (
    SELECT id_assessment, code_module, code_presentation, assessment_type, date, weight
    FROM source_ref.assessments
    WHERE date IS NULL OR BTRIM(date) IN ('', '?')
),
submission_counts AS (
    SELECT id_assessment, COUNT(*)::BIGINT AS submission_records,
           COUNT(DISTINCT id_student)::BIGINT AS distinct_students,
           COUNT(*) FILTER (WHERE BTRIM(date_submitted) = '-1')::BIGINT
               AS minus_one_submission_records
    FROM source_ref.student_assessment
    GROUP BY id_assessment
)
SELECT m.*,
       COALESCE(s.submission_records, 0)::BIGINT AS submission_records,
       COALESCE(s.distinct_students, 0)::BIGINT AS distinct_students,
       COALESCE(s.minus_one_submission_records, 0)::BIGINT AS minus_one_submission_records
FROM missing_due_dates m
LEFT JOIN submission_counts s USING (id_assessment)
ORDER BY m.code_module, m.code_presentation, m.id_assessment;

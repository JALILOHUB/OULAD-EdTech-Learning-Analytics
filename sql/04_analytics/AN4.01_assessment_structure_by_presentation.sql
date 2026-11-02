-- Question: What assessments does each presentation contain, and how do weights add up?
-- Expectation: Each presentation has a few TMA/CMA items and usually one Exam; weights of non-exam items typically total 100 and the exam adds 100 where present.
-- Grain: One row per module, presentation and assessment type.
-- Source: staging.assessments.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: Weight totals that differ from 100 are a finding, not an error, until the dataset documentation is checked. Do not average scores across types before reading this table.
SELECT code_module,
       code_presentation,
       assessment_type,
       COUNT(*)::BIGINT AS assessment_count,
       SUM(weight) AS total_weight,
       COUNT(*) FILTER (WHERE date IS NULL)::BIGINT AS missing_date_count,
       MIN(date) AS first_due_day,
       MAX(date) AS last_due_day
FROM staging.assessments
GROUP BY code_module, code_presentation, assessment_type
ORDER BY code_module, code_presentation, assessment_type;

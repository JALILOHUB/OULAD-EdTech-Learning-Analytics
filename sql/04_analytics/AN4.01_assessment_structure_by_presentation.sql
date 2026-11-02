-- Question: What assessments does each presentation contain, and how do weights add up?
-- Expectation: No assessment-type pattern or weight-total rule is assumed; inspect the observed structure by presentation.
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

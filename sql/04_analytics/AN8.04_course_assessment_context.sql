-- Question: Are course windows and assessment due-date/weight summaries complete?
-- Expectation: Return course dimensions and assessment context without inferring score availability.
-- Grain: Result set 1 one row per presentation; result set 2 one row per presentation.
-- Source: staging.courses, staging.assessments.
-- Safety: READ-ONLY SELECT.
-- Runtime: LOW.
-- Read as: Due dates and weights do not prove score or feedback publication time.
SELECT code_module,code_presentation,module_presentation_length FROM staging.courses ORDER BY 1,2;
SELECT code_module,code_presentation,COUNT(*)::BIGINT assessment_count,
 COUNT(*) FILTER(WHERE date IS NULL)::BIGINT missing_due_dates,SUM(weight)::NUMERIC total_weight
FROM staging.assessments GROUP BY 1,2 ORDER BY 1,2;
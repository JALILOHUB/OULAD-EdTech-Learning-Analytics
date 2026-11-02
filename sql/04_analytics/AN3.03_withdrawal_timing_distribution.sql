-- Question: When during a presentation do students unregister?
-- Expectation: Historical timing patterns are hypotheses only; no bucket prevalence or module difference is assumed.
-- Grain: One row per module, presentation and timing bucket.
-- Source: staging.student_registration with staging.courses.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: Buckets are relative to presentation start (day 0). Negative days mean before start. Percentages use all unregistrations of that presentation as the denominator, not all registrations.
SELECT sr.code_module,
       sr.code_presentation,
       CASE
           WHEN sr.date_unregistration < 0 THEN '1_before_start'
           WHEN sr.date_unregistration > c.module_presentation_length THEN '6_after_course_end'
           WHEN sr.date_unregistration < 28 THEN '2_weeks_1_4'
           WHEN sr.date_unregistration < 84 THEN '3_weeks_5_12'
           WHEN sr.date_unregistration < 168 THEN '4_weeks_13_24'
           ELSE '5_weeks_25_to_end'
       END AS timing_bucket,
       COUNT(*)::BIGINT AS unregistration_rows,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY sr.code_module, sr.code_presentation), 2) AS pct_of_presentation_unregistrations
FROM staging.student_registration AS sr
JOIN staging.courses AS c USING (code_module, code_presentation)
WHERE sr.date_unregistration IS NOT NULL
GROUP BY sr.code_module, sr.code_presentation, 3
ORDER BY sr.code_module, sr.code_presentation, timing_bucket;

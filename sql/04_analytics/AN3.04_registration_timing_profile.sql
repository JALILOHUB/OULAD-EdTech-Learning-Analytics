-- Question: How early do students register, and does registration timing relate to withdrawal?
-- Expectation: Registration is mostly before day 0; the 45 NULL registration dates form their own group; late registrants may withdraw more.
-- Grain: One row per registration-timing bucket.
-- Source: staging.student_registration and staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: Report the NULL bucket separately; never drop it silently. Association only: earlier registration may reflect motivation, not cause outcomes.
SELECT CASE
           WHEN sr.date_registration IS NULL THEN '0_missing'
           WHEN sr.date_registration < -180 THEN '1_more_than_180_days_before'
           WHEN sr.date_registration < -90 THEN '2_91_to_180_days_before'
           WHEN sr.date_registration < -30 THEN '3_31_to_90_days_before'
           WHEN sr.date_registration < 0 THEN '4_1_to_30_days_before'
           ELSE '5_on_or_after_start'
       END AS registration_bucket,
       COUNT(*)::BIGINT AS student_presentation_rows,
       COUNT(*) FILTER (WHERE si.final_result = 'Withdrawn')::BIGINT AS withdrawn_rows,
       ROUND(100.0 * COUNT(*) FILTER (WHERE si.final_result = 'Withdrawn') / COUNT(*), 2) AS pct_withdrawn
FROM staging.student_registration AS sr
JOIN staging.student_info AS si
  ON si.code_module = sr.code_module AND si.code_presentation = sr.code_presentation AND si.id_student = sr.id_student
GROUP BY 1
ORDER BY 1;

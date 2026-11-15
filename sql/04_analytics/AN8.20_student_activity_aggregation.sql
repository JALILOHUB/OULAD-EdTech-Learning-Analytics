-- Question: What recorded activity metrics can be aggregated at student-presentation grain?
-- Expectation: One row per registration with source rows, clicks, active days, and active resources.
-- Grain: One row per registered student-presentation.
-- Source: staging.student_registration, staging.student_vle.
-- Safety: READ-ONLY SELECT; preserve R0 source rows and do not deduplicate.
-- Runtime: HIGH; full scan/grouping of 10.6M rows. Run alone.
-- Read as: Clicks and rows are platform activity, not learning quality.
WITH a AS (SELECT code_module,code_presentation,id_student,COUNT(*)::BIGINT activity_rows,
 SUM(sum_click)::NUMERIC recorded_clicks,COUNT(DISTINCT date)::BIGINT active_days,
 COUNT(DISTINCT id_site)::BIGINT active_resources FROM staging.student_vle GROUP BY 1,2,3)
SELECT r.code_module,r.code_presentation,r.id_student,COALESCE(a.activity_rows,0)::BIGINT activity_rows,
 COALESCE(a.recorded_clicks,0)::NUMERIC recorded_clicks,COALESCE(a.active_days,0)::BIGINT active_days,
 COALESCE(a.active_resources,0)::BIGINT active_resources,(a.id_student IS NOT NULL) has_recorded_activity
FROM staging.student_registration r LEFT JOIN a USING(code_module,code_presentation,id_student) ORDER BY 1,2,3;
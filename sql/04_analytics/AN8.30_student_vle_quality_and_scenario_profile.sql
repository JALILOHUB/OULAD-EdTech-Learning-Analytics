-- [AN8.30] Student VLE quality and scenario profile
-- Question: How do repeated-key patterns, click values, resource matches, registration matches, and course-relative dates affect the analytical interpretation of student_vle?
-- Expectation: Preserve R0; report R1/R2 as sensitivity scenarios only. No source correction is implied.
-- Grain: Result set 1 = overall source and scenario profile; result set 2 = one row per diagnostic state.
-- Source: staging.student_vle, staging.student_registration, staging.courses, staging.vle.
-- Safety: READ-ONLY SELECT. No deduplication, updates, or persistent objects.
-- Runtime: HIGH; multiple grouped scans of the 10.6M-row source. Run alone.
-- Read as: R1 removes exact six-column duplicates; R2 uses MAX(sum_click) per five-column key only as a sensitivity assumption. Neither is asserted as truth.

-- 1. Compare R0, R1, and R2 row/click totals without changing source rows.
WITH exact_rows AS (
    SELECT DISTINCT code_module, code_presentation, id_student, id_site, date, sum_click
    FROM staging.student_vle
),
key_rows AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           MAX(sum_click) AS sum_click
    FROM staging.student_vle
    GROUP BY 1,2,3,4,5
),
scenario_totals AS (
    SELECT 'R0'::TEXT scenario, COUNT(*)::BIGINT activity_rows,
           SUM(sum_click)::NUMERIC recorded_clicks FROM staging.student_vle
    UNION ALL
    SELECT 'R1', COUNT(*)::BIGINT, SUM(sum_click)::NUMERIC FROM exact_rows
    UNION ALL
    SELECT 'R2', COUNT(*)::BIGINT, SUM(sum_click)::NUMERIC FROM key_rows
),
key_profile AS (
    SELECT COUNT(*) FILTER (WHERE n > 1)::BIGINT repeated_five_key_groups,
           COALESCE(SUM(n - 1),0)::BIGINT excess_rows_over_five_key,
           COUNT(*) FILTER (WHERE click_values > 1)::BIGINT multi_click_value_groups,
           MAX(n)::BIGINT maximum_five_key_group_size
    FROM (
        SELECT COUNT(*) n, COUNT(DISTINCT sum_click) click_values
        FROM staging.student_vle GROUP BY 1,2,3,4,5
    ) g
),
source_profile AS (
    SELECT COUNT(*)::BIGINT r0_rows,
           COUNT(*) FILTER (WHERE sum_click <= 0)::BIGINT nonpositive_click_rows,
           COUNT(*) FILTER (WHERE sum_click IS NULL)::BIGINT null_click_rows,
           MIN(sum_click) min_clicks, MAX(sum_click) max_clicks,
           COUNT(*) FILTER (WHERE date < 0)::BIGINT pre_course_rows
    FROM staging.student_vle
)
SELECT t.scenario, t.activity_rows, t.recorded_clicks,
       s.r0_rows, k.repeated_five_key_groups, k.excess_rows_over_five_key,
       k.multi_click_value_groups, k.maximum_five_key_group_size,
       s.nonpositive_click_rows, s.null_click_rows, s.min_clicks, s.max_clicks,
       s.pre_course_rows
FROM scenario_totals t CROSS JOIN key_profile k CROSS JOIN source_profile s
ORDER BY t.scenario;

-- 2. Classify reference-integrity and temporal states at source-row grain.
SELECT
    CASE WHEN r.id_student IS NULL THEN 'NO_REGISTRATION_MATCH'
         ELSE 'REGISTRATION_MATCH' END registration_state,
    CASE WHEN c.code_module IS NULL THEN 'NO_COURSE_MATCH'
         ELSE 'COURSE_MATCH' END course_state,
    CASE WHEN v.id_site IS NULL THEN 'NO_VLE_RESOURCE_MATCH'
         ELSE 'VLE_RESOURCE_MATCH' END resource_state,
    CASE WHEN c.module_presentation_length IS NULL THEN 'UNKNOWN_COURSE_WINDOW'
         WHEN sv.date < 0 THEN 'PRE_COURSE'
         WHEN sv.date <= c.module_presentation_length THEN 'IN_COURSE'
         ELSE 'POST_COURSE' END temporal_state,
    COUNT(*)::BIGINT source_rows,
    SUM(sv.sum_click)::NUMERIC recorded_clicks
FROM staging.student_vle sv
LEFT JOIN staging.student_registration r
  ON r.code_module=sv.code_module AND r.code_presentation=sv.code_presentation
 AND r.id_student=sv.id_student
LEFT JOIN staging.courses c
  ON c.code_module=sv.code_module AND c.code_presentation=sv.code_presentation
LEFT JOIN staging.vle v
  ON v.id_site=sv.id_site AND v.code_module=sv.code_module
 AND v.code_presentation=sv.code_presentation
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4;

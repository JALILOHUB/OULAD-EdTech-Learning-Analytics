-- Question: Do recorded activity measures and activity coverage differ across final-result groups, and are those patterns sensitive to R0, R1, and R2?
-- Expectation: All scenarios use the same registered student-presentation population. Outcome groups are assigned only through a unique student_info composite key; missing, duplicate, or conflicting profile matches remain explicit.
-- Grain: One row per scenario, module-presentation, and final-result/profile-status group; plus one profile-match diagnostic row per module-presentation.
-- Source: staging.student_vle, staging.student_registration, staging.student_info.
-- Safety: READ-ONLY. Final results are retrospective grouping labels, not predictors. No source data or persistent database objects are modified.
-- Runtime: HIGH. Three scenario aggregations scan the 10.6M-row activity table. Run alone with statement_timeout_ms=600000.
-- Read as: Compare groups within each module-presentation. Mean and median clicks include registered student-presentations with no matching activity as zero. Small groups are flagged; descriptive differences do not imply causation or predictive validity.

-- 1. Build a one-row-per-key profile map without allowing duplicate student_info rows to multiply activity metrics.
WITH registered_population AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS registration_rows
    FROM staging.student_registration
    GROUP BY code_module, code_presentation, id_student
),
profile_by_key AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS profile_rows,
           COUNT(DISTINCT final_result)::BIGINT AS distinct_final_results,
           MIN(final_result) AS final_result
    FROM staging.student_info
    GROUP BY code_module, code_presentation, id_student
),
scenario_rows AS (
    SELECT 'R0'::TEXT AS scenario,
           code_module, code_presentation, id_student, id_site, date, sum_click
    FROM staging.student_vle

    UNION ALL

    SELECT 'R1'::TEXT,
           code_module, code_presentation, id_student, id_site, date, sum_click
    FROM (
        SELECT DISTINCT code_module, code_presentation, id_student, id_site, date, sum_click
        FROM staging.student_vle
    ) AS exact_rows

    UNION ALL

    SELECT 'R2'::TEXT,
           code_module, code_presentation, id_student, id_site, date, MAX(sum_click) AS sum_click
    FROM staging.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
),
student_activity AS (
    SELECT scenario, code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS scenario_activity_rows,
           SUM(sum_click)::NUMERIC AS recorded_sum_click,
           COUNT(DISTINCT date)::BIGINT AS active_days,
           COUNT(DISTINCT id_site)::BIGINT AS active_sites
    FROM scenario_rows
    GROUP BY scenario, code_module, code_presentation, id_student
),
scenario_population AS (
    SELECT s.scenario, r.code_module, r.code_presentation, r.id_student,
           r.registration_rows,
           CASE
               WHEN p.profile_rows IS NULL THEN 'NO_STUDENT_INFO_MATCH'
               WHEN p.distinct_final_results > 1 THEN 'CONFLICTING_FINAL_RESULT'
               WHEN p.profile_rows > 1 THEN 'DUPLICATE_STUDENT_INFO_KEY'
               WHEN p.final_result IS NULL THEN 'MISSING_FINAL_RESULT'
               ELSE p.final_result
           END AS outcome_group,
           (p.profile_rows = 1 AND p.distinct_final_results <= 1 AND p.final_result IS NOT NULL)
               AS valid_outcome_match,
           (a.id_student IS NOT NULL) AS has_activity,
           COALESCE(a.scenario_activity_rows, 0)::BIGINT AS scenario_activity_rows,
           COALESCE(a.recorded_sum_click, 0)::NUMERIC AS recorded_sum_click,
           COALESCE(a.active_days, 0)::BIGINT AS active_days,
           COALESCE(a.active_sites, 0)::BIGINT AS active_sites
    FROM registered_population AS r
    CROSS JOIN (VALUES ('R0'::TEXT), ('R1'::TEXT), ('R2'::TEXT)) AS s(scenario)
    LEFT JOIN profile_by_key AS p
      ON p.code_module = r.code_module
     AND p.code_presentation = r.code_presentation
     AND p.id_student = r.id_student
    LEFT JOIN student_activity AS a
      ON a.scenario = s.scenario
     AND a.code_module = r.code_module
     AND a.code_presentation = r.code_presentation
     AND a.id_student = r.id_student
),
outcome_metrics AS (
    SELECT scenario, code_module, code_presentation, outcome_group,
           COUNT(*)::BIGINT AS registered_student_presentations,
           COUNT(DISTINCT id_student)::BIGINT AS distinct_students,
           COUNT(*) FILTER (WHERE has_activity)::BIGINT AS activity_bearing_student_presentations,
           COUNT(*) FILTER (WHERE NOT has_activity)::BIGINT AS student_presentations_without_activity,
           ROUND(100.0 * COUNT(*) FILTER (WHERE has_activity)
                 / NULLIF(COUNT(*), 0), 2) AS pct_with_recorded_activity,
           SUM(scenario_activity_rows)::BIGINT AS scenario_activity_rows,
           SUM(recorded_sum_click)::NUMERIC AS recorded_sum_click,
           ROUND(AVG(recorded_sum_click), 2) AS mean_clicks_per_registered_student_presentation,
           percentile_cont(0.50) WITHIN GROUP (ORDER BY recorded_sum_click)::NUMERIC
               AS median_clicks_per_registered_student_presentation,
           SUM(active_days)::BIGINT AS student_active_day_pairs,
           ROUND(AVG(active_days), 2) AS mean_active_days_per_registered_student_presentation,
           SUM(active_sites)::BIGINT AS student_active_site_pairs,
           ROUND(AVG(active_sites), 2) AS mean_active_sites_per_registered_student_presentation,
           COUNT(*) FILTER (WHERE valid_outcome_match)::BIGINT AS valid_outcome_student_presentations
    FROM scenario_population
    GROUP BY scenario, code_module, code_presentation, outcome_group
)
SELECT scenario, code_module, code_presentation, outcome_group,
       registered_student_presentations, distinct_students,
       activity_bearing_student_presentations, student_presentations_without_activity,
       pct_with_recorded_activity, scenario_activity_rows, recorded_sum_click,
       mean_clicks_per_registered_student_presentation,
       median_clicks_per_registered_student_presentation,
       student_active_day_pairs, mean_active_days_per_registered_student_presentation,
       student_active_site_pairs, mean_active_sites_per_registered_student_presentation,
       valid_outcome_student_presentations,
       (registered_student_presentations < 100) AS small_group_flag
FROM outcome_metrics
ORDER BY scenario, code_module, code_presentation, outcome_group;

-- 2. Diagnose registration-to-profile matching independently of the R0/R1/R2 scenario.
WITH registered_population AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS registration_rows
    FROM staging.student_registration
    GROUP BY code_module, code_presentation, id_student
),
profile_by_key AS (
    SELECT code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS profile_rows,
           COUNT(DISTINCT final_result)::BIGINT AS distinct_final_results,
           MIN(final_result) AS final_result
    FROM staging.student_info
    GROUP BY code_module, code_presentation, id_student
)
SELECT r.code_module, r.code_presentation,
       COUNT(*)::BIGINT AS registered_student_presentation_keys,
       COUNT(*) FILTER (WHERE r.registration_rows > 1)::BIGINT AS duplicate_registration_keys,
       COUNT(*) FILTER (WHERE p.profile_rows = 1)::BIGINT AS unique_profile_matches,
       COUNT(*) FILTER (WHERE p.profile_rows IS NULL)::BIGINT AS missing_profile_matches,
       COUNT(*) FILTER (WHERE p.profile_rows > 1)::BIGINT AS duplicate_profile_matches,
       COUNT(*) FILTER (WHERE p.distinct_final_results > 1)::BIGINT AS conflicting_final_result_keys,
       COUNT(*) FILTER (WHERE p.profile_rows = 1 AND p.final_result IS NULL)::BIGINT AS missing_final_result_keys,
       COUNT(*) FILTER (WHERE p.profile_rows = 1 AND p.distinct_final_results = 1)::BIGINT
           AS single_final_result_keys
FROM registered_population AS r
LEFT JOIN profile_by_key AS p
  ON p.code_module = r.code_module
 AND p.code_presentation = r.code_presentation
 AND p.id_student = r.id_student
GROUP BY r.code_module, r.code_presentation
ORDER BY r.code_module, r.code_presentation;

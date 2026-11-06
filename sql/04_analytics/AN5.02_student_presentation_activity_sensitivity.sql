-- Question: How sensitive are recorded click volume, active-day presence, resource breadth, and activity coverage to R0, R1, and R2 at student-presentation grain?
-- Expectation: Scenario values may differ. The registered student-presentation denominator must remain identical across R0, R1, and R2 within each presentation.
-- Grain: One row per scenario and module-presentation, plus one overall row per scenario.
-- Source: staging.student_vle, staging.student_registration.
-- Safety: READ-ONLY. Scenario transformations exist only in query CTEs; RAW and STAGING remain unchanged.
-- Runtime: HIGH. R0, R1, and R2 each aggregate the 10.6M-row activity table. Run alone with statement_timeout_ms=600000.
-- Read as: Click volume is recorded platform activity, not learning quality. Active-day pairs and student-site pairs sum student-level distinct counts and are not unique presentation-wide days/sites. Unmatched activity keys are excluded from the registered cohort comparison and are counted in AN5.01.

-- 1. Build the three virtual scenarios and aggregate each to student-presentation grain.
WITH registered_population AS (
    SELECT code_module, code_presentation, id_student
    FROM staging.student_registration
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
scenario_student_activity AS (
    SELECT scenario, code_module, code_presentation, id_student,
           COUNT(*)::BIGINT AS scenario_activity_rows,
           SUM(sum_click)::NUMERIC AS recorded_sum_click,
           COUNT(DISTINCT date)::BIGINT AS active_days,
           COUNT(DISTINCT id_site)::BIGINT AS active_sites
    FROM scenario_rows
    GROUP BY scenario, code_module, code_presentation, id_student
),
population_with_activity AS (
    SELECT scenarios.scenario,
           r.code_module, r.code_presentation, r.id_student,
           a.id_student AS activity_match,
           COALESCE(a.scenario_activity_rows, 0)::BIGINT AS scenario_activity_rows,
           COALESCE(a.recorded_sum_click, 0)::NUMERIC AS recorded_sum_click,
           COALESCE(a.active_days, 0)::BIGINT AS active_days,
           COALESCE(a.active_sites, 0)::BIGINT AS active_sites
    FROM registered_population AS r
    CROSS JOIN (SELECT DISTINCT scenario FROM scenario_student_activity) AS scenarios
    LEFT JOIN scenario_student_activity AS a
      ON a.scenario = scenarios.scenario
     AND a.code_module = r.code_module
     AND a.code_presentation = r.code_presentation
     AND a.id_student = r.id_student
),
sensitivity_metrics AS (
    SELECT scenario, code_module, code_presentation,
           CASE WHEN GROUPING(code_module) = 1 THEN 'ALL_PRESENTATIONS'
                ELSE 'MODULE_PRESENTATION' END AS output_scope,
           COUNT(*)::BIGINT AS registered_student_presentations,
           COUNT(DISTINCT id_student)::BIGINT AS distinct_registered_students,
           COUNT(*) FILTER (WHERE activity_match IS NOT NULL)::BIGINT AS activity_bearing_student_presentations,
           COUNT(DISTINCT id_student) FILTER (WHERE activity_match IS NOT NULL)::BIGINT AS distinct_students_with_activity,
           COUNT(*) FILTER (WHERE activity_match IS NULL)::BIGINT AS student_presentations_without_activity,
           SUM(scenario_activity_rows)::BIGINT AS matched_registered_activity_rows,
           SUM(recorded_sum_click)::NUMERIC AS matched_registered_sum_click,
           SUM(active_days)::BIGINT AS student_active_day_pairs,
           SUM(active_sites)::BIGINT AS student_active_site_pairs
    FROM population_with_activity
    GROUP BY GROUPING SETS (
        (scenario, code_module, code_presentation),
        (scenario)
    )
)

SELECT scenario, output_scope, code_module, code_presentation,
       registered_student_presentations, distinct_registered_students,
       activity_bearing_student_presentations, distinct_students_with_activity,
       student_presentations_without_activity,
       ROUND(100.0 * activity_bearing_student_presentations
             / NULLIF(registered_student_presentations, 0), 2) AS pct_registered_student_presentations_with_activity,
       matched_registered_activity_rows, matched_registered_sum_click,
       student_active_day_pairs, student_active_site_pairs
FROM sensitivity_metrics
ORDER BY scenario, output_scope, code_module, code_presentation;

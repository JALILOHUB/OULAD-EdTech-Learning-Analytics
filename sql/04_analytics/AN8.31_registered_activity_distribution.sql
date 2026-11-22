-- [AN8.31] Registered activity distributions
-- Question: What are the zero-inclusive distributions of recorded activity rows, clicks, active days, and resource breadth for registered student-presentations?
-- Expectation: Every registered key remains in the denominator, including keys with no in-course activity.
-- Grain: One row per module-presentation and metric.
-- Source: staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY SELECT; R0 source rows are preserved.
-- Runtime: HIGH; scans student_vle and aggregates to the registered student-presentation grain. Run alone.
-- Read as: Row/click counts are source-record measures and remain repetition-sensitive. Active days and resource breadth are distinct-day/site counts, not learning quality.

WITH registered AS (
    SELECT r.code_module,r.code_presentation,r.id_student,c.module_presentation_length
    FROM staging.student_registration r
    JOIN staging.courses c USING(code_module,code_presentation)
),
activity AS (
    SELECT r.code_module,r.code_presentation,r.id_student,
           COUNT(v.id_site) FILTER(WHERE v.date BETWEEN 0 AND r.module_presentation_length)::BIGINT in_course_rows,
           COALESCE(SUM(v.sum_click) FILTER(WHERE v.date BETWEEN 0 AND r.module_presentation_length),0)::NUMERIC in_course_clicks,
           COUNT(DISTINCT v.date) FILTER(WHERE v.date BETWEEN 0 AND r.module_presentation_length)::BIGINT active_days,
           COUNT(DISTINCT v.id_site) FILTER(WHERE v.date BETWEEN 0 AND r.module_presentation_length)::BIGINT resource_breadth
    FROM registered r
    LEFT JOIN staging.student_vle v
      ON v.code_module=r.code_module AND v.code_presentation=r.code_presentation
     AND v.id_student=r.id_student
    GROUP BY r.code_module,r.code_presentation,r.id_student
),
metrics AS (
    SELECT r.code_module,r.code_presentation,r.id_student,
           COALESCE(a.in_course_rows,0)::BIGINT in_course_rows,
           COALESCE(a.in_course_clicks,0)::NUMERIC in_course_clicks,
           COALESCE(a.active_days,0)::BIGINT active_days,
           COALESCE(a.resource_breadth,0)::BIGINT resource_breadth
    FROM registered r LEFT JOIN activity a USING(code_module,code_presentation,id_student)
),
long_metrics AS (
    SELECT code_module,code_presentation,'ACTIVITY_ROWS'::TEXT metric,in_course_rows::NUMERIC value FROM metrics
    UNION ALL SELECT code_module,code_presentation,'RECORDED_CLICKS',in_course_clicks FROM metrics
    UNION ALL SELECT code_module,code_presentation,'ACTIVE_DAYS',active_days::NUMERIC FROM metrics
    UNION ALL SELECT code_module,code_presentation,'RESOURCE_BREADTH',resource_breadth::NUMERIC FROM metrics
)
SELECT code_module,code_presentation,metric,
       COUNT(*)::BIGINT registered_denominator,
       COUNT(*) FILTER(WHERE value=0)::BIGINT zero_value_count,
       ROUND(100.0*COUNT(*) FILTER(WHERE value=0)/NULLIF(COUNT(*),0),2) pct_zero,
       ROUND(AVG(value),2) mean_value,
       PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY value)::NUMERIC p25,
       PERCENTILE_CONT(0.50) WITHIN GROUP(ORDER BY value)::NUMERIC median,
       PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY value)::NUMERIC p75,
       PERCENTILE_CONT(0.90) WITHIN GROUP(ORDER BY value)::NUMERIC p90,
       MAX(value) max_value
FROM long_metrics
GROUP BY code_module,code_presentation,metric
ORDER BY code_module,code_presentation,metric;

-- [AN8.34] Activity distributions by outcome and presentation
-- Question: How do zero-inclusive recorded activity measures differ across retrospective outcome groups within each module-presentation?
-- Expectation: Retain all outcome categories and every registered student-presentation in each denominator.
-- Grain: One row per module-presentation and final_result.
-- Source: staging.student_info, staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY SELECT. final_result is a retrospective grouping variable, not a predictor or causal outcome model.
-- Runtime: HIGH; scans student_vle and aggregates to student-presentation grain. Run alone.
-- Read as: Differences are descriptive associations. Small group sizes and repeated source rows must be visible; do not infer causality.

WITH cohort AS (
 SELECT r.code_module,r.code_presentation,r.id_student,
        si.final_result,c.module_presentation_length
 FROM staging.student_registration r
 JOIN staging.student_info si USING(code_module,code_presentation,id_student)
 JOIN staging.courses c USING(code_module,code_presentation)
),
activity AS (
 SELECT c.code_module,c.code_presentation,c.id_student,
        COUNT(v.id_site) FILTER(WHERE v.date BETWEEN 0 AND c.module_presentation_length)::BIGINT activity_rows,
        COALESCE(SUM(v.sum_click) FILTER(WHERE v.date BETWEEN 0 AND c.module_presentation_length),0)::NUMERIC clicks,
        COUNT(DISTINCT v.date) FILTER(WHERE v.date BETWEEN 0 AND c.module_presentation_length)::BIGINT active_days,
        COUNT(DISTINCT v.id_site) FILTER(WHERE v.date BETWEEN 0 AND c.module_presentation_length)::BIGINT resource_breadth
 FROM cohort c LEFT JOIN staging.student_vle v
  ON v.code_module=c.code_module AND v.code_presentation=c.code_presentation AND v.id_student=c.id_student
 GROUP BY c.code_module,c.code_presentation,c.id_student
),
joined AS (
 SELECT c.code_module,c.code_presentation,c.final_result,
        COALESCE(a.activity_rows,0)::BIGINT activity_rows,
        COALESCE(a.clicks,0)::NUMERIC clicks,
        COALESCE(a.active_days,0)::BIGINT active_days,
        COALESCE(a.resource_breadth,0)::BIGINT resource_breadth
 FROM cohort c JOIN activity a USING(code_module,code_presentation,id_student)
),
long_metrics AS (
 SELECT code_module,code_presentation,final_result,'ACTIVE_DAYS'::TEXT metric,active_days::NUMERIC value FROM joined
 UNION ALL SELECT code_module,code_presentation,final_result,'RESOURCE_BREADTH',resource_breadth::NUMERIC FROM joined
 UNION ALL SELECT code_module,code_presentation,final_result,'ACTIVITY_ROWS',activity_rows::NUMERIC FROM joined
 UNION ALL SELECT code_module,code_presentation,final_result,'RECORDED_CLICKS',clicks FROM joined
)
SELECT code_module,code_presentation,final_result,metric,
       COUNT(*)::BIGINT student_presentation_denominator,
       COUNT(*) FILTER(WHERE value=0)::BIGINT zero_count,
       ROUND(100.0*COUNT(*) FILTER(WHERE value=0)/NULLIF(COUNT(*),0),2) pct_zero,
       ROUND(AVG(value),2) mean_value,
       PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY value)::NUMERIC median,
       PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY value)::NUMERIC p75,
       PERCENTILE_CONT(0.9) WITHIN GROUP(ORDER BY value)::NUMERIC p90
FROM long_metrics
GROUP BY code_module,code_presentation,final_result,metric
ORDER BY code_module,code_presentation,final_result,metric;

-- Question: What in-course VLE activity is recorded among all registered student-presentations?
-- Expectation: Denominator includes every registered key; the inclusive window is 0 through module_presentation_length.
-- Grain: One row per presentation and coverage/distribution statistic.
-- Source: staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY. SQL aggregation only; no source or persistent changes.
-- Runtime: HIGH; scans student_vle. Run alone with statement_timeout_ms=600000 after AN6.01 review.
-- Read as: Zero-inclusive distributions retain inactive registrations. Outside-window-only differs from no recorded activity. These are platform-record measures, not learning measures.

-- 1. Aggregate in-course activity at registered student-presentation grain.
WITH registered AS (
    SELECT DISTINCT r.code_module, r.code_presentation, r.id_student, c.module_presentation_length
    FROM staging.student_registration AS r
    JOIN staging.courses AS c USING (code_module, code_presentation)
),
activity AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
           COUNT(v.id_site) FILTER (WHERE v.date BETWEEN 0 AND r.module_presentation_length)::BIGINT AS in_course_rows,
           COUNT(DISTINCT v.date) FILTER (WHERE v.date BETWEEN 0 AND r.module_presentation_length)::BIGINT AS active_days,
           COUNT(DISTINCT v.id_site) FILTER (WHERE v.date BETWEEN 0 AND r.module_presentation_length)::BIGINT AS resource_breadth,
           MIN(v.date) FILTER (WHERE v.date BETWEEN 0 AND r.module_presentation_length)::INTEGER AS first_in_course_day,
           COUNT(v.id_site) FILTER (WHERE v.date < 0 OR v.date > r.module_presentation_length)::BIGINT AS outside_window_rows
    FROM registered AS r
    LEFT JOIN staging.student_vle AS v
      ON v.code_module=r.code_module AND v.code_presentation=r.code_presentation AND v.id_student=r.id_student
    GROUP BY r.code_module, r.code_presentation, r.id_student
),
metrics AS (
    SELECT r.code_module, r.code_presentation, r.id_student,
           COALESCE(a.in_course_rows,0)::BIGINT AS in_course_rows,
           COALESCE(a.active_days,0)::BIGINT AS active_days,
           COALESCE(a.resource_breadth,0)::BIGINT AS resource_breadth,
           a.first_in_course_day,
           COALESCE(a.outside_window_rows,0)::BIGINT AS outside_window_rows,
           CASE WHEN COALESCE(a.in_course_rows,0)>0 THEN 'IN_COURSE_ACTIVITY'
                WHEN COALESCE(a.outside_window_rows,0)>0 THEN 'OUTSIDE_WINDOW_ONLY'
                ELSE 'NO_RECORDED_ACTIVITY' END AS activity_state
    FROM registered AS r LEFT JOIN activity AS a
      USING (code_module, code_presentation, id_student)
),
coverage AS (
    SELECT code_module, code_presentation, 'COVERAGE'::TEXT AS output_section,
           'IN_COURSE_COVERAGE'::TEXT AS metric, COUNT(*)::BIGINT AS registered_denominator,
           COUNT(*) FILTER (WHERE in_course_rows>0)::BIGINT AS observed_count,
           COUNT(*) FILTER (WHERE activity_state='OUTSIDE_WINDOW_ONLY')::BIGINT AS outside_window_only_count,
           COUNT(*) FILTER (WHERE activity_state='NO_RECORDED_ACTIVITY')::BIGINT AS no_recorded_activity_count,
           ROUND(100.0*COUNT(*) FILTER (WHERE in_course_rows>0)/NULLIF(COUNT(*),0),2)::NUMERIC AS pct_or_mean,
           NULL::DOUBLE PRECISION AS p25, NULL::DOUBLE PRECISION AS median,
           NULL::DOUBLE PRECISION AS p75, NULL::DOUBLE PRECISION AS p90
    FROM metrics GROUP BY code_module, code_presentation
),
distributions AS (
    SELECT code_module, code_presentation, 'DISTRIBUTION'::TEXT,
           'ACTIVE_DAYS'::TEXT, COUNT(*)::BIGINT,
           COUNT(*) FILTER (WHERE active_days=0)::BIGINT, NULL::BIGINT, NULL::BIGINT,
           AVG(active_days)::NUMERIC,
           percentile_cont(0.25) WITHIN GROUP (ORDER BY active_days),
           percentile_cont(0.50) WITHIN GROUP (ORDER BY active_days),
           percentile_cont(0.75) WITHIN GROUP (ORDER BY active_days),
           percentile_cont(0.90) WITHIN GROUP (ORDER BY active_days)
    FROM metrics GROUP BY code_module, code_presentation
    UNION ALL
    SELECT code_module, code_presentation, 'DISTRIBUTION', 'RESOURCE_BREADTH',
           COUNT(*)::BIGINT, COUNT(*) FILTER (WHERE resource_breadth=0)::BIGINT,
           NULL::BIGINT, NULL::BIGINT, AVG(resource_breadth)::NUMERIC,
           percentile_cont(0.25) WITHIN GROUP (ORDER BY resource_breadth),
           percentile_cont(0.50) WITHIN GROUP (ORDER BY resource_breadth),
           percentile_cont(0.75) WITHIN GROUP (ORDER BY resource_breadth),
           percentile_cont(0.90) WITHIN GROUP (ORDER BY resource_breadth)
    FROM metrics GROUP BY code_module, code_presentation
    UNION ALL
    SELECT code_module, code_presentation, 'DISTRIBUTION', 'FIRST_IN_COURSE_DAY',
           COUNT(*) FILTER (WHERE first_in_course_day IS NOT NULL)::BIGINT,
           COUNT(*) FILTER (WHERE first_in_course_day IS NULL)::BIGINT,
           NULL::BIGINT, NULL::BIGINT, AVG(first_in_course_day)::NUMERIC,
           percentile_cont(0.25) WITHIN GROUP (ORDER BY first_in_course_day),
           percentile_cont(0.50) WITHIN GROUP (ORDER BY first_in_course_day),
           percentile_cont(0.75) WITHIN GROUP (ORDER BY first_in_course_day),
           percentile_cont(0.90) WITHIN GROUP (ORDER BY first_in_course_day)
    FROM metrics GROUP BY code_module, code_presentation
)
SELECT * FROM coverage
UNION ALL SELECT * FROM distributions
ORDER BY code_module, code_presentation, output_section, metric;

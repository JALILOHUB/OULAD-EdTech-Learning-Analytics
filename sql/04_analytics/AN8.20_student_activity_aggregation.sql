-- [AN8.20] Consolidated student-presentation activity extract
-- Question: What are the validated course-relative and registration-relative activity measures for each registered student-presentation, and do all source activity rows reconcile to the registered cohort?
-- Expectation: One pass over student_vle returns one row per registered student-presentation, plus repeated source-level reconciliation totals that expose unmatched activity.
-- Grain: One row per registered student-presentation (code_module, code_presentation, id_student).
-- Source: staging.student_registration, staging.courses, staging.student_vle.
-- Safety: READ-ONLY SELECT. Preserve every R0 source row; no deduplication, DDL, DML, or RAW/QUALITY/STAGING changes.
-- Runtime: HIGH. One full scan/grouping of staging.student_vle. Run alone with statement_timeout_ms=600000 and max_rows >= validated registration count.
-- Read as: Course-relative (pre/in/post/no-course-window) and post-registration measures are separate. Post-registration exposure starts at max(date_registration, 0). Unknown registration dates produce NULL post-registration metrics; no unregistration-date truncation is applied. Clicks/rows are platform activity, not learning quality.
WITH cohort AS (
    SELECT
        r.code_module,
        r.code_presentation,
        r.id_student,
        r.date_registration,
        c.module_presentation_length AS course_length,
        CASE
            WHEN r.date_registration IS NULL THEN NULL
            ELSE GREATEST(r.date_registration, 0)
        END AS exposure_start
    FROM staging.student_registration AS r
    JOIN staging.courses AS c
      USING (code_module, code_presentation)
),
activity AS (
    SELECT
        v.code_module,
        v.code_presentation,
        v.id_student,
        co.module_presentation_length AS course_length,
        c.exposure_start,
        (c.id_student IS NOT NULL) AS registration_match,
        COUNT(*)::BIGINT AS all_observed_activity_rows,
        COALESCE(SUM(v.sum_click), 0)::NUMERIC AS all_observed_recorded_clicks,
        COUNT(*) FILTER (WHERE co.module_presentation_length IS NOT NULL AND v.date < 0)::BIGINT AS pre_course_activity_rows,
        COALESCE(SUM(v.sum_click) FILTER (WHERE co.module_presentation_length IS NOT NULL AND v.date < 0), 0)::NUMERIC AS pre_course_recorded_clicks,
        COUNT(*) FILTER (
            WHERE co.module_presentation_length IS NOT NULL
              AND v.date BETWEEN 0 AND co.module_presentation_length
        )::BIGINT AS in_course_activity_rows,
        COALESCE(SUM(v.sum_click) FILTER (
            WHERE co.module_presentation_length IS NOT NULL
              AND v.date BETWEEN 0 AND co.module_presentation_length
        ), 0)::NUMERIC AS in_course_recorded_clicks,
        COUNT(*) FILTER (
            WHERE co.module_presentation_length IS NOT NULL
              AND v.date > co.module_presentation_length
        )::BIGINT AS post_course_activity_rows,
        COALESCE(SUM(v.sum_click) FILTER (
            WHERE co.module_presentation_length IS NOT NULL
              AND v.date > co.module_presentation_length
        ), 0)::NUMERIC AS post_course_recorded_clicks,
        COUNT(*) FILTER (WHERE co.module_presentation_length IS NULL)::BIGINT
            AS no_course_window_activity_rows,
        COALESCE(SUM(v.sum_click) FILTER (WHERE co.module_presentation_length IS NULL), 0)::NUMERIC
            AS no_course_window_recorded_clicks,
        COUNT(DISTINCT v.date) FILTER (
            WHERE co.module_presentation_length IS NOT NULL
              AND v.date BETWEEN 0 AND co.module_presentation_length
        )::BIGINT AS in_course_active_days,
        COUNT(DISTINCT v.id_site) FILTER (
            WHERE v.id_site IS NOT NULL
              AND co.module_presentation_length IS NOT NULL
              AND v.date BETWEEN 0 AND co.module_presentation_length
        )::BIGINT AS in_course_resource_breadth,
        COUNT(DISTINCT v.date) FILTER (
            WHERE c.exposure_start IS NOT NULL
              AND v.date BETWEEN c.exposure_start AND c.course_length
        )::BIGINT AS post_registration_active_days,
        COUNT(DISTINCT v.id_site) FILTER (
            WHERE v.id_site IS NOT NULL
              AND c.exposure_start IS NOT NULL
              AND v.date BETWEEN c.exposure_start AND c.course_length
        )::BIGINT AS post_registration_resource_breadth
    FROM staging.student_vle AS v
    LEFT JOIN staging.courses AS co
      USING (code_module, code_presentation)
    LEFT JOIN cohort AS c
      USING (code_module, code_presentation, id_student)
    GROUP BY
        v.code_module, v.code_presentation, v.id_student,
        co.module_presentation_length, c.exposure_start, c.id_student
),
source_reconciliation AS (
    SELECT
        COALESCE(SUM(all_observed_activity_rows), 0)::BIGINT AS total_source_activity_rows,
        COALESCE(SUM(all_observed_recorded_clicks), 0)::NUMERIC AS total_source_recorded_clicks,
        COALESCE(SUM(all_observed_activity_rows) FILTER (WHERE registration_match), 0)::BIGINT
            AS matched_registered_activity_rows,
        COALESCE(SUM(all_observed_activity_rows) FILTER (WHERE NOT registration_match), 0)::BIGINT
            AS unmatched_activity_rows,
        COALESCE(SUM(all_observed_recorded_clicks) FILTER (WHERE registration_match), 0)::NUMERIC
            AS matched_registered_recorded_clicks,
        COALESCE(SUM(all_observed_recorded_clicks) FILTER (WHERE NOT registration_match), 0)::NUMERIC
            AS unmatched_recorded_clicks,
        COALESCE(SUM(in_course_activity_rows), 0)::BIGINT AS all_source_in_course_activity_rows,
        COALESCE(SUM(pre_course_activity_rows), 0)::BIGINT AS all_source_pre_course_activity_rows,
        COALESCE(SUM(post_course_activity_rows), 0)::BIGINT AS all_source_post_course_activity_rows,
        COALESCE(SUM(no_course_window_activity_rows), 0)::BIGINT AS all_source_no_course_window_activity_rows,
        COALESCE(SUM(pre_course_recorded_clicks), 0)::NUMERIC AS all_source_pre_course_recorded_clicks,
        COALESCE(SUM(in_course_recorded_clicks), 0)::NUMERIC AS all_source_in_course_recorded_clicks,
        COALESCE(SUM(post_course_recorded_clicks), 0)::NUMERIC AS all_source_post_course_recorded_clicks,
        COALESCE(SUM(no_course_window_recorded_clicks), 0)::NUMERIC AS all_source_no_course_window_recorded_clicks
    FROM activity
)
SELECT
    c.code_module,
    c.code_presentation,
    c.id_student,
    c.date_registration,
    c.course_length,
    c.exposure_start,
    CASE
        WHEN c.exposure_start IS NULL OR c.exposure_start > c.course_length THEN NULL
        ELSE (c.course_length - c.exposure_start + 1)::BIGINT
    END AS post_registration_exposure_days,
    COALESCE(a.all_observed_activity_rows, 0)::BIGINT AS all_observed_activity_rows,
    COALESCE(a.all_observed_recorded_clicks, 0)::NUMERIC AS all_observed_recorded_clicks,
    COALESCE(a.pre_course_activity_rows, 0)::BIGINT AS pre_course_activity_rows,
    COALESCE(a.pre_course_recorded_clicks, 0)::NUMERIC AS pre_course_recorded_clicks,
    COALESCE(a.in_course_activity_rows, 0)::BIGINT AS in_course_activity_rows,
    COALESCE(a.in_course_recorded_clicks, 0)::NUMERIC AS in_course_recorded_clicks,
    COALESCE(a.post_course_activity_rows, 0)::BIGINT AS post_course_activity_rows,
    COALESCE(a.post_course_recorded_clicks, 0)::NUMERIC AS post_course_recorded_clicks,
    COALESCE(a.no_course_window_activity_rows, 0)::BIGINT AS no_course_window_activity_rows,
    COALESCE(a.no_course_window_recorded_clicks, 0)::NUMERIC AS no_course_window_recorded_clicks,
    COALESCE(a.in_course_active_days, 0)::BIGINT AS in_course_active_days,
    COALESCE(a.in_course_resource_breadth, 0)::BIGINT AS in_course_resource_breadth,
    CASE WHEN c.exposure_start IS NULL THEN NULL
         ELSE COALESCE(a.post_registration_active_days, 0)::BIGINT
    END AS post_registration_active_days,
    CASE WHEN c.exposure_start IS NULL THEN NULL
         ELSE COALESCE(a.post_registration_resource_breadth, 0)::BIGINT
    END AS post_registration_resource_breadth,
    CASE
        WHEN c.exposure_start IS NULL OR c.exposure_start > c.course_length THEN NULL
        ELSE COALESCE(a.post_registration_active_days, 0)::NUMERIC
             / NULLIF(c.course_length - c.exposure_start + 1, 0)
    END AS post_registration_active_day_rate,
    (a.id_student IS NOT NULL) AS has_recorded_activity,
    s.total_source_activity_rows,
    s.total_source_recorded_clicks,
    s.matched_registered_activity_rows,
    s.unmatched_activity_rows,
    s.matched_registered_recorded_clicks,
    s.unmatched_recorded_clicks,
    s.all_source_in_course_activity_rows,
    s.all_source_pre_course_activity_rows,
    s.all_source_post_course_activity_rows,
    s.all_source_no_course_window_activity_rows,
    s.all_source_pre_course_recorded_clicks,
    s.all_source_in_course_recorded_clicks,
    s.all_source_post_course_recorded_clicks,
    s.all_source_no_course_window_recorded_clicks
FROM cohort AS c
LEFT JOIN activity AS a
  USING (code_module, code_presentation, id_student)
CROSS JOIN source_reconciliation AS s
ORDER BY c.code_module, c.code_presentation, c.id_student;

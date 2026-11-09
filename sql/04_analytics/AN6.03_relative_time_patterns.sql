-- Question: How does recorded activity distribute across course-relative temporal classes and fixed seven-day bins?
-- Expectation: PRE_COURSE, IN_COURSE, POST_COURSE, and NO_COURSE_WINDOW remain explicit; seven-day bins are analytical periods, not academic weeks.
-- Grain: One row per presentation and temporal bucket, relative seven-day period, or boundary diagnostic.
-- Source: staging.courses, staging.student_registration, staging.student_vle.
-- Safety: READ-ONLY. No source changes or persistent objects. Uses the fixed registered student-presentation cohort.
-- Runtime: HIGH; scans student_vle. Run sequentially after AN6.01 readiness passes.
-- Read as: Counts describe recorded rows. Active registered student-presentations use COUNT(DISTINCT id_student); click totals remain secondary and repetition-sensitive.

-- 1. Classify activity rows once against the course-relative presentation window.
WITH population AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS registered_student_presentations
    FROM staging.student_registration
    GROUP BY code_module, code_presentation
),
classified AS (
    SELECT v.code_module,
           v.code_presentation,
           v.id_student,
           v.date,
           v.sum_click,
           CASE
               WHEN c.code_module IS NULL THEN 'NO_COURSE_WINDOW'
               WHEN v.date < 0 THEN 'PRE_COURSE'
               WHEN v.date <= c.module_presentation_length THEN 'IN_COURSE'
               ELSE 'POST_COURSE'
           END AS temporal_bucket,
           CASE
               WHEN c.code_module IS NULL OR v.date < 0 THEN NULL
               ELSE FLOOR(v.date::NUMERIC / 7)::INTEGER
           END AS relative_7day_period_index,
           r.id_student AS registration_match
    FROM staging.student_vle AS v
    LEFT JOIN staging.courses AS c
      USING (code_module, code_presentation)
    LEFT JOIN staging.student_registration AS r
      ON r.code_module = v.code_module
     AND r.code_presentation = v.code_presentation
     AND r.id_student = v.id_student
),
-- 2. Collapse to one row per student-presentation and temporal bucket/period first.
-- This replaces large COUNT(DISTINCT id_student, id_site, date) and COUNT(DISTINCT id_student)
-- sorts with bounded student-grain aggregation; activity-row totals remain exact.
student_level AS (
    SELECT a.code_module,
           a.code_presentation,
           a.id_student,
           a.temporal_bucket,
           a.relative_7day_period_index,
           GROUPING(a.relative_7day_period_index)::INTEGER AS bucket_level,
           COUNT(*)::BIGINT AS activity_rows,
           BOOL_OR(a.registration_match IS NOT NULL) AS is_registered,
           SUM(a.sum_click)::NUMERIC AS recorded_clicks
    FROM classified AS a
    GROUP BY GROUPING SETS (
        (a.code_module, a.code_presentation, a.id_student, a.temporal_bucket),
        (a.code_module, a.code_presentation, a.id_student, a.temporal_bucket,
         a.relative_7day_period_index)
    )
),
bucket_summary AS (
    SELECT s.code_module,
           s.code_presentation,
           'TEMPORAL_BUCKET'::TEXT AS output_section,
           s.temporal_bucket::TEXT AS bucket_label,
           NULL::INTEGER AS period_index,
           p.registered_student_presentations,
           SUM(s.activity_rows)::BIGINT AS activity_rows,
           COUNT(*) FILTER (WHERE s.is_registered)::BIGINT
               AS active_registered_student_presentations,
           SUM(s.activity_rows) FILTER (WHERE NOT s.is_registered)::BIGINT
               AS unmatched_registration_activity_rows,
           SUM(s.recorded_clicks)::NUMERIC AS recorded_clicks
    FROM student_level AS s
    LEFT JOIN population AS p USING (code_module, code_presentation)
    WHERE s.bucket_level = 1
    GROUP BY s.code_module, s.code_presentation, s.temporal_bucket,
             p.registered_student_presentations
),
period_summary AS (
    SELECT s.code_module,
           s.code_presentation,
           'RELATIVE_7DAY_PERIOD'::TEXT AS output_section,
           CASE
               WHEN s.temporal_bucket = 'NO_COURSE_WINDOW' THEN 'NO_COURSE_WINDOW'
               WHEN s.relative_7day_period_index IS NULL THEN 'PRE_COURSE'
               ELSE 'PERIOD_' || LPAD(s.relative_7day_period_index::TEXT, 3, '0')
           END::TEXT AS bucket_label,
           s.relative_7day_period_index::INTEGER AS period_index,
           p.registered_student_presentations,
           SUM(s.activity_rows)::BIGINT AS activity_rows,
           COUNT(*) FILTER (WHERE s.is_registered)::BIGINT
               AS active_registered_student_presentations,
           SUM(s.activity_rows) FILTER (WHERE NOT s.is_registered)::BIGINT
               AS unmatched_registration_activity_rows,
           SUM(s.recorded_clicks)::NUMERIC AS recorded_clicks
    FROM student_level AS s
    LEFT JOIN population AS p USING (code_module, code_presentation)
    WHERE s.bucket_level = 0
    GROUP BY s.code_module, s.code_presentation, s.temporal_bucket,
             s.relative_7day_period_index, p.registered_student_presentations
),
temporal_summary AS (
    SELECT * FROM bucket_summary
    UNION ALL
    SELECT * FROM period_summary
),
-- 3. Keep explicit edge-day checks without a second composite DISTINCT operation.
boundary_rows AS (
    SELECT c.code_module,
           c.code_presentation,
           'BOUNDARY_DIAGNOSTIC'::TEXT AS output_section,
           b.boundary_label::TEXT AS bucket_label,
           NULL::INTEGER AS period_index,
           p.registered_student_presentations,
           COUNT(v.date)::BIGINT AS activity_rows,
           COUNT(DISTINCT r.id_student)::BIGINT
               AS active_registered_student_presentations,
           COUNT(v.date) FILTER (WHERE v.date IS NOT NULL AND r.id_student IS NULL)::BIGINT
               AS unmatched_registration_activity_rows,
           SUM(v.sum_click)::NUMERIC AS recorded_clicks
    FROM staging.courses AS c
    LEFT JOIN population AS p
      USING (code_module, code_presentation)
    CROSS JOIN LATERAL (
        VALUES
            ('DAY_MINUS_1', -1),
            ('DAY_ZERO', 0),
            ('LAST_IN_COURSE_DAY', c.module_presentation_length),
            ('FIRST_POST_COURSE_DAY', c.module_presentation_length + 1)
    ) AS b(boundary_label, boundary_day)
    LEFT JOIN staging.student_vle AS v
      ON v.code_module = c.code_module
     AND v.code_presentation = c.code_presentation
     AND v.date = b.boundary_day
    LEFT JOIN staging.student_registration AS r
      ON r.code_module = v.code_module
     AND r.code_presentation = v.code_presentation
     AND r.id_student = v.id_student
    GROUP BY c.code_module, c.code_presentation,
             b.boundary_label, p.registered_student_presentations
)
-- 4. Return the compact summary without a final global sort.
SELECT * FROM temporal_summary
UNION ALL
SELECT * FROM boundary_rows;

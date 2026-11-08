-- Question: How does recorded activity distribute across course-relative temporal classes and fixed seven-day bins?
-- Expectation: PRE_COURSE, IN_COURSE, and POST_COURSE are explicit; seven-day bins are analytical periods, not academic weeks.
-- Grain: One row per presentation and temporal bucket or relative seven-day period.
-- Source: staging.courses, staging.student_registration, staging.student_vle.
-- Safety: READ-ONLY. No source changes or persistent objects.
-- Runtime: HIGH; scans student_vle. Run sequentially after AN6.01 review.
-- Read as: Denominator is the fixed registered student-presentation cohort. Presentation-level counts are not unique people across presentations.

-- 1. Classify all activity rows against the presentation window.
WITH population AS (
    SELECT code_module, code_presentation, COUNT(*)::BIGINT AS registered_student_presentations
    FROM (SELECT DISTINCT code_module, code_presentation, id_student FROM staging.student_registration) r
    GROUP BY code_module, code_presentation
),
classified AS (
    SELECT v.code_module, v.code_presentation, v.id_student, v.id_site, v.date, v.sum_click,
           c.module_presentation_length,
           CASE WHEN c.code_module IS NULL THEN 'NO_COURSE_WINDOW'
                WHEN v.date<0 THEN 'PRE_COURSE'
                WHEN v.date<=c.module_presentation_length THEN 'IN_COURSE'
                ELSE 'POST_COURSE' END AS temporal_bucket,
           CASE WHEN c.code_module IS NULL OR v.date<0 THEN NULL
                ELSE FLOOR(v.date::NUMERIC/7)::INTEGER END AS relative_7day_period_index,
           r.id_student AS registration_match
    FROM staging.student_vle v
    LEFT JOIN staging.courses c USING (code_module, code_presentation)
    LEFT JOIN (SELECT DISTINCT code_module,code_presentation,id_student FROM staging.student_registration) r
      ON r.code_module=v.code_module AND r.code_presentation=v.code_presentation AND r.id_student=v.id_student
),
bucket_rows AS (
    SELECT a.code_module, a.code_presentation, 'TEMPORAL_BUCKET'::TEXT AS output_section,
           a.temporal_bucket AS bucket_label, NULL::INTEGER AS period_index,
           p.registered_student_presentations, COUNT(*)::BIGINT AS activity_rows,
           COUNT(DISTINCT (a.id_student,a.id_site,a.date))::BIGINT AS student_resource_day_keys,
           COUNT(DISTINCT a.id_student) FILTER (WHERE a.registration_match IS NOT NULL)::BIGINT AS active_registered_student_presentations,
           COUNT(*) FILTER (WHERE a.registration_match IS NULL)::BIGINT AS unmatched_registration_activity_rows,
           SUM(a.sum_click)::NUMERIC AS recorded_clicks
    FROM classified a LEFT JOIN population p USING (code_module,code_presentation)
    GROUP BY a.code_module,a.code_presentation,a.temporal_bucket,p.registered_student_presentations
),
period_rows AS (
    SELECT a.code_module,a.code_presentation,'RELATIVE_7DAY_PERIOD'::TEXT,
           CASE WHEN a.temporal_bucket='NO_COURSE_WINDOW' THEN 'NO_COURSE_WINDOW'
                WHEN a.relative_7day_period_index IS NULL THEN 'PRE_COURSE'
                ELSE 'PERIOD_'||LPAD(a.relative_7day_period_index::TEXT,3,'0') END,
           a.relative_7day_period_index,p.registered_student_presentations,
           COUNT(*)::BIGINT,COUNT(DISTINCT (a.id_student,a.id_site,a.date))::BIGINT,
           COUNT(DISTINCT a.id_student) FILTER (WHERE a.registration_match IS NOT NULL)::BIGINT,
           COUNT(*) FILTER (WHERE a.registration_match IS NULL)::BIGINT,SUM(a.sum_click)::NUMERIC
    FROM classified a LEFT JOIN population p USING (code_module,code_presentation)
    GROUP BY a.code_module,a.code_presentation,a.temporal_bucket,a.relative_7day_period_index,p.registered_student_presentations
)
,boundary_rows AS (
    SELECT c.code_module,c.code_presentation,'BOUNDARY_DIAGNOSTIC'::TEXT AS output_section,
           b.boundary_label AS bucket_label,NULL::INTEGER AS period_index,
           p.registered_student_presentations,
           COUNT(v.date) FILTER (WHERE v.date=b.boundary_day)::BIGINT AS activity_rows,
           NULL::BIGINT AS student_resource_day_keys,
           COUNT(DISTINCT r.id_student) FILTER (WHERE v.date=b.boundary_day)::BIGINT AS active_registered_student_presentations,
           COUNT(v.date) FILTER (WHERE v.date=b.boundary_day AND r.id_student IS NULL)::BIGINT AS unmatched_registration_activity_rows,
           NULL::NUMERIC AS recorded_clicks
    FROM staging.courses c
    LEFT JOIN population p USING (code_module,code_presentation)
    CROSS JOIN LATERAL (VALUES
        ('DAY_MINUS_1',-1),
        ('DAY_ZERO',0),
        ('LAST_IN_COURSE_DAY',c.module_presentation_length),
        ('FIRST_POST_COURSE_DAY',c.module_presentation_length+1)
    ) b(boundary_label,boundary_day)
    LEFT JOIN staging.student_vle v
      ON v.code_module=c.code_module AND v.code_presentation=c.code_presentation
     AND v.date=b.boundary_day
    LEFT JOIN (SELECT DISTINCT code_module,code_presentation,id_student FROM staging.student_registration) r
      ON r.code_module=v.code_module AND r.code_presentation=v.code_presentation AND r.id_student=v.id_student
    GROUP BY c.code_module,c.code_presentation,b.boundary_label,p.registered_student_presentations
)
SELECT * FROM bucket_rows
UNION ALL SELECT * FROM period_rows
UNION ALL SELECT * FROM boundary_rows
ORDER BY code_module,code_presentation,output_section,period_index NULLS FIRST,bucket_label;

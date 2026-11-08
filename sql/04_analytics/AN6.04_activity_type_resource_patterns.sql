-- Question: Which VLE activity types contribute to in-course resource breadth and registered student-presentation reach?
-- Expectation: Resource joins use the course-scoped key (code_module, code_presentation, id_site); unmatched resources and missing activity_type remain explicit categories.
-- Grain: One row per presentation and activity type, plus one presentation-level metadata reconciliation row.
-- Source: staging.student_registration, staging.student_vle, staging.vle, staging.courses.
-- Safety: READ-ONLY. No persistent objects or source changes.
-- Runtime: HIGH; scans student_vle and joins VLE metadata. Run sequentially.
-- Read as: Reach is distinct registered student-presentations with in-course activity of the type. Missing metadata is not filtered out.

-- 1. Summarize activity-type breadth/reach and resource metadata matching.
WITH registered AS (
    SELECT DISTINCT code_module,code_presentation,id_student FROM staging.student_registration
),
population AS (
    SELECT code_module,code_presentation,COUNT(*)::BIGINT AS registered_student_presentations
    FROM registered GROUP BY code_module,code_presentation
),
joined AS (
    SELECT v.code_module,v.code_presentation,v.id_student,v.id_site,v.date,
           CASE WHEN m.id_site IS NULL THEN 'UNMATCHED_RESOURCE'
                WHEN m.activity_type IS NULL OR BTRIM(m.activity_type)='' THEN 'UNKNOWN_ACTIVITY_TYPE'
                ELSE m.activity_type END AS activity_type,
           (m.id_site IS NOT NULL) AS resource_matched
    FROM staging.student_vle v LEFT JOIN staging.vle m
      ON m.code_module=v.code_module
     AND m.code_presentation=v.code_presentation
     AND m.id_site=v.id_site
),
in_course AS (
    SELECT j.* FROM joined j JOIN staging.courses c USING (code_module,code_presentation)
    WHERE j.date BETWEEN 0 AND c.module_presentation_length
),
types AS (
    SELECT a.code_module,a.code_presentation,a.activity_type,
           COUNT(*)::BIGINT AS in_course_activity_rows,
           COUNT(DISTINCT a.id_site)::BIGINT AS distinct_resources,
           COUNT(DISTINCT a.id_student)::BIGINT AS active_student_presentations,
           COUNT(DISTINCT a.date)::BIGINT AS distinct_course_relative_days,
           COUNT(*) FILTER (WHERE NOT a.resource_matched)::BIGINT AS unmatched_resource_rows
    FROM in_course a
    JOIN registered r ON r.code_module=a.code_module AND r.code_presentation=a.code_presentation AND r.id_student=a.id_student
    GROUP BY a.code_module,a.code_presentation,a.activity_type
),
meta AS (
    SELECT v.code_module,v.code_presentation,COUNT(*)::BIGINT AS all_activity_rows,
           COUNT(*) FILTER (WHERE m.id_site IS NOT NULL)::BIGINT AS matched_resource_rows,
           COUNT(*) FILTER (WHERE m.id_site IS NULL)::BIGINT AS unmatched_resource_rows,
           COUNT(*) FILTER (WHERE m.id_site IS NOT NULL AND (m.activity_type IS NULL OR BTRIM(m.activity_type)=''))::BIGINT AS missing_activity_type_rows,
           COUNT(*) FILTER (WHERE r.id_student IS NULL)::BIGINT AS unmatched_registration_activity_rows
    FROM staging.student_vle v LEFT JOIN staging.vle m
      ON m.code_module=v.code_module
     AND m.code_presentation=v.code_presentation
     AND m.id_site=v.id_site
    LEFT JOIN registered r ON r.code_module=v.code_module AND r.code_presentation=v.code_presentation AND r.id_student=v.id_student
    GROUP BY v.code_module,v.code_presentation
)
SELECT 'IN_COURSE_ACTIVITY_TYPE'::TEXT AS output_section,t.code_module,t.code_presentation,t.activity_type,
       p.registered_student_presentations,t.in_course_activity_rows,t.distinct_resources,
       t.active_student_presentations,
       ROUND(100.0*t.active_student_presentations/NULLIF(p.registered_student_presentations,0),2) AS registered_reach_pct,
       t.distinct_course_relative_days,t.unmatched_resource_rows,
       NULL::BIGINT AS all_activity_rows,NULL::BIGINT AS matched_resource_rows,
       NULL::BIGINT AS unmatched_resource_rows_total,NULL::BIGINT AS missing_activity_type_rows,NULL::BIGINT AS unmatched_registration_activity_rows
FROM types t LEFT JOIN population p USING (code_module,code_presentation)
UNION ALL
SELECT 'ALL_ACTIVITY_METADATA_MATCH',m.code_module,m.code_presentation,'ALL_TYPES',
       p.registered_student_presentations,NULL::BIGINT,NULL::BIGINT,NULL::BIGINT,NULL::NUMERIC,
       NULL::BIGINT,NULL::BIGINT,m.all_activity_rows,m.matched_resource_rows,
       m.unmatched_resource_rows,m.missing_activity_type_rows,m.unmatched_registration_activity_rows
FROM meta m LEFT JOIN population p USING (code_module,code_presentation)
ORDER BY code_module,code_presentation,output_section,activity_type;

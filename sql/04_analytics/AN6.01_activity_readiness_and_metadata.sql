-- Question: Are course windows, VLE resource metadata, and registration/activity keys ready for AN6?
-- Expectation: Each presentation has one valid non-negative length; VLE id_site and registration keys are unique; activity key components are complete.
-- Grain: One row per course presentation; one VLE metadata summary; one registration/activity key summary.
-- Source: staging.courses, staging.vle, staging.student_registration, staging.student_vle.
-- Safety: READ-ONLY. No persistent objects or source modifications.
-- Runtime: LOW to MODERATE; metadata/key diagnostics only.
-- Read as: Review all three result sets. Invalid windows or keys block downstream queries. Missing activity_type/week metadata is reported, not filtered.

-- 1. Course-window integrity.
SELECT code_module, code_presentation, module_presentation_length,
       COUNT(*) OVER (PARTITION BY code_module, code_presentation) AS course_key_rows,
       (module_presentation_length IS NOT NULL AND module_presentation_length >= 0) AS valid_course_window
FROM staging.courses
ORDER BY code_module, code_presentation;

-- 2. VLE resource metadata.
SELECT COUNT(*)::BIGINT AS vle_rows,
       COUNT(DISTINCT id_site)::BIGINT AS distinct_id_site,
       (COUNT(*) - COUNT(DISTINCT id_site))::BIGINT AS excess_rows_over_distinct_id_site,
       COUNT(*) FILTER (WHERE id_site IS NULL)::BIGINT AS null_id_site_rows,
       COUNT(*) FILTER (WHERE activity_type IS NULL OR BTRIM(activity_type) = '')::BIGINT AS missing_activity_type_rows,
       COUNT(*) FILTER (WHERE week_from IS NULL)::BIGINT AS missing_week_from_rows,
       COUNT(*) FILTER (WHERE week_to IS NULL)::BIGINT AS missing_week_to_rows,
       COUNT(*) FILTER (WHERE week_from IS NOT NULL AND week_to IS NOT NULL AND week_from > week_to)::BIGINT AS reversed_week_range_rows
FROM staging.vle;

-- 3. Registration/activity key integrity.
WITH registration_keys AS (
    SELECT code_module, code_presentation, id_student, COUNT(*)::BIGINT AS key_rows
    FROM staging.student_registration
    GROUP BY code_module, code_presentation, id_student
),
activity_profile AS (
    SELECT COUNT(*)::BIGINT AS activity_rows,
           COUNT(*) FILTER (WHERE code_module IS NULL OR code_presentation IS NULL OR id_student IS NULL OR id_site IS NULL OR date IS NULL)::BIGINT AS activity_rows_with_null_key_component
    FROM staging.student_vle
)
SELECT (SELECT COUNT(*) FROM staging.student_registration)::BIGINT AS registration_rows,
       COUNT(*)::BIGINT AS distinct_registration_keys,
       COUNT(*) FILTER (WHERE key_rows > 1)::BIGINT AS duplicate_registration_keys,
       COALESCE(SUM(key_rows - 1) FILTER (WHERE key_rows > 1), 0)::BIGINT AS excess_registration_rows,
       a.activity_rows, a.activity_rows_with_null_key_component
FROM registration_keys CROSS JOIN activity_profile AS a
GROUP BY a.activity_rows, a.activity_rows_with_null_key_component;

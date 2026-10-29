-- Question: How do student-presentation registrations differ from distinct people across the dataset?
-- Expectation: Registration rows count student-module-presentation records; distinct id_student counts people represented at least once.
-- Grain: One overall summary row and one row per number of presentations per student.
-- Source: staging.student_registration.
-- Safety: READ-ONLY
-- Runtime: Low; aggregates approximately 32.6K rows.
-- Read as: Do not label registration counts as unique people. A person can contribute multiple registrations across presentations.

-- 1. Report registration-grain and person-grain counts separately.
WITH per_student AS (
    SELECT id_student,
           COUNT(*)::BIGINT AS registration_count,
           COUNT(DISTINCT (code_module, code_presentation))::BIGINT AS presentation_count
    FROM staging.student_registration
    GROUP BY id_student
),
overall AS (
    SELECT COUNT(*)::BIGINT AS registration_rows,
           COUNT(DISTINCT id_student)::BIGINT AS distinct_people,
           COUNT(*) FILTER (WHERE date_registration IS NULL)::BIGINT AS null_registration_date_rows,
           COUNT(*) FILTER (WHERE date_unregistration IS NOT NULL)::BIGINT AS rows_with_unregistration_date
    FROM staging.student_registration
),
presentation_distribution AS (
    SELECT presentation_count,
           COUNT(*)::BIGINT AS people_count
    FROM per_student
    GROUP BY presentation_count
)
SELECT 'OVERALL'::TEXT AS metric_group,
       NULL::BIGINT AS presentation_count,
       o.registration_rows AS registration_rows,
       o.distinct_people AS people_count,
       o.null_registration_date_rows AS null_registration_date_rows,
       o.rows_with_unregistration_date AS rows_with_unregistration_date
FROM overall AS o
UNION ALL
SELECT 'PEOPLE_BY_PRESENTATION_COUNT',
       d.presentation_count,
       NULL::BIGINT,
       d.people_count,
       NULL::BIGINT,
       NULL::BIGINT
FROM presentation_distribution AS d
ORDER BY metric_group, presentation_count NULLS FIRST;

-- Question: Among student-presentations classified as Withdrawn, how many have a recorded VLE activity row, and how does the last recorded activity day compare with the unregistration day?
-- Expectation: The query describes recorded-row presence and timing. No direction or prevalence is assumed.
-- Grain: One row per module, presentation, and recorded-activity group among Withdrawn student-presentations.
-- Source: staging.student_info, staging.student_registration, staging.student_vle (aggregated to student-presentation first).
-- Safety: READ-ONLY
-- Runtime: HIGH. Scans staging.student_vle (historically about 10.6M rows). Run alone. If needed, pass a reviewed higher statement_timeout_ms through the shared runner; do not add SET commands here.
-- Read as: NO_ACTIVITY means no matching row was found in staging.student_vle for this student-presentation. It does not prove the student never clicked, did not learn, or used no other channel. Report both the Withdrawn denominator and the full student-presentation denominator. Do not use sum_click.

WITH activity AS (
    SELECT code_module, code_presentation, id_student,
           MAX(date) AS last_activity_day
    FROM staging.student_vle
    GROUP BY code_module, code_presentation, id_student
),
withdrawn AS (
    SELECT si.code_module, si.code_presentation, si.id_student,
           sr.id_student AS registration_match,
           sr.date_unregistration,
           a.id_student AS activity_match,
           a.last_activity_day
    FROM staging.student_info AS si
    LEFT JOIN staging.student_registration AS sr
      ON sr.code_module = si.code_module
     AND sr.code_presentation = si.code_presentation
     AND sr.id_student = si.id_student
    LEFT JOIN activity AS a
      ON a.code_module = si.code_module
     AND a.code_presentation = si.code_presentation
     AND a.id_student = si.id_student
    WHERE si.final_result = 'Withdrawn'
),
presentation_denominators AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS all_student_presentations
    FROM staging.student_info
    GROUP BY code_module, code_presentation
),
withdrawn_denominators AS (
    SELECT code_module, code_presentation,
           COUNT(*)::BIGINT AS withdrawn_presentations
    FROM withdrawn
    GROUP BY code_module, code_presentation
),
grouped AS (
    SELECT code_module,
           code_presentation,
           CASE
               WHEN registration_match IS NULL THEN 'NO_REGISTRATION_MATCH'
               WHEN activity_match IS NULL THEN 'NO_RECORDED_ACTIVITY_ROW'
               WHEN date_unregistration IS NULL THEN 'ACTIVITY_UNREGISTRATION_DATE_MISSING'
               WHEN last_activity_day IS NULL THEN 'ACTIVITY_ROW_WITH_NULL_MAX_DATE'
               WHEN last_activity_day <= date_unregistration THEN 'LAST_ACTIVITY_ON_OR_BEFORE_UNREGISTRATION'
               ELSE 'LAST_ACTIVITY_AFTER_UNREGISTRATION'
           END AS activity_group,
           COUNT(*)::BIGINT AS withdrawn_student_presentations,
           COUNT(DISTINCT id_student)::BIGINT AS distinct_students
    FROM withdrawn
    GROUP BY code_module, code_presentation, 3
)
SELECT g.code_module,
       g.code_presentation,
       g.activity_group,
       g.withdrawn_student_presentations,
       g.distinct_students,
       wd.withdrawn_presentations AS withdrawn_denominator,
       pd.all_student_presentations AS all_student_presentation_denominator,
       ROUND(100.0 * g.withdrawn_student_presentations
             / NULLIF(wd.withdrawn_presentations, 0), 2) AS pct_of_withdrawn_presentations,
       ROUND(100.0 * g.withdrawn_student_presentations
             / NULLIF(pd.all_student_presentations, 0), 2) AS pct_of_all_student_presentations
FROM grouped AS g
JOIN withdrawn_denominators AS wd
  USING (code_module, code_presentation)
JOIN presentation_denominators AS pd
  USING (code_module, code_presentation)
ORDER BY g.code_module, g.code_presentation, g.activity_group;

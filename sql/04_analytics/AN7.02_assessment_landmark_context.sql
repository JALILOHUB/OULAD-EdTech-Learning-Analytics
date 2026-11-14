-- Question: Which assessment due dates and recorded weights fall on or before the proposed 28-, 56-, and 84-day landmarks?
-- Expectation: Assessment structure and due-date coverage vary by module-presentation and type; no universal weight rule is assumed.
-- Grain: One row per module-presentation, assessment type, and landmark.
-- Source: staging.courses, staging.assessments.
-- Safety: READ-ONLY. No source changes, DDL, temporary tables, or persistent objects.
-- Runtime: LOW. Aggregates the small assessment metadata table.
-- Read as: "Due by landmark" means stored assessment date <= landmark while the landmark lies inside the course window. It does not prove score or feedback availability. No weighted score is created.

WITH landmarks(landmark, landmark_day) AS (
    VALUES ('L28',27),('L56',55),('L84',83)
),
presentation_landmarks AS (
    SELECT c.code_module, c.code_presentation, c.module_presentation_length,
           l.landmark, l.landmark_day,
           (l.landmark_day <= c.module_presentation_length) AS landmark_within_course
    FROM staging.courses c CROSS JOIN landmarks l
)
SELECT p.code_module, p.code_presentation, a.assessment_type,
       p.landmark, p.landmark_day, p.module_presentation_length,
       p.landmark_within_course,
       COUNT(a.id_assessment)::BIGINT AS assessment_count,
       COUNT(a.id_assessment) FILTER (WHERE a.date IS NULL)::BIGINT AS assessments_without_due_date,
       COUNT(a.id_assessment) FILTER (
         WHERE p.landmark_within_course AND a.date IS NOT NULL AND a.date <= p.landmark_day
       )::BIGINT AS assessments_due_by_landmark,
       SUM(a.weight) FILTER (WHERE a.id_assessment IS NOT NULL) AS total_recorded_weight,
       SUM(a.weight) FILTER (
         WHERE p.landmark_within_course AND a.date IS NOT NULL AND a.date <= p.landmark_day
       ) AS recorded_weight_due_by_landmark
FROM presentation_landmarks p
LEFT JOIN staging.assessments a
  ON a.code_module=p.code_module AND a.code_presentation=p.code_presentation
GROUP BY p.code_module,p.code_presentation,a.assessment_type,p.landmark,
         p.landmark_day,p.module_presentation_length,p.landmark_within_course;

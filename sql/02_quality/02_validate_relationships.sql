-- Purpose: Validate tested references among RAW tables.
-- Execute each SELECT separately in pgAdmin if you need to inspect every result set.

-- B3.1: Parent-reference checks.
SELECT 'assessments -> courses' AS relationship_name, COUNT(*) AS unmatched_rows
FROM raw.assessments a
LEFT JOIN raw.courses c
  ON c.code_module = a.code_module
 AND c.code_presentation = a.code_presentation
WHERE c.code_module IS NULL
UNION ALL
SELECT 'student_info -> courses', COUNT(*)
FROM raw.student_info s
LEFT JOIN raw.courses c
  ON c.code_module = s.code_module
 AND c.code_presentation = s.code_presentation
WHERE c.code_module IS NULL
UNION ALL
SELECT 'student_registration -> courses', COUNT(*)
FROM raw.student_registration s
LEFT JOIN raw.courses c
  ON c.code_module = s.code_module
 AND c.code_presentation = s.code_presentation
WHERE c.code_module IS NULL
UNION ALL
SELECT 'student_assessment -> assessments', COUNT(*)
FROM raw.student_assessment sa
LEFT JOIN raw.assessments a ON a.id_assessment = sa.id_assessment
WHERE a.id_assessment IS NULL
UNION ALL
SELECT 'student_vle -> vle', COUNT(*)
FROM raw.student_vle sv
LEFT JOIN raw.vle v
  ON v.id_site = sv.id_site
 AND v.code_module = sv.code_module
 AND v.code_presentation = sv.code_presentation
WHERE v.id_site IS NULL
ORDER BY relationship_name;

-- B3.2: Assessment rows against the matching student-course record.
SELECT COUNT(*) AS student_assessment_rows,
       COUNT(*) FILTER (WHERE a.id_assessment IS NULL) AS unmatched_assessment_rows,
       COUNT(*) FILTER (
           WHERE a.id_assessment IS NOT NULL AND si.id_student IS NULL
       ) AS unmatched_student_course_rows
FROM raw.student_assessment sa
LEFT JOIN raw.assessments a ON a.id_assessment = sa.id_assessment
LEFT JOIN raw.student_info si
  ON si.id_student = sa.id_student
 AND si.code_module = a.code_module
 AND si.code_presentation = a.code_presentation;

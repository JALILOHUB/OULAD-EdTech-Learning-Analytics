-- Purpose: Validate post-creation STAGING integrity and key preservation.
-- Execute each SELECT separately in pgAdmin. Run only after the STAGING tables exist.

-- Reconcile row counts between RAW and STAGING after table creation.
SELECT 'assessments' AS table_name,
       (SELECT COUNT(*) FROM raw.assessments) AS raw_rows,
       (SELECT COUNT(*) FROM staging.assessments) AS staging_rows
UNION ALL SELECT 'courses', (SELECT COUNT(*) FROM raw.courses), (SELECT COUNT(*) FROM staging.courses)
UNION ALL SELECT 'student_assessment', (SELECT COUNT(*) FROM raw.student_assessment), (SELECT COUNT(*) FROM staging.student_assessment)
UNION ALL SELECT 'student_info', (SELECT COUNT(*) FROM raw.student_info), (SELECT COUNT(*) FROM staging.student_info)
UNION ALL SELECT 'student_registration', (SELECT COUNT(*) FROM raw.student_registration), (SELECT COUNT(*) FROM staging.student_registration)
UNION ALL SELECT 'student_vle', (SELECT COUNT(*) FROM raw.student_vle), (SELECT COUNT(*) FROM staging.student_vle)
UNION ALL SELECT 'vle', (SELECT COUNT(*) FROM raw.vle), (SELECT COUNT(*) FROM staging.vle)
ORDER BY table_name;

-- Inspect the converted column data types.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND ((table_name = 'assessments' AND column_name = 'date')
    OR (table_name = 'student_registration' AND column_name IN ('date_registration', 'date_unregistration'))
    OR (table_name = 'student_assessment' AND column_name = 'score')
    OR (table_name = 'vle' AND column_name IN ('week_from', 'week_to'))
    OR (table_name = 'student_info' AND column_name = 'imd_band'))
ORDER BY table_name, column_name;

-- S1: Reconcile RAW question-mark tokens with STAGING NULL values.
SELECT 'assessments.date' AS column_name,
       COUNT(*) FILTER (WHERE BTRIM(r.date) = '?') AS raw_missing_tokens,
       COUNT(*) FILTER (WHERE s.date IS NULL) AS staging_nulls
FROM raw.assessments r JOIN staging.assessments s
  USING (code_module, code_presentation, id_assessment)
UNION ALL
SELECT 'student_registration.date_registration',
       COUNT(*) FILTER (WHERE BTRIM(r.date_registration) = '?'),
       COUNT(*) FILTER (WHERE s.date_registration IS NULL)
FROM raw.student_registration r JOIN staging.student_registration s
  USING (code_module, code_presentation, id_student)
UNION ALL
SELECT 'student_registration.date_unregistration',
       COUNT(*) FILTER (WHERE BTRIM(r.date_unregistration) = '?'),
       COUNT(*) FILTER (WHERE s.date_unregistration IS NULL)
FROM raw.student_registration r JOIN staging.student_registration s
  USING (code_module, code_presentation, id_student)
UNION ALL
SELECT 'student_assessment.score',
       COUNT(*) FILTER (WHERE BTRIM(r.score) = '?'),
       COUNT(*) FILTER (WHERE s.score IS NULL)
FROM raw.student_assessment r JOIN staging.student_assessment s
  USING (id_assessment, id_student)
UNION ALL
SELECT 'student_info.imd_band',
       COUNT(*) FILTER (WHERE BTRIM(r.imd_band) = '?'),
       COUNT(*) FILTER (WHERE s.imd_band IS NULL)
FROM raw.student_info r JOIN staging.student_info s
  USING (code_module, code_presentation, id_student)
UNION ALL
SELECT 'vle.week_from', COUNT(*) FILTER (WHERE BTRIM(r.week_from) = '?'),
       COUNT(*) FILTER (WHERE s.week_from IS NULL)
FROM raw.vle r JOIN staging.vle s USING (id_site)
UNION ALL
SELECT 'vle.week_to', COUNT(*) FILTER (WHERE BTRIM(r.week_to) = '?'),
       COUNT(*) FILTER (WHERE s.week_to IS NULL)
FROM raw.vle r JOIN staging.vle s USING (id_site)
ORDER BY column_name;

-- S3: Validate converted assessment scores in STAGING.
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE score IS NULL) AS null_scores,
       COUNT(*) FILTER (WHERE score < 0) AS negative_scores,
       COUNT(*) FILTER (WHERE score > 100) AS scores_above_100,
       MIN(score) AS minimum_score,
       MAX(score) AS maximum_score
FROM staging.student_assessment;

-- S4: Validate converted VLE week ranges in STAGING.
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE week_from IS NULL) AS missing_week_from,
       COUNT(*) FILTER (WHERE week_to IS NULL) AS missing_week_to,
       COUNT(*) FILTER (WHERE week_from IS NOT NULL AND week_to IS NOT NULL
                          AND week_from > week_to) AS reversed_week_ranges,
       MIN(week_from) AS minimum_week_from,
       MAX(week_from) AS maximum_week_from,
       MIN(week_to) AS minimum_week_to,
       MAX(week_to) AS maximum_week_to
FROM staging.vle;

-- S5: Confirm STAGING preserved student_vle rows and the observed candidate-key pattern.
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT (code_module, code_presentation, id_student, id_site, date)) AS distinct_candidate_keys,
       COUNT(*) - COUNT(DISTINCT (code_module, code_presentation, id_student, id_site, date)) AS excess_rows
FROM staging.student_vle;

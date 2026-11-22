-- [P3.07] Cross-domain grain and join-cardinality validation
-- Question: Do source relation keys and cross-domain joins preserve their declared grains, or do they create row multiplication?
-- Expectation: Candidate-key duplicate groups and before/after join counts are reported independently for each relationship.
-- Grain: Result set 1 = one row per candidate-key test; result set 2 = one row per join-cardinality test.
-- Source: source_ref.courses, assessments, student_info, student_registration, student_assessment, vle, student_vle.
-- Safety: READ-ONLY SELECT. No constraints, indexes, or persistent objects are created.
-- Runtime: MEDIUM to HIGH; student_vle reference checks scan the high-volume relation.
-- Read as: A join is accepted only when its observed cardinality matches the intended relationship. Do not resolve duplicates by deleting rows.

-- 1. Candidate-key duplicate counts for relations with expected keys.
WITH duplicate_groups AS (
    SELECT 'courses(code_module,code_presentation)'::TEXT AS key_name, COUNT(*)::BIGINT AS duplicate_groups
    FROM (SELECT code_module, code_presentation FROM source_ref.courses GROUP BY 1,2 HAVING COUNT(*) > 1) q
    UNION ALL
    SELECT 'assessments(id_assessment)', COUNT(*)
    FROM (SELECT id_assessment FROM source_ref.assessments GROUP BY 1 HAVING COUNT(*) > 1) q
    UNION ALL
    SELECT 'student_info(module,presentation,student)', COUNT(*)
    FROM (SELECT code_module, code_presentation, id_student FROM source_ref.student_info GROUP BY 1,2,3 HAVING COUNT(*) > 1) q
    UNION ALL
    SELECT 'student_registration(module,presentation,student)', COUNT(*)
    FROM (SELECT code_module, code_presentation, id_student FROM source_ref.student_registration GROUP BY 1,2,3 HAVING COUNT(*) > 1) q
    UNION ALL
    SELECT 'student_assessment(assessment,student)', COUNT(*)
    FROM (SELECT id_assessment, id_student FROM source_ref.student_assessment GROUP BY 1,2 HAVING COUNT(*) > 1) q
    UNION ALL
    SELECT 'vle(module,presentation,site)', COUNT(*)
    FROM (SELECT code_module, code_presentation, id_site FROM source_ref.vle GROUP BY 1,2,3 HAVING COUNT(*) > 1) q
)
SELECT key_name, duplicate_groups FROM duplicate_groups ORDER BY key_name;

-- 2. Registered cohort joins: base cohort, after course join, and after student profile join.
WITH base AS (
    SELECT code_module, code_presentation, id_student
    FROM source_ref.student_registration
),
course_join AS (
    SELECT b.code_module, b.code_presentation, b.id_student
    FROM base b
    LEFT JOIN source_ref.courses c USING (code_module, code_presentation)
),
profile_join AS (
    SELECT b.code_module, b.code_presentation, b.id_student
    FROM base b
    LEFT JOIN source_ref.student_info i USING (code_module, code_presentation, id_student)
)
SELECT 'registration_base'::TEXT AS join_stage, COUNT(*)::BIGINT AS rows FROM base
UNION ALL SELECT 'after_course_join', COUNT(*)::BIGINT FROM course_join
UNION ALL SELECT 'after_profile_join', COUNT(*)::BIGINT FROM profile_join;

-- 3. Student VLE foreign-reference states: course, registration, and resource.
SELECT
    CASE WHEN c.code_module IS NULL THEN 'NO_COURSE_MATCH' ELSE 'COURSE_MATCH' END AS course_state,
    CASE WHEN r.id_student IS NULL THEN 'NO_REGISTRATION_MATCH' ELSE 'REGISTRATION_MATCH' END AS registration_state,
    CASE WHEN v.id_site IS NULL THEN 'NO_RESOURCE_MATCH' ELSE 'RESOURCE_MATCH' END AS resource_state,
    COUNT(*)::BIGINT AS source_activity_rows
FROM source_ref.student_vle s
LEFT JOIN source_ref.courses c USING (code_module, code_presentation)
LEFT JOIN source_ref.student_registration r USING (code_module, code_presentation, id_student)
LEFT JOIN source_ref.vle v USING (code_module, code_presentation, id_site)
GROUP BY 1,2,3
ORDER BY 1,2,3;

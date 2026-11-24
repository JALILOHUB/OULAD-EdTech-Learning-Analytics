-- [P3.07] Cross-domain grain and join-cardinality validation
-- Question: Do source relation keys and cross-domain joins preserve their declared grains, or can they multiply source records?
-- Expectation: Candidate-key duplicate groups, cohort join counts, and activity-reference match cardinalities are reported without fan-out.
-- Grain: Result set 1 = one row per candidate-key test; result set 2 = one row per cohort join stage; result set 3 = one row per activity reference-match pattern.
-- Source: source_ref.courses, assessments, student_info, student_registration, student_assessment, vle, student_vle.
-- Safety: READ-ONLY SELECT. No constraints, indexes, or persistent objects are created.
-- Runtime: HIGH; result set 3 scans the 10.6M-row student_vle relation. Run alone.
-- Read as: Resolve key uniqueness and join cardinality before downstream joins. Counts greater than one indicate potential fan-out; never repair them by deleting source rows.

-- 1. Candidate-key duplicate groups for the source relations.
WITH duplicate_groups AS (
    SELECT 'courses(module,presentation)'::TEXT AS key_name, COUNT(*)::BIGINT AS duplicate_groups
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
    UNION ALL
    SELECT 'student_vle(module,presentation,student,site,date)', COUNT(*)
    FROM (SELECT code_module, code_presentation, id_student, id_site, date
          FROM source_ref.student_vle GROUP BY 1,2,3,4,5 HAVING COUNT(*) > 1) q
)
SELECT key_name, duplicate_groups
FROM duplicate_groups
ORDER BY key_name;

-- 2. Confirm registered-cohort join counts and key-set agreement.
WITH base AS (
    SELECT code_module, code_presentation, id_student FROM source_ref.student_registration
),
course_join AS (
    SELECT b.code_module, b.code_presentation, b.id_student
    FROM base b LEFT JOIN source_ref.courses c USING (code_module, code_presentation)
),
profile_join AS (
    SELECT b.code_module, b.code_presentation, b.id_student
    FROM base b LEFT JOIN source_ref.student_info i USING (code_module, code_presentation, id_student)
),
key_set_difference AS (
    SELECT 'registration_without_profile'::TEXT AS difference_type, COUNT(*)::BIGINT AS keys
    FROM (
        SELECT code_module, code_presentation, id_student FROM source_ref.student_registration
        EXCEPT
        SELECT code_module, code_presentation, id_student FROM source_ref.student_info
    ) d
    UNION ALL
    SELECT 'profile_without_registration', COUNT(*)::BIGINT
    FROM (
        SELECT code_module, code_presentation, id_student FROM source_ref.student_info
        EXCEPT
        SELECT code_module, code_presentation, id_student FROM source_ref.student_registration
    ) d
)
SELECT 'registration_base'::TEXT AS join_stage, COUNT(*)::BIGINT AS rows FROM base
UNION ALL SELECT 'after_course_join', COUNT(*)::BIGINT FROM course_join
UNION ALL SELECT 'after_profile_join', COUNT(*)::BIGINT FROM profile_join
UNION ALL SELECT 'key_set_difference:' || difference_type, keys FROM key_set_difference
ORDER BY join_stage;

-- 3. Count reference matches per source activity row without multiplying rows.
-- Reference relations are grouped to one row per lookup key before joining.
WITH course_keys AS (
    SELECT code_module, code_presentation, COUNT(*)::BIGINT AS match_count
    FROM source_ref.courses GROUP BY 1,2
),
registration_keys AS (
    SELECT code_module, code_presentation, id_student, COUNT(*)::BIGINT AS match_count
    FROM source_ref.student_registration GROUP BY 1,2,3
),
profile_keys AS (
    SELECT code_module, code_presentation, id_student, COUNT(*)::BIGINT AS match_count
    FROM source_ref.student_info GROUP BY 1,2,3
),
resource_keys AS (
    SELECT code_module, code_presentation, id_site, COUNT(*)::BIGINT AS match_count
    FROM source_ref.vle GROUP BY 1,2,3
)
SELECT
    CASE WHEN COALESCE(c.match_count, 0) = 0 THEN 'NO_COURSE_MATCH'
         WHEN c.match_count = 1 THEN 'ONE_COURSE_MATCH'
         ELSE 'MULTIPLE_COURSE_MATCHES' END AS course_match_state,
    CASE WHEN COALESCE(r.match_count, 0) = 0 THEN 'NO_REGISTRATION_MATCH'
         WHEN r.match_count = 1 THEN 'ONE_REGISTRATION_MATCH'
         ELSE 'MULTIPLE_REGISTRATION_MATCHES' END AS registration_match_state,
    CASE WHEN COALESCE(i.match_count, 0) = 0 THEN 'NO_PROFILE_MATCH'
         WHEN i.match_count = 1 THEN 'ONE_PROFILE_MATCH'
         ELSE 'MULTIPLE_PROFILE_MATCHES' END AS profile_match_state,
    CASE WHEN COALESCE(v.match_count, 0) = 0 THEN 'NO_RESOURCE_MATCH'
         WHEN v.match_count = 1 THEN 'ONE_RESOURCE_MATCH'
         ELSE 'MULTIPLE_RESOURCE_MATCHES' END AS resource_match_state,
    COUNT(*)::BIGINT AS source_activity_rows
FROM source_ref.student_vle s
LEFT JOIN course_keys c USING (code_module, code_presentation)
LEFT JOIN registration_keys r USING (code_module, code_presentation, id_student)
LEFT JOIN profile_keys i USING (code_module, code_presentation, id_student)
LEFT JOIN resource_keys v USING (code_module, code_presentation, id_site)
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4;

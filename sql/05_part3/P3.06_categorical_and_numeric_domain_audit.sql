-- [P3.06] Categorical tokens and numeric-domain audit
-- Question: Which categorical values, missing tokens, and numeric ranges are actually present across the seven source files?
-- Expectation: Value frequencies and numeric ranges are reported without normalizing spelling, merging categories, or replacing source tokens.
-- Grain: Result set 1 = one row per field/value token; result set 2 = one row per numeric field.
-- Source: source_ref.student_info, student_registration, student_assessment, assessments, vle, courses.
-- Safety: READ-ONLY SELECT. No category recoding, imputation, or domain enforcement.
-- Runtime: MEDIUM; grouped scans of smaller dimensions and assessment tables.
-- Read as: This is an observed-domain inventory. A rare value or a spelling variant is not automatically invalid; compare with the official source descriptor before defining canonical categories.

-- 1. Observed categorical values, preserving blanks and question-mark tokens as distinct states.
WITH values_by_field AS (
    SELECT 'student_info.gender'::TEXT AS source_field, COALESCE(NULLIF(BTRIM(gender), ''), '<BLANK_OR_NULL>') AS source_value FROM source_ref.student_info
    UNION ALL SELECT 'student_info.region', COALESCE(NULLIF(BTRIM(region), ''), '<BLANK_OR_NULL>') FROM source_ref.student_info
    UNION ALL SELECT 'student_info.highest_education', COALESCE(NULLIF(BTRIM(highest_education), ''), '<BLANK_OR_NULL>') FROM source_ref.student_info
    UNION ALL SELECT 'student_info.imd_band', COALESCE(NULLIF(BTRIM(imd_band), ''), '<BLANK_OR_NULL>') FROM source_ref.student_info
    UNION ALL SELECT 'student_info.age_band', COALESCE(NULLIF(BTRIM(age_band), ''), '<BLANK_OR_NULL>') FROM source_ref.student_info
    UNION ALL SELECT 'student_info.disability', COALESCE(NULLIF(BTRIM(disability), ''), '<BLANK_OR_NULL>') FROM source_ref.student_info
    UNION ALL SELECT 'student_info.final_result', COALESCE(NULLIF(BTRIM(final_result), ''), '<BLANK_OR_NULL>') FROM source_ref.student_info
    UNION ALL SELECT 'student_assessment.is_banked', COALESCE(NULLIF(BTRIM(is_banked), ''), '<BLANK_OR_NULL>') FROM source_ref.student_assessment
    UNION ALL SELECT 'assessments.assessment_type', COALESCE(NULLIF(BTRIM(assessment_type), ''), '<BLANK_OR_NULL>') FROM source_ref.assessments
    UNION ALL SELECT 'vle.activity_type', COALESCE(NULLIF(BTRIM(activity_type), ''), '<BLANK_OR_NULL>') FROM source_ref.vle
)
SELECT source_field, source_value, COUNT(*)::BIGINT AS occurrences
FROM values_by_field
GROUP BY source_field, source_value
ORDER BY source_field, occurrences DESC, source_value;

-- 2. Numeric ranges with guarded parsing; unparseable source tokens remain counted.
WITH numeric_values AS (
    SELECT 'courses.module_presentation_length'::TEXT AS source_field, module_presentation_length AS raw_value FROM source_ref.courses
    UNION ALL SELECT 'student_info.num_of_prev_attempts', num_of_prev_attempts FROM source_ref.student_info
    UNION ALL SELECT 'student_info.studied_credits', studied_credits FROM source_ref.student_info
    UNION ALL SELECT 'student_registration.date_registration', date_registration FROM source_ref.student_registration
    UNION ALL SELECT 'student_registration.date_unregistration', date_unregistration FROM source_ref.student_registration
    UNION ALL SELECT 'assessments.date', date FROM source_ref.assessments
    UNION ALL SELECT 'assessments.weight', weight FROM source_ref.assessments
    UNION ALL SELECT 'student_assessment.score', score FROM source_ref.student_assessment
    UNION ALL SELECT 'student_assessment.date_submitted', date_submitted FROM source_ref.student_assessment
    UNION ALL SELECT 'vle.week_from', week_from FROM source_ref.vle
    UNION ALL SELECT 'vle.week_to', week_to FROM source_ref.vle
),
parsed AS (
    SELECT source_field, raw_value,
           CASE WHEN BTRIM(raw_value) ~ '^-?[0-9]+(\.[0-9]+)?$' THEN BTRIM(raw_value)::NUMERIC END AS numeric_value
    FROM numeric_values
)
SELECT source_field,
       COUNT(*)::BIGINT AS source_rows,
       COUNT(*) FILTER (WHERE raw_value IS NULL OR BTRIM(raw_value) = '')::BIGINT AS blank_or_null_rows,
       COUNT(*) FILTER (WHERE BTRIM(raw_value) = '?')::BIGINT AS question_mark_rows,
       COUNT(*) FILTER (WHERE raw_value IS NOT NULL AND BTRIM(raw_value) NOT IN ('', '?') AND numeric_value IS NULL)::BIGINT AS unparseable_rows,
       MIN(numeric_value) AS minimum_value,
       MAX(numeric_value) AS maximum_value,
       COUNT(DISTINCT numeric_value)::BIGINT AS distinct_numeric_values
FROM parsed
GROUP BY source_field
ORDER BY source_field;

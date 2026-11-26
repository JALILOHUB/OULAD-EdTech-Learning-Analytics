
-- [P3.02] Relative-day semantics and temporal boundaries
-- Question: How are negative, zero, and positive relative-day values distributed across all documented date fields, and what actual source rows illustrate the boundaries?
-- Expectation: Each field's parseable range and sign distribution is reported; samples retain the exact source value and linked presentation length.
-- Grain: Result set 1 = one row per temporal field; result set 2 = one row per representative source record.
-- Source: source_ref.student_vle, student_registration, assessments, student_assessment, courses.
-- Safety: READ-ONLY SELECT. No sign changes, clipping, calendar conversion, or row deletion.
-- Runtime: HIGH; student_vle requires a full scan. Run alone.
-- Read as: Negative values are documented relative offsets, not automatically errors. Day 0 is the presentation start. Calendar dates are not derivable without an exact authoritative start-date anchor.

-- 1. Relative-day distribution across all five source fields.
WITH temporal_values AS (
    SELECT 'student_vle.date'::TEXT AS source_field, date AS raw_value
    FROM source_ref.student_vle

    UNION ALL
    SELECT 'student_registration.date_registration', date_registration
    FROM source_ref.student_registration

    UNION ALL
    SELECT 'student_registration.date_unregistration', date_unregistration
    FROM source_ref.student_registration

    UNION ALL
    SELECT 'assessments.date', date
    FROM source_ref.assessments

    UNION ALL
    SELECT 'student_assessment.date_submitted', date_submitted
    FROM source_ref.student_assessment
),
parsed AS (
    SELECT
        source_field,
        raw_value,
        CASE
            WHEN BTRIM(raw_value) ~ '^-?[0-9]+$'
            THEN BTRIM(raw_value)::INTEGER
        END AS relative_day
    FROM temporal_values
)
SELECT
    source_field,
    COUNT(*)::BIGINT AS source_rows,
    COUNT(*) FILTER (
        WHERE raw_value IS NULL OR BTRIM(raw_value) = ''
    )::BIGINT AS blank_or_null_rows,
    COUNT(*) FILTER (
        WHERE BTRIM(raw_value) = '?'
    )::BIGINT AS question_mark_tokens,
    COUNT(*) FILTER (
        WHERE relative_day IS NULL
          AND raw_value IS NOT NULL
          AND BTRIM(raw_value) NOT IN ('', '?')
    )::BIGINT AS non_integer_tokens,
    COUNT(*) FILTER (
        WHERE relative_day < 0
    )::BIGINT AS negative_rows,
    COUNT(*) FILTER (
        WHERE relative_day = 0
    )::BIGINT AS day_zero_rows,
    COUNT(*) FILTER (
        WHERE relative_day > 0
    )::BIGINT AS positive_rows,
    MIN(relative_day) AS minimum_relative_day,
    MAX(relative_day) AS maximum_relative_day
FROM parsed
GROUP BY source_field
ORDER BY source_field;


-- 2. Representative VLE boundary rows.
-- Preserve source values and safely parse presentation length.
WITH courses_typed AS (
    SELECT
        code_module,
        code_presentation,
        module_presentation_length,
        CASE
            WHEN BTRIM(module_presentation_length) ~ '^[0-9]+$'
            THEN BTRIM(module_presentation_length)::INTEGER
        END AS module_length_days
    FROM source_ref.courses
),
vle_typed AS (
    SELECT
        v.code_module,
        v.code_presentation,
        v.id_student,
        v.id_site,
        v.date,
        v.sum_click,
        CASE
            WHEN BTRIM(v.date) ~ '^-?[0-9]+$'
            THEN BTRIM(v.date)::INTEGER
        END AS relative_day
    FROM source_ref.student_vle AS v
)
SELECT
    v.code_module,
    v.code_presentation,
    v.id_student,
    v.id_site,
    v.date AS source_relative_day,
    c.module_presentation_length,
    CASE
        WHEN v.relative_day IS NULL
            THEN 'UNPARSEABLE'
        WHEN v.relative_day < 0
            THEN 'PRE_START'
        WHEN v.relative_day = 0
            THEN 'START_DAY'
        WHEN c.module_length_days IS NULL
            THEN 'PRESENTATION_LENGTH_UNAVAILABLE'
        WHEN v.relative_day <= c.module_length_days
            THEN 'WITHIN_AN8_0_TO_L_CONVENTION'
        ELSE 'AFTER_AN8_0_TO_L_CONVENTION'
    END AS observed_temporal_state,
    v.sum_click
FROM vle_typed AS v
LEFT JOIN courses_typed AS c
    USING (code_module, code_presentation)
WHERE
    v.relative_day < 0
    OR (
        c.module_length_days IS NOT NULL
        AND v.relative_day > c.module_length_days
    )
ORDER BY
    v.code_module,
    v.code_presentation,
    v.id_student
LIMIT 200;


-- 3. Inspect presentation lengths and observed maximum offsets.
SELECT
    c.code_module,
    c.code_presentation,
    c.module_presentation_length,

    (
        SELECT MAX(BTRIM(v.date)::INTEGER)
        FROM source_ref.student_vle AS v
        WHERE v.code_module = c.code_module
          AND v.code_presentation = c.code_presentation
          AND BTRIM(v.date) ~ '^-?[0-9]+$'
    ) AS max_vle_relative_day,

    (
        SELECT MAX(BTRIM(a.date)::INTEGER)
        FROM source_ref.assessments AS a
        WHERE a.code_module = c.code_module
          AND a.code_presentation = c.code_presentation
          AND BTRIM(a.date) ~ '^-?[0-9]+$'
    ) AS max_assessment_due_relative_day

FROM source_ref.courses AS c
ORDER BY
    c.code_module,
    c.code_presentation;

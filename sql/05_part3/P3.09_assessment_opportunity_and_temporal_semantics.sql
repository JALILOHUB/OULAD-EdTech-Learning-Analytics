-- [P3.09] Assessment submission, transfer, deadline, and opportunity semantics
-- Question: Which assessment records represent transferred results, current-presentation submissions, negative/missing dates, and eligible assessment opportunities?
-- Expectation: Reconcile assessment catalogue, source records, banked results, negative dates, score states, enrollment timing, and candidate denominators without treating absent rows as confirmed non-submissions.
-- Grain: Result 1 = module-presentation and assessment-type catalogue; result 2 = one row per assessment/banked/date/score/timing state; result 3 = one row per date_submitted=-1 source record; result 4 = negative submission day by banked/score/type; result 5 = one row per assessment with known due day and opportunity/result reconciliation.
-- Source: source_ref.assessments, student_assessment, student_registration, student_info, courses.
-- Safety: READ-ONLY SELECT. No source changes, recoding, score imputation, or inferred due dates. Uses guarded TEXT parsing. No student_vle full-table scan.
-- Runtime: MEDIUM; assessment and registration relations only. Run alone and inspect every result set.
-- Read as: is_banked=1 means the result was transferred from a previous presentation. Such a row is not a current-presentation submission. A -1 date is not a valid current submission timestamp for timing metrics. Non-banked -1 and other negative dates require case-level review. Opportunity denominators are candidates, not approved KPIs.

-- 1. Assessment catalogue and weighting structure by presentation and assessment type.
WITH a AS (
    SELECT
        code_module,
        code_presentation,
        id_assessment,
        assessment_type,
        CASE WHEN BTRIM(date) ~ '^-?[0-9]+$' THEN BTRIM(date)::INTEGER END AS due_day,
        CASE WHEN BTRIM(weight) ~ '^-?[0-9]+(\.[0-9]+)?$' THEN BTRIM(weight)::NUMERIC END AS weight_value
    FROM source_ref.assessments
),
c AS (
    SELECT code_module, code_presentation,
           CASE WHEN BTRIM(module_presentation_length) ~ '^[0-9]+$'
                THEN BTRIM(module_presentation_length)::INTEGER END AS presentation_length
    FROM source_ref.courses
)
SELECT
    a.code_module,
    a.code_presentation,
    a.assessment_type,
    COUNT(*)::BIGINT AS assessment_items,
    COUNT(*) FILTER (WHERE due_day IS NOT NULL)::BIGINT AS assessments_with_known_due_day,
    COUNT(*) FILTER (WHERE due_day IS NULL)::BIGINT AS assessments_without_known_due_day,
    SUM(weight_value) AS total_assessment_weight,
    MIN(due_day) AS earliest_due_day,
    MAX(due_day) AS latest_due_day,
    MAX(c.presentation_length) AS presentation_length
FROM a
LEFT JOIN c USING (code_module, code_presentation)
GROUP BY a.code_module, a.code_presentation, a.assessment_type
ORDER BY a.code_module, a.code_presentation, a.assessment_type;

-- 2. Per-assessment record states: transfer, score, submission date, and deadline timing.
WITH a AS (
    SELECT id_assessment, code_module, code_presentation, assessment_type,
           CASE WHEN BTRIM(date) ~ '^-?[0-9]+$' THEN BTRIM(date)::INTEGER END AS due_day
    FROM source_ref.assessments
),
s AS (
    SELECT id_assessment, id_student, date_submitted, is_banked, score,
           CASE WHEN BTRIM(date_submitted) ~ '^-?[0-9]+$'
                THEN BTRIM(date_submitted)::INTEGER END AS submitted_day,
           CASE WHEN BTRIM(score) ~ '^-?[0-9]+(\.[0-9]+)?$'
                THEN BTRIM(score)::NUMERIC END AS score_value,
           CASE
             WHEN BTRIM(is_banked) = '1' THEN 'BANKED_TRANSFER'
             WHEN BTRIM(is_banked) = '0' THEN 'NOT_BANKED'
             ELSE 'UNKNOWN_BANKED_FLAG'
           END AS banked_state,
           CASE
             WHEN score IS NULL OR BTRIM(score) IN ('', '?') THEN 'MISSING_SCORE'
             WHEN BTRIM(score) ~ '^-?[0-9]+(\.[0-9]+)?$'
                  AND BTRIM(score)::NUMERIC = 0 THEN 'OBSERVED_ZERO_SCORE'
             WHEN BTRIM(score) ~ '^-?[0-9]+(\.[0-9]+)?$'
                  AND BTRIM(score)::NUMERIC BETWEEN 0 AND 100 THEN 'VALID_NONZERO_SCORE'
             WHEN BTRIM(score) ~ '^-?[0-9]+(\.[0-9]+)?$' THEN 'NUMERIC_OUTSIDE_0_100'
             ELSE 'UNPARSEABLE_SCORE'
           END AS score_state,
           CASE
             WHEN date_submitted IS NULL OR BTRIM(date_submitted) IN ('', '?') THEN 'MISSING_SUBMISSION_DAY'
             WHEN BTRIM(date_submitted) = '-1' THEN 'DAY_MINUS_ONE'
             WHEN BTRIM(date_submitted) ~ '^-?[0-9]+$'
                  AND BTRIM(date_submitted)::INTEGER < -1 THEN 'OTHER_NEGATIVE_DAY'
             WHEN BTRIM(date_submitted) ~ '^-?[0-9]+$'
                  AND BTRIM(date_submitted)::INTEGER = 0 THEN 'DAY_ZERO'
             WHEN BTRIM(date_submitted) ~ '^-?[0-9]+$' THEN 'POSITIVE_DAY'
             ELSE 'UNPARSEABLE_SUBMISSION_DAY'
           END AS submission_day_state
    FROM source_ref.student_assessment
)
SELECT
    a.code_module,
    a.code_presentation,
    a.assessment_type,
    a.id_assessment,
    s.banked_state,
    s.submission_day_state,
    s.score_state,
    CASE
      WHEN s.submitted_day IS NULL OR a.due_day IS NULL THEN 'TIMING_NOT_COMPARABLE'
      WHEN s.submitted_day < 0 THEN 'NEGATIVE_DAY_NOT_A_CURRENT_SUBMISSION_DATE'
      WHEN s.submitted_day < a.due_day THEN 'RECORDED_BEFORE_DEADLINE'
      WHEN s.submitted_day = a.due_day THEN 'RECORDED_ON_DEADLINE'
      ELSE 'RECORDED_AFTER_DEADLINE'
    END AS deadline_timing_state,
    COUNT(*)::BIGINT AS assessment_records,
    COUNT(DISTINCT s.id_student)::BIGINT AS distinct_students,
    MIN(s.submitted_day) AS minimum_submitted_day,
    MAX(s.submitted_day) AS maximum_submitted_day,
    MIN(s.score_value) AS minimum_numeric_score,
    MAX(s.score_value) AS maximum_numeric_score
FROM s
JOIN a USING (id_assessment)
GROUP BY
    a.code_module, a.code_presentation, a.assessment_type, a.id_assessment,
    s.banked_state, s.submission_day_state, s.score_state, deadline_timing_state
ORDER BY
    a.code_module, a.code_presentation, a.id_assessment,
    s.banked_state, s.submission_day_state, s.score_state;

-- 3. Case-level review of all -1 records with registration and outcome context.
WITH a AS (
    SELECT id_assessment, code_module, code_presentation, assessment_type, date AS due_day_raw,
           CASE WHEN BTRIM(date) ~ '^-?[0-9]+$' THEN BTRIM(date)::INTEGER END AS due_day
    FROM source_ref.assessments
),
r AS (
    SELECT id_student, code_module, code_presentation, date_registration, date_unregistration,
           CASE WHEN BTRIM(date_registration) ~ '^-?[0-9]+$'
                THEN BTRIM(date_registration)::INTEGER END AS registration_day,
           CASE WHEN BTRIM(date_unregistration) ~ '^-?[0-9]+$'
                THEN BTRIM(date_unregistration)::INTEGER END AS unregistration_day
    FROM source_ref.student_registration
),
c AS (
    SELECT code_module, code_presentation,
           CASE WHEN BTRIM(module_presentation_length) ~ '^[0-9]+$'
                THEN BTRIM(module_presentation_length)::INTEGER END AS presentation_length
    FROM source_ref.courses
)
SELECT
    sa.id_assessment,
    sa.id_student,
    a.code_module,
    a.code_presentation,
    a.assessment_type,
    a.due_day_raw,
    sa.date_submitted,
    sa.is_banked,
    sa.score,
    CASE
      WHEN sa.score IS NULL OR BTRIM(sa.score) IN ('', '?') THEN 'MISSING_SCORE'
      WHEN BTRIM(sa.score) ~ '^-?[0-9]+(\.[0-9]+)?$'
           AND BTRIM(sa.score)::NUMERIC = 0 THEN 'OBSERVED_ZERO_SCORE'
      WHEN BTRIM(sa.score) ~ '^-?[0-9]+(\.[0-9]+)?$'
           AND BTRIM(sa.score)::NUMERIC BETWEEN 0 AND 100 THEN 'VALID_NONZERO_SCORE'
      WHEN BTRIM(sa.score) ~ '^-?[0-9]+(\.[0-9]+)?$' THEN 'NUMERIC_OUTSIDE_0_100'
      ELSE 'UNPARSEABLE_SCORE'
    END AS score_state,
    r.date_registration,
    r.date_unregistration,
    r.registration_day,
    r.unregistration_day,
    c.presentation_length,
    i.num_of_prev_attempts,
    i.final_result,
    CASE
      WHEN BTRIM(sa.is_banked) = '1' THEN 'BANKED_TRANSFER'
      WHEN BTRIM(sa.is_banked) = '0' THEN 'NOT_BANKED'
      ELSE 'UNKNOWN_BANKED_FLAG'
    END AS banked_state,
    CASE
      WHEN r.registration_day IS NULL THEN 'REGISTRATION_DAY_UNKNOWN'
      WHEN a.due_day IS NULL THEN 'DUE_DAY_UNKNOWN'
      WHEN r.registration_day > a.due_day THEN 'REGISTERED_AFTER_DEADLINE'
      WHEN r.unregistration_day IS NOT NULL AND r.unregistration_day < a.due_day THEN 'WITHDREW_BEFORE_DEADLINE'
      WHEN r.unregistration_day = a.due_day THEN 'WITHDREW_ON_DEADLINE'
      ELSE 'REGISTERED_BY_DEADLINE_NO_PRIOR_WITHDRAWAL'
    END AS enrollment_at_deadline_state
FROM source_ref.student_assessment sa
JOIN a USING (id_assessment)
LEFT JOIN r
  ON r.id_student = sa.id_student
 AND r.code_module = a.code_module
 AND r.code_presentation = a.code_presentation
LEFT JOIN c USING (code_module, code_presentation)
LEFT JOIN source_ref.student_info i
  ON i.id_student = sa.id_student
 AND i.code_module = a.code_module
 AND i.code_presentation = a.code_presentation
WHERE BTRIM(sa.date_submitted) = '-1'
ORDER BY
    CASE WHEN BTRIM(sa.is_banked) = '0' THEN 0 ELSE 1 END,
    a.code_module, a.code_presentation, a.assessment_type, sa.id_assessment, sa.id_student;

-- 4. Every negative submission day, including values below -1, by transfer and score state.
WITH a AS (
    SELECT id_assessment, assessment_type
    FROM source_ref.assessments
),
s AS (
    SELECT id_assessment, id_student, date_submitted, is_banked, score,
           CASE WHEN BTRIM(date_submitted) ~ '^-?[0-9]+$'
                THEN BTRIM(date_submitted)::INTEGER END AS submitted_day,
           CASE
             WHEN score IS NULL OR BTRIM(score) IN ('', '?') THEN 'MISSING_SCORE'
             WHEN BTRIM(score) ~ '^-?[0-9]+(\.[0-9]+)?$'
                  AND BTRIM(score)::NUMERIC = 0 THEN 'OBSERVED_ZERO_SCORE'
             WHEN BTRIM(score) ~ '^-?[0-9]+(\.[0-9]+)?$'
                  AND BTRIM(score)::NUMERIC BETWEEN 0 AND 100 THEN 'VALID_NONZERO_SCORE'
             WHEN BTRIM(score) ~ '^-?[0-9]+(\.[0-9]+)?$' THEN 'NUMERIC_OUTSIDE_0_100'
             ELSE 'UNPARSEABLE_SCORE'
           END AS score_state
    FROM source_ref.student_assessment
)
SELECT
    a.assessment_type,
    s.submitted_day,
    CASE
      WHEN BTRIM(s.is_banked) = '1' THEN 'BANKED_TRANSFER'
      WHEN BTRIM(s.is_banked) = '0' THEN 'NOT_BANKED'
      ELSE 'UNKNOWN_BANKED_FLAG'
    END AS banked_state,
    s.score_state,
    COUNT(*)::BIGINT AS source_records,
    COUNT(DISTINCT s.id_assessment)::BIGINT AS assessment_items,
    COUNT(DISTINCT (s.id_assessment, s.id_student))::BIGINT AS distinct_assessment_student_pairs
FROM s
JOIN a USING (id_assessment)
WHERE s.submitted_day < 0
GROUP BY a.assessment_type, s.submitted_day, banked_state, s.score_state
ORDER BY a.assessment_type, s.submitted_day, banked_state, s.score_state;

-- 5. Candidate opportunity denominator by assessment with a known due day.
-- The on-deadline withdrawal state is separate; current result coverage is reconciled to enrollment states.
WITH a AS (
    SELECT id_assessment, code_module, code_presentation, assessment_type,
           CASE WHEN BTRIM(date) ~ '^-?[0-9]+$' THEN BTRIM(date)::INTEGER END AS due_day
    FROM source_ref.assessments
),
r AS (
    SELECT id_student, code_module, code_presentation, date_registration, date_unregistration,
           CASE WHEN BTRIM(date_registration) ~ '^-?[0-9]+$'
                THEN BTRIM(date_registration)::INTEGER END AS registration_day,
           CASE WHEN BTRIM(date_unregistration) ~ '^-?[0-9]+$'
                THEN BTRIM(date_unregistration)::INTEGER END AS unregistration_day,
           CASE WHEN date_unregistration IS NULL OR BTRIM(date_unregistration) IN ('', '?')
                THEN TRUE ELSE FALSE END AS no_recorded_unregistration
    FROM source_ref.student_registration
),
opportunity AS (
    SELECT
        a.id_assessment,
        COUNT(*) FILTER (
            WHERE r.registration_day IS NOT NULL
              AND r.registration_day <= a.due_day
              AND (r.no_recorded_unregistration OR r.unregistration_day > a.due_day)
        )::BIGINT AS candidate_opportunity_denominator,
        COUNT(*) FILTER (
            WHERE r.registration_day IS NOT NULL
              AND r.registration_day <= a.due_day
              AND r.unregistration_day = a.due_day
        )::BIGINT AS withdrawal_on_deadline,
        COUNT(*) FILTER (
            WHERE r.registration_day IS NOT NULL
              AND r.registration_day > a.due_day
        )::BIGINT AS registered_after_deadline,
        COUNT(*) FILTER (
            WHERE r.registration_day IS NOT NULL
              AND r.registration_day <= a.due_day
              AND r.unregistration_day < a.due_day
        )::BIGINT AS withdrawn_before_deadline,
        COUNT(*) FILTER (WHERE r.registration_day IS NULL)::BIGINT AS unknown_registration_day
    FROM a
    JOIN r USING (code_module, code_presentation)
    WHERE a.due_day IS NOT NULL
    GROUP BY a.id_assessment
),
recorded AS (
    SELECT
        sa.id_assessment,
        COUNT(*)::BIGINT AS all_recorded_result_rows,
        COUNT(*) FILTER (WHERE BTRIM(sa.is_banked) = '1')::BIGINT AS banked_result_rows,
        COUNT(*) FILTER (WHERE BTRIM(sa.is_banked) = '0')::BIGINT AS nonbanked_result_rows,
        COUNT(*) FILTER (
            WHERE BTRIM(sa.is_banked) = '0'
              AND BTRIM(sa.date_submitted) ~ '^[0-9]+$'
        )::BIGINT AS nonbanked_nonnegative_dated_rows,
        COUNT(*) FILTER (
            WHERE BTRIM(sa.is_banked) = '0'
              AND BTRIM(sa.date_submitted) = '-1'
        )::BIGINT AS nonbanked_minus_one_rows,
        COUNT(*) FILTER (
            WHERE BTRIM(sa.is_banked) = '0'
              AND r.registration_day IS NOT NULL
              AND r.registration_day <= a.due_day
              AND (r.no_recorded_unregistration OR r.unregistration_day > a.due_day)
        )::BIGINT AS nonbanked_results_from_candidate_eligible_students,
        COUNT(*) FILTER (
            WHERE BTRIM(sa.is_banked) = '0'
              AND r.registration_day IS NOT NULL
              AND r.unregistration_day = a.due_day
        )::BIGINT AS nonbanked_results_withdrawn_on_deadline,
        COUNT(*) FILTER (
            WHERE BTRIM(sa.is_banked) = '0'
              AND r.registration_day IS NOT NULL
              AND r.registration_day > a.due_day
        )::BIGINT AS nonbanked_results_registered_after_deadline,
        COUNT(*) FILTER (
            WHERE BTRIM(sa.is_banked) = '0'
              AND r.registration_day IS NOT NULL
              AND r.registration_day <= a.due_day
              AND r.unregistration_day < a.due_day
        )::BIGINT AS nonbanked_results_withdrawn_before_deadline,
        COUNT(*) FILTER (
            WHERE BTRIM(sa.is_banked) = '0'
              AND r.registration_day IS NULL
        )::BIGINT AS nonbanked_results_unknown_registration
    FROM source_ref.student_assessment sa
    JOIN a USING (id_assessment)
    LEFT JOIN r
      ON r.id_student = sa.id_student
     AND r.code_module = a.code_module
     AND r.code_presentation = a.code_presentation
    WHERE a.due_day IS NOT NULL
    GROUP BY sa.id_assessment
)
SELECT
    a.code_module,
    a.code_presentation,
    a.assessment_type,
    a.id_assessment,
    a.due_day,
    COALESCE(o.candidate_opportunity_denominator, 0)::BIGINT AS candidate_opportunity_denominator,
    COALESCE(o.withdrawal_on_deadline, 0)::BIGINT AS withdrawal_on_deadline_review,
    COALESCE(o.registered_after_deadline, 0)::BIGINT AS registered_after_deadline,
    COALESCE(o.withdrawn_before_deadline, 0)::BIGINT AS withdrawn_before_deadline,
    COALESCE(o.unknown_registration_day, 0)::BIGINT AS unknown_registration_day,
    COALESCE(s.all_recorded_result_rows, 0)::BIGINT AS all_recorded_result_rows,
    COALESCE(s.banked_result_rows, 0)::BIGINT AS banked_result_rows,
    COALESCE(s.nonbanked_result_rows, 0)::BIGINT AS nonbanked_result_rows,
    COALESCE(s.nonbanked_nonnegative_dated_rows, 0)::BIGINT AS nonbanked_nonnegative_dated_rows,
    COALESCE(s.nonbanked_minus_one_rows, 0)::BIGINT AS nonbanked_minus_one_rows,
    COALESCE(s.nonbanked_results_from_candidate_eligible_students, 0)::BIGINT
        AS nonbanked_results_from_candidate_eligible_students,
    COALESCE(s.nonbanked_results_withdrawn_on_deadline, 0)::BIGINT
        AS nonbanked_results_withdrawn_on_deadline,
    COALESCE(s.nonbanked_results_registered_after_deadline, 0)::BIGINT
        AS nonbanked_results_registered_after_deadline,
    COALESCE(s.nonbanked_results_withdrawn_before_deadline, 0)::BIGINT
        AS nonbanked_results_withdrawn_before_deadline,
    COALESCE(s.nonbanked_results_unknown_registration, 0)::BIGINT
        AS nonbanked_results_unknown_registration
FROM a
LEFT JOIN opportunity o USING (id_assessment)
LEFT JOIN recorded s USING (id_assessment)
WHERE a.due_day IS NOT NULL
ORDER BY a.code_module, a.code_presentation, a.assessment_type, a.id_assessment;

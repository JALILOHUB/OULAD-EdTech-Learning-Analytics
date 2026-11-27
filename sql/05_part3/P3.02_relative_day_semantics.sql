-- [P3.02] Relative-day semantics and temporal boundaries
-- Question: How are negative, zero, positive offsets distributed, and which source rows represent presentation boundaries?
-- Expectation: Sign/missing counts reconcile; examples are stratified by temporal state; presentation maxima are compared with recorded length.
-- Grain: Result 1 = one row per temporal field; result 2 = up to 25 rows per boundary state; result 3 = one row per module-presentation.
-- Source: source_ref.student_vle, student_registration, assessments, student_assessment, courses.
-- Safety: READ-ONLY SELECT. No sign changes, clipping, calendar conversion, or deletion.
-- Runtime: HIGH; student_vle scan. Run alone.
-- Read as: Day 0 is presentation start. Negative VLE offsets can represent pre-start access. Preserve day L as a distinct end boundary; no calendar dates without a verified start-date anchor. date_submitted=-1 remains unresolved.

-- 1. Relative-day distribution.
WITH temporal_values AS (
 SELECT 'student_vle.date'::TEXT source_field,date raw_value FROM source_ref.student_vle
 UNION ALL SELECT 'student_registration.date_registration',date_registration FROM source_ref.student_registration
 UNION ALL SELECT 'student_registration.date_unregistration',date_unregistration FROM source_ref.student_registration
 UNION ALL SELECT 'assessments.date',date FROM source_ref.assessments
 UNION ALL SELECT 'student_assessment.date_submitted',date_submitted FROM source_ref.student_assessment
), parsed AS (
 SELECT source_field,raw_value,CASE WHEN BTRIM(raw_value)~'^-?[0-9]+$' THEN BTRIM(raw_value)::INTEGER END relative_day FROM temporal_values
)
SELECT source_field,COUNT(*)::BIGINT source_rows,
 COUNT(*) FILTER(WHERE raw_value IS NULL OR BTRIM(raw_value)='')::BIGINT blank_or_null_rows,
 COUNT(*) FILTER(WHERE BTRIM(raw_value)='?')::BIGINT question_mark_tokens,
 COUNT(*) FILTER(WHERE relative_day IS NULL AND raw_value IS NOT NULL AND BTRIM(raw_value) NOT IN ('','?'))::BIGINT non_integer_tokens,
 COUNT(*) FILTER(WHERE relative_day<0)::BIGINT negative_rows,
 COUNT(*) FILTER(WHERE relative_day=0)::BIGINT day_zero_rows,
 COUNT(*) FILTER(WHERE relative_day>0)::BIGINT positive_rows,
 MIN(relative_day) minimum_relative_day,MAX(relative_day) maximum_relative_day
FROM parsed GROUP BY source_field ORDER BY source_field;

-- 2. Up to 25 original VLE rows per boundary state.
WITH c AS (
 SELECT code_module,code_presentation,module_presentation_length,
 CASE WHEN BTRIM(module_presentation_length)~'^[0-9]+$' THEN BTRIM(module_presentation_length)::INTEGER END length_days FROM source_ref.courses
), v AS (
 SELECT code_module,code_presentation,id_student,id_site,date,sum_click,
 CASE WHEN BTRIM(date)~'^-?[0-9]+$' THEN BTRIM(date)::INTEGER END relative_day FROM source_ref.student_vle
), classified AS (
 SELECT v.*,c.module_presentation_length,c.length_days,
 CASE WHEN relative_day IS NULL THEN 'UNPARSEABLE'
 WHEN relative_day<0 THEN 'PRE_START'
 WHEN relative_day=0 THEN 'START_DAY'
 WHEN length_days IS NULL THEN 'PRESENTATION_LENGTH_UNAVAILABLE'
 WHEN relative_day=length_days THEN 'PRESENTATION_END_BOUNDARY'
 WHEN relative_day>length_days THEN 'AFTER_LENGTH_BOUNDARY'
 ELSE 'WITHIN_PRESENTATION_INTERVAL' END observed_temporal_state
 FROM v LEFT JOIN c USING(code_module,code_presentation)
), ranked AS (
 SELECT *,ROW_NUMBER() OVER(PARTITION BY observed_temporal_state ORDER BY code_module,code_presentation,id_student,id_site,date) sample_rank
 FROM classified WHERE observed_temporal_state IN ('PRE_START','START_DAY','PRESENTATION_END_BOUNDARY','AFTER_LENGTH_BOUNDARY')
)
SELECT code_module,code_presentation,id_student,id_site,date source_relative_day,module_presentation_length,observed_temporal_state,sum_click
FROM ranked WHERE sample_rank<=25
ORDER BY CASE observed_temporal_state WHEN 'PRE_START' THEN 1 WHEN 'START_DAY' THEN 2 WHEN 'PRESENTATION_END_BOUNDARY' THEN 3 WHEN 'AFTER_LENGTH_BOUNDARY' THEN 4 ELSE 5 END,
code_module,code_presentation,id_student,id_site;

-- 3. Compare observed maxima to recorded presentation length.
WITH c AS (
 SELECT code_module,code_presentation,module_presentation_length,
 CASE WHEN BTRIM(module_presentation_length)~'^[0-9]+$' THEN BTRIM(module_presentation_length)::INTEGER END length_days FROM source_ref.courses
), vm AS (
 SELECT code_module,code_presentation,MAX(CASE WHEN BTRIM(date)~'^-?[0-9]+$' THEN BTRIM(date)::INTEGER END) max_vle_relative_day
 FROM source_ref.student_vle GROUP BY code_module,code_presentation
), am AS (
 SELECT code_module,code_presentation,MAX(CASE WHEN BTRIM(date)~'^-?[0-9]+$' THEN BTRIM(date)::INTEGER END) max_assessment_due_relative_day
 FROM source_ref.assessments GROUP BY code_module,code_presentation
)
SELECT c.code_module,c.code_presentation,c.module_presentation_length,vm.max_vle_relative_day,am.max_assessment_due_relative_day,
(vm.max_vle_relative_day=c.length_days) max_vle_at_length_boundary,
(vm.max_vle_relative_day>c.length_days) max_vle_after_length_boundary,
(am.max_assessment_due_relative_day>c.length_days) assessment_due_after_length_boundary
FROM c LEFT JOIN vm USING(code_module,code_presentation) LEFT JOIN am USING(code_module,code_presentation)
ORDER BY c.code_module,c.code_presentation;

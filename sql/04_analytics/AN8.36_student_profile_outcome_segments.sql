-- [AN8.36] Student profile and outcome segments
-- Question: How are retrospective outcomes distributed across observed student-profile categories and prior-study characteristics?
-- Expectation: Keep NULL IMD bands explicit and report within-segment denominators and outcome shares.
-- Grain: One row per module-presentation, profile dimension/value, and final_result.
-- Source: staging.student_info, staging.student_registration.
-- Safety: READ-ONLY SELECT. Demographic/profile associations are descriptive and must not be interpreted causally or as a fairness assessment.
-- Runtime: LOW; approximately 32.6K student-presentation rows.
-- Read as: Distinct people are not additive across presentations. Small cells require suppression/review before public reporting.

WITH profile AS (
 SELECT si.code_module,si.code_presentation,si.id_student,si.final_result,
        si.gender,si.region,si.highest_education,
        COALESCE(si.imd_band,'[NULL]') imd_band,
        si.age_band,si.disability,
        si.num_of_prev_attempts,si.studied_credits
 FROM staging.student_info si
 JOIN staging.student_registration r USING(code_module,code_presentation,id_student)
),
segments AS (
 SELECT code_module,code_presentation,final_result,'GENDER'::TEXT dimension,gender::TEXT segment_value FROM profile
 UNION ALL SELECT code_module,code_presentation,final_result,'REGION',region FROM profile
 UNION ALL SELECT code_module,code_presentation,final_result,'HIGHEST_EDUCATION',highest_education FROM profile
 UNION ALL SELECT code_module,code_presentation,final_result,'IMD_BAND',imd_band FROM profile
 UNION ALL SELECT code_module,code_presentation,final_result,'AGE_BAND',age_band FROM profile
 UNION ALL SELECT code_module,code_presentation,final_result,'DISABILITY',disability FROM profile
 UNION ALL SELECT code_module,code_presentation,final_result,'PREVIOUS_ATTEMPTS',num_of_prev_attempts::TEXT FROM profile
 UNION ALL SELECT code_module,code_presentation,final_result,'STUDIED_CREDITS',studied_credits::TEXT FROM profile
)
SELECT code_module,code_presentation,dimension,segment_value,final_result,
       COUNT(*)::BIGINT student_presentation_rows,
       ROUND(100.0*COUNT(*)/NULLIF(SUM(COUNT(*)) OVER
          (PARTITION BY code_module,code_presentation,dimension,segment_value),0),2) pct_within_segment
FROM segments
GROUP BY code_module,code_presentation,dimension,segment_value,final_result
ORDER BY code_module,code_presentation,dimension,segment_value,final_result;

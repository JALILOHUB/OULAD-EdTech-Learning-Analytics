-- Question: How much recorded activity falls before, within, and after course windows?
-- Expectation: Partition source activity rows by course-relative date.
-- Grain: One row per temporal bucket.
-- Source: staging.student_vle, staging.courses.
-- Safety: READ-ONLY SELECT; no row deletion or deduplication.
-- Runtime: HIGH; full scan. Run alone.
-- Read as: Course-relative windows do not establish registration-relative exposure.
SELECT CASE WHEN v.date<0 THEN 'PRE_COURSE' WHEN v.date<=c.module_presentation_length THEN 'IN_COURSE'
 ELSE 'POST_COURSE' END activity_window,COUNT(*)::BIGINT activity_rows,SUM(v.sum_click)::NUMERIC recorded_clicks
FROM staging.student_vle v JOIN staging.courses c USING(code_module,code_presentation) GROUP BY 1 ORDER BY 1;
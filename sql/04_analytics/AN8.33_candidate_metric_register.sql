-- [AN8.33] Candidate analytical metric register
-- Question: Which descriptive measures are available, what is their grain and denominator, and what limitations govern their use?
-- Expectation: Return a transparent register of candidate measures; none is approved as a KPI by this query.
-- Grain: One row per candidate measure.
-- Source: AN8 analytical definitions and validated STAGING field semantics.
-- Safety: READ-ONLY SELECT using a VALUES definition; no database objects are created.
-- Runtime: VERY LOW.
-- Read as: Candidate status is NOT_APPROVED until empirical validation, sensitivity review, and owner decision are documented.

SELECT * FROM (VALUES
 ('registered_student_presentations','COUNT(*)','student-presentation','All validated registration keys','Cohort size; not unique people','CANDIDATE_NOT_APPROVED'),
 ('in_course_activity_presence','has at least one source row in inclusive course window','student-presentation','All registered keys','No recorded row is not proof of no learning','CANDIDATE_NOT_APPROVED'),
 ('in_course_active_days','COUNT(DISTINCT date)','student-presentation','All registered keys including zero','Day-level; same-day event order unavailable','CANDIDATE_NOT_APPROVED'),
 ('in_course_resource_breadth','COUNT(DISTINCT id_site)','student-presentation','All registered keys including zero','Resource breadth is not learning quality','CANDIDATE_NOT_APPROVED'),
 ('post_registration_active_day_rate','active days / available exposure days','student-presentation','Known positive exposure only','Unknown/zero exposure must remain separate','CANDIDATE_NOT_APPROVED'),
 ('recorded_click_volume','SUM(sum_click)','student-presentation','All registered keys','Sensitive to repeated source rows; secondary diagnostic','CANDIDATE_NOT_APPROVED'),
 ('assessment_score','score','student-assessment','Observed non-NULL scores','Retrospective; availability time not established','CANDIDATE_NOT_APPROVED'),
 ('final_result','final_result','student-presentation','Validated student_info cohort','Outcome only; never an early predictor','OUTCOME_ONLY')
) AS metric_register(metric_id,operational_definition,grain,denominator,limitation,approval_status)
ORDER BY metric_id;

-- [AN8.33] Candidate measure register
-- Question: Which candidate measures have explicit definitions and approval status?
-- Expectation: All candidates remain NOT_APPROVED.
-- Grain: One row per candidate measure.
-- Source: Project metric definitions; no database source.
-- Safety: READ-ONLY SELECT.
-- Runtime: LOW.
-- Read as: This is a proposal register, not a production KPI table.
SELECT * FROM (VALUES
('recorded_clicks','SUM(sum_click)','Recorded platform click volume','R0 source rows','NOT_APPROVED'),
('activity_rows','COUNT(*)','Recorded activity-row volume','R0 source rows','NOT_APPROVED'),
('active_days','COUNT(DISTINCT date)','Temporal activity presence','Course-relative days','NOT_APPROVED'),
('active_day_rate','post-registration in-course active days / post-registration exposure days','Exposure-adjusted activity presence','Known positive post-registration exposure only','NOT_APPROVED'),
('resource_breadth','COUNT(DISTINCT id_site)','In-course and post-registration resource presence breadth','Not exposure-normalized','NOT_APPROVED')
) AS candidates(candidate_id,definition,interpretation,denominator_basis,approval_status);
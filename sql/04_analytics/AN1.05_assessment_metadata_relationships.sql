-- Question: Are assessment metadata keys unique, and do submissions join without fan-out?
-- Expectation: id_assessment is unique and each student_assessment row matches one metadata row.
-- Grain: One row for assessment-key diagnostics and one row for the submission-to-metadata join.
-- Source: staging.assessments, staging.student_assessment.
-- Safety: READ-ONLY; no persistent database changes.
-- Runtime: Low; scans 173,912 submission rows and 206 metadata rows.
-- Read as: joined_rows counts all LEFT JOIN output rows; matched_rows is reported separately. This supplements, but does not repeat, AN1.03's student-only join fan-out comparison.

-- 1. Separate physical metadata rows from distinct assessment identifiers.
WITH assessment_key_groups AS (
    SELECT id_assessment, COUNT(*)::BIGINT AS group_rows
    FROM staging.assessments
    GROUP BY id_assessment
),
assessment_key_summary AS (
    SELECT (SELECT COUNT(*) FROM staging.assessments)::BIGINT AS assessment_source_rows,
           COUNT(*)::BIGINT AS distinct_assessment_ids,
           COUNT(*) FILTER (WHERE group_rows > 1)::BIGINT AS duplicate_key_groups,
           COALESCE(SUM(group_rows - 1) FILTER (WHERE group_rows > 1), 0)::BIGINT AS duplicate_excess_rows
    FROM assessment_key_groups
),
submission_summary AS (
    SELECT COUNT(*)::BIGINT AS submission_rows,
           COUNT(a.id_assessment)::BIGINT AS matched_submission_rows,
           COUNT(*) FILTER (WHERE a.id_assessment IS NULL)::BIGINT AS unmatched_submission_rows,
           COUNT(*)::BIGINT AS joined_rows
    FROM staging.student_assessment AS sa
    LEFT JOIN staging.assessments AS a ON a.id_assessment = sa.id_assessment
)
SELECT 'ASSESSMENT_KEY'::TEXT AS diagnostic,
       k.assessment_source_rows AS source_rows,
       k.distinct_assessment_ids,
       NULL::BIGINT AS matched_rows,
       NULL::BIGINT AS unmatched_rows,
       k.duplicate_key_groups,
       k.duplicate_excess_rows,
       NULL::BIGINT AS joined_rows,
       NULL::NUMERIC AS join_multiplier
FROM assessment_key_summary AS k
UNION ALL
SELECT 'SUBMISSION_JOIN', s.submission_rows, NULL::BIGINT,
       s.matched_submission_rows, s.unmatched_submission_rows,
       NULL::BIGINT, NULL::BIGINT, s.joined_rows,
       ROUND(s.joined_rows::NUMERIC / NULLIF(s.submission_rows, 0), 4)
FROM submission_summary AS s
ORDER BY diagnostic;

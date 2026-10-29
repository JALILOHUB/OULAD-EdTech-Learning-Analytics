-- Question: What is the current state of the existing quality registry?
-- Expectation: The historical baseline is 29 records and 29 distinct test codes, with 25 PASS, 4 REVIEW, and 0 FAIL.
-- Grain: One row per registry summary metric.
-- Source: quality.test_results.
-- Safety: READ-ONLY
-- Runtime: Very low; reads the small registry.
-- Read as: Compare current values with the documented historical baseline; do not rerun or reseed quality tests.

-- 1. Summarize registry volume, status counts, duplicate test codes, and missing historical execution timestamps.
WITH summary AS (
    SELECT COUNT(*)::BIGINT AS registry_rows,
           COUNT(DISTINCT test_code)::BIGINT AS distinct_test_codes,
           COUNT(*) FILTER (WHERE status = 'PASS')::BIGINT AS pass_rows,
           COUNT(*) FILTER (WHERE status = 'REVIEW')::BIGINT AS review_rows,
           COUNT(*) FILTER (WHERE status = 'FAIL')::BIGINT AS fail_rows,
           COUNT(*) FILTER (WHERE executed_at IS NULL)::BIGINT AS null_executed_at_rows
    FROM quality.test_results
)
SELECT metric_name, metric_value
FROM summary
CROSS JOIN LATERAL (
    VALUES
        ('registry_rows', registry_rows),
        ('distinct_test_codes', distinct_test_codes),
        ('pass_rows', pass_rows),
        ('review_rows', review_rows),
        ('fail_rows', fail_rows),
        ('null_executed_at_rows', null_executed_at_rows),
        ('duplicate_test_code_excess', registry_rows - distinct_test_codes)
) AS metrics(metric_name, metric_value)
ORDER BY metric_name;

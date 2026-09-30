-- Purpose:
-- Template for data-quality checks.
-- Add one check at a time after the official table structure is verified.

-- Example pattern:
-- SELECT
--     COUNT(*) AS total_rows,
--     COUNT(*) FILTER (WHERE some_column IS NULL) AS null_rows
-- FROM raw.some_table;

-- Interpretation must be written in the corresponding notebook.

-- Purpose: Create a reusable registry for validated data-quality findings.
-- Safe to run more than once because the table is created only when absent.

CREATE TABLE IF NOT EXISTS quality.test_results (
    test_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    test_code TEXT NOT NULL,
    table_name TEXT NOT NULL,
    test_description TEXT NOT NULL,
    expected_result TEXT,
    actual_result TEXT,
    failed_rows BIGINT,
    status TEXT NOT NULL CHECK (status IN ('PASS', 'REVIEW', 'FAIL')),
    executed_at TIMESTAMPTZ,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

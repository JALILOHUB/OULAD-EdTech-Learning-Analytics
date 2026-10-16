# Tests

The SQL data-quality checks for the current RAW/STAGING phase are stored under `sql/02_quality/` and `sql/03_staging/`. This folder is reserved for reusable automated checks where they add value beyond the canonical SQL checks.

Potential future automated checks include:

- row-count reconciliation;
- expected schema and data-type checks;
- uniqueness and relationship constraints;
- accepted-value and range checks;
- NULL/missing-token reconciliation;
- analytical metric reconciliation.

Avoid duplicating an existing SQL test in Python without a specific reason. Any automated test should document its purpose, expected result, actual result, and failure behavior.

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


## Analytics database runner tests

`test_analytics_db_runner.py` contains synthetic unit tests for the read-only SQL runner. It checks legacy single-result compatibility, multiple result sets, per-result display caps, non-result statements, empty SQL rejection, and connection cleanup. These tests use mocked connection/cursor behavior and do not connect to PostgreSQL or validate the SQL files against the OULAD database.

Run locally from the repository root with:

```powershell
python -m unittest discover -s tests -p "test_*.py" -v
```

A passing synthetic test suite validates the tested Python control flow only. It does not establish live database behavior or execute WO-2 analytical queries.

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


## PostgreSQL integration test

`test_analytics_db_runner_postgres.py` adds a separate integration test for the actual pinned Psycopg version against a disposable PostgreSQL 18 service. It sends three SELECT statements in one SQL file, verifies all result sets and statement ordering, and confirms that the session is read-only.

The integration test is skipped unless `OULAD_TEST_DATABASE_URL` is set. The GitHub Actions workflow supplies credentials only for its disposable `oulad_runner_test` service. The test asserts that `DB_NAME` is exactly `oulad_runner_test`; it does not connect to `oulad_analytics`, inspect OULAD source tables, or perform data-changing statements.

The unit tests use mocked cursor/connection objects. The integration test exercises Psycopg and PostgreSQL themselves. Passing both is required before considering the runner validated for the next stage.

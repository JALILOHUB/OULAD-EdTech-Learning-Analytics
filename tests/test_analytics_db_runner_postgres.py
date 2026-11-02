"""PostgreSQL integration test for Psycopg multi-result execution.

This test uses a dedicated disposable test database and SELECT statements only.
It is skipped unless OULAD_TEST_DATABASE_URL is set by the test environment.
"""

from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path

from src.analytics import db


@unittest.skipUnless(
    os.getenv("OULAD_TEST_DATABASE_URL"),
    "Set OULAD_TEST_DATABASE_URL to enable the isolated PostgreSQL integration test.",
)
class PsycopgMultiStatementIntegrationTests(unittest.TestCase):
    def test_multiple_select_results_use_read_only_postgresql_session(self):
        # Guard against accidentally pointing this integration test at the project DB.
        self.assertEqual(os.getenv("DB_NAME"), "oulad_runner_test")

        with tempfile.TemporaryDirectory() as directory:
            sql_path = Path(directory) / "AN0.07_integration_test.sql"
            sql_path.write_text(
                "SELECT 1 AS first_value;\n"
                "SELECT current_setting('transaction_read_only') AS read_only_state;\n"
                "SELECT 3 AS third_value;\n",
                encoding="utf-8",
            )

            from unittest.mock import patch

            with patch.object(db, "_resolve_query_file", return_value=sql_path):
                result = db.run_query(
                    "AN0.07",
                    max_rows=10,
                    statement_timeout_ms=5000,
                )

        self.assertEqual(result["result_set_count"], 3)
        self.assertEqual(
            [item["statement_number"] for item in result["result_sets"]],
            [1, 2, 3],
        )
        self.assertEqual(result["result_sets"][0]["data"]["first_value"].tolist(), [1])
        self.assertEqual(
            result["result_sets"][1]["data"]["read_only_state"].tolist(),
            ["on"],
        )
        self.assertEqual(result["result_sets"][2]["data"]["third_value"].tolist(), [3])


if __name__ == "__main__":
    unittest.main()

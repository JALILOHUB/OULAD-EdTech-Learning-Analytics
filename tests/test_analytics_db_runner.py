"""Synthetic unit tests for the read-only PostgreSQL query runner."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from src.analytics import db


class MultiResultCursor:
    """Small cursor double that models Psycopg's nextset() contract."""

    def __init__(self, result_sets):
        self.result_sets = list(result_sets)
        self.index = -1
        self.description = None
        self.executed_sql = None
        self.executed_kwargs = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def execute(self, sql, **kwargs):
        self.executed_sql = sql
        self.executed_kwargs = kwargs
        self.index = 0
        self._activate()

    def _activate(self):
        if self.index < len(self.result_sets):
            rows, columns = self.result_sets[self.index]
            self.description = (
                [SimpleNamespace(name=name) for name in columns]
                if columns is not None
                else None
            )
            self._rows = rows
        else:
            self.description = None
            self._rows = []

    def fetchmany(self, size):
        return self._rows[:size]

    def nextset(self):
        self.index += 1
        if self.index >= len(self.result_sets):
            self.description = None
            return None
        self._activate()
        return True


class RunQueryTests(unittest.TestCase):
    def _run_with_results(self, result_sets, max_rows=10):
        cursor = MultiResultCursor(result_sets)
        connection = MagicMock()
        connection.cursor.return_value.__enter__.return_value = cursor
        connection.cursor.return_value.__exit__.return_value = False

        with tempfile.TemporaryDirectory() as directory:
            sql_path = Path(directory) / "AN0.07_test.sql"
            sql_path.write_text("-- synthetic SQL; do not connect to a database\nSELECT 1;", encoding="utf-8")
            with (
                patch.object(db, "_resolve_query_file", return_value=sql_path),
                patch.object(db, "connect_read_only", return_value=connection),
            ):
                result = db.run_query("AN0.07", max_rows=max_rows)
        return result, cursor, connection

    def test_single_result_preserves_legacy_keys(self):
        result, cursor, connection = self._run_with_results(
            [([(1,), (2,)], ["value"])]
        )

        self.assertEqual(result["data"]["value"].tolist(), [1, 2])
        self.assertEqual(result["rows_displayed"], 2)
        self.assertFalse(result["display_truncated"])
        self.assertEqual(result["result_set_count"], 1)
        self.assertEqual(result["result_sets"][0]["statement_number"], 1)
        self.assertIn("elapsed_seconds", result)
        self.assertEqual(cursor.executed_kwargs, {"prepare": False})
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()

    def test_multiple_result_sets_are_all_returned_and_capped(self):
        result, _, _ = self._run_with_results(
            [
                ([(1,), (2,), (3,)], ["first_value"]),
                ([(10,), (20,)], ["second_value"]),
                ([(99,)], ["third_value"]),
            ],
            max_rows=2,
        )

        self.assertEqual(result["result_set_count"], 3)
        self.assertEqual(
            [item["statement_number"] for item in result["result_sets"]],
            [1, 2, 3],
        )
        self.assertEqual(result["result_sets"][0]["data"]["first_value"].tolist(), [1, 2])
        self.assertTrue(result["result_sets"][0]["display_truncated"])
        self.assertEqual(result["result_sets"][1]["data"]["second_value"].tolist(), [10, 20])
        self.assertFalse(result["result_sets"][1]["display_truncated"])
        self.assertEqual(result["result_sets"][2]["data"]["third_value"].tolist(), [99])
        self.assertEqual(result["data"]["first_value"].tolist(), [1, 2])

    def test_non_result_statement_does_not_create_a_result_set(self):
        result, _, _ = self._run_with_results(
            [
                ([], None),
                ([(7,)], ["value"]),
            ]
        )

        self.assertEqual(result["result_set_count"], 1)
        self.assertEqual(result["result_sets"][0]["statement_number"], 2)
        self.assertEqual(result["data"]["value"].tolist(), [7])

    def test_empty_sql_file_is_rejected_before_connection(self):
        with tempfile.TemporaryDirectory() as directory:
            sql_path = Path(directory) / "AN0.07_test.sql"
            sql_path.write_text("  -- blank file\n  ", encoding="utf-8")
            with (
                patch.object(db, "_resolve_query_file", return_value=sql_path),
                patch.object(db, "connect_read_only") as connect,
            ):
                with self.assertRaisesRegex(ValueError, "empty SQL file"):
                    db.run_query("AN0.07")
            connect.assert_not_called()


if __name__ == "__main__":
    unittest.main()

"""Read-only PostgreSQL query runner for canonical OULAD SQL analytics files."""

from __future__ import annotations

import os
import re
import time
from pathlib import Path
from typing import Any

import pandas as pd
import psycopg
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[2]
ANALYTICS_SQL_DIR = PROJECT_ROOT / "sql" / "04_analytics"
_QUERY_ID_PATTERN = re.compile(r"^AN\d+\.\d+$")


def _validate_statement_timeout_ms(statement_timeout_ms: int) -> int:
    """Validate a positive integer statement timeout in milliseconds."""
    if isinstance(statement_timeout_ms, bool) or not isinstance(statement_timeout_ms, int):
        raise ValueError("statement_timeout_ms must be a positive integer.")
    if statement_timeout_ms < 1:
        raise ValueError("statement_timeout_ms must be a positive integer.")
    return statement_timeout_ms


def connect_read_only(statement_timeout_ms: int = 120000) -> psycopg.Connection:
    """Open a read-only PostgreSQL session with a validated statement timeout."""
    statement_timeout_ms = _validate_statement_timeout_ms(statement_timeout_ms)
    load_dotenv(PROJECT_ROOT / ".env", override=False)

    password = os.getenv("DB_PASSWORD")
    if not password or password == "CHANGE_ME":
        raise RuntimeError(
            "DB_PASSWORD is missing or still set to CHANGE_ME. "
            "Copy .env.example to .env and configure local credentials."
        )

    connection = psycopg.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "oulad_analytics"),
        user=os.getenv("DB_USER", "postgres"),
        password=password,
        options=(
            "-c default_transaction_read_only=on "
            f"-c statement_timeout={statement_timeout_ms} "
            "-c lock_timeout=5000"
        ),
    )

    try:
        with connection.cursor() as cursor:
            cursor.execute("SHOW transaction_read_only")
            read_only = cursor.fetchone()[0]
        if read_only.lower() != "on":
            raise RuntimeError("The PostgreSQL session is not read-only.")
    except Exception:
        connection.close()
        raise

    return connection


def _resolve_query_file(query_id: str) -> Path:
    """Resolve one canonical SQL file from its stable work-order ID."""
    if not _QUERY_ID_PATTERN.fullmatch(query_id):
        raise ValueError("Use a query ID such as AN0.01 or AN1.03.")

    matches = sorted(ANALYTICS_SQL_DIR.glob(f"{query_id}_*.sql"))
    if len(matches) != 1:
        raise FileNotFoundError(
            f"Expected exactly one SQL file for {query_id}; found {len(matches)}."
        )
    return matches[0]


def _read_result_set(
    cursor: psycopg.Cursor,
    *,
    statement_number: int,
    max_rows: int,
) -> dict[str, Any]:
    """Fetch one cursor result without loading more than max_rows + 1 rows."""
    columns = [column.name for column in cursor.description]
    fetched = cursor.fetchmany(max_rows + 1)
    truncated = len(fetched) > max_rows
    visible_rows = fetched[:max_rows]
    frame = pd.DataFrame(visible_rows, columns=columns)

    return {
        "statement_number": statement_number,
        "data": frame,
        "rows_displayed": len(frame),
        "display_truncated": truncated,
        # Psycopg's multi-statement simple-query batch does not expose reliable
        # per-statement server timings. The batch duration is recorded at query level.
        "execution_time_seconds": None,
    }


def run_query(
    query_id: str,
    max_rows: int = 500,
    *,
    statement_timeout_ms: int = 120000,
) -> dict[str, Any]:
    """Execute a canonical read-only SQL file and return all result sets.

    SQL files are sent as one unparameterized multi-statement command. Psycopg's
    nextset() API advances through returned results; SQL is never split on semicolons.
    Legacy keys (data, rows_displayed, display_truncated, elapsed_seconds) remain
    available and refer to the first returned result set.
    """
    if isinstance(max_rows, bool) or not isinstance(max_rows, int) or max_rows < 1:
        raise ValueError("max_rows must be a positive integer.")
    statement_timeout_ms = _validate_statement_timeout_ms(statement_timeout_ms)

    query_path = _resolve_query_file(query_id)
    sql_text = query_path.read_text(encoding="utf-8")
    if not sql_text.strip():
        raise ValueError(f"{query_id} contains an empty SQL file.")

    connection = connect_read_only(statement_timeout_ms=statement_timeout_ms)
    started = time.perf_counter()

    try:
        result_sets: list[dict[str, Any]] = []
        statement_number = 1

        with connection.cursor() as cursor:
            # No parameters are supplied; prepare=False disables statement
            # preparation. Psycopg supports multiple statements in this form.
            # nextset() advances through their results. Do not split SQL in Python.
            cursor.execute(sql_text, prepare=False)

            while True:
                if cursor.description is not None:
                    result_sets.append(
                        _read_result_set(
                            cursor,
                            statement_number=statement_number,
                            max_rows=max_rows,
                        )
                    )

                if not cursor.nextset():
                    break
                statement_number += 1

        elapsed = round(time.perf_counter() - started, 3)
        if not result_sets:
            raise RuntimeError(
                f"{query_id} returned no result sets. "
                "Analytics work-order SQL files must return SELECT results."
            )

        first = result_sets[0]
        return {
            "query_id": query_id,
            "query_file": str(query_path.relative_to(PROJECT_ROOT)),
            # Backward-compatible first-result aliases.
            "data": first["data"],
            "rows_displayed": first["rows_displayed"],
            "display_truncated": first["display_truncated"],
            "elapsed_seconds": elapsed,
            # Complete multi-result representation.
            "result_sets": result_sets,
            "result_set_count": len(result_sets),
            "max_rows": max_rows,
            "statement_timeout_ms": statement_timeout_ms,
            "execution_time_scope": (
                "elapsed_seconds is the total SQL-file batch duration; "
                "per-statement server execution times are not exposed by this API."
            ),
        }
    finally:
        connection.rollback()
        connection.close()

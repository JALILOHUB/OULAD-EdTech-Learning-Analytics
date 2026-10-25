"""Read-only PostgreSQL query runner for the OULAD SQL analytics notebook."""

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


def connect_read_only() -> psycopg.Connection:
    """Open a local PostgreSQL session configured for read-only analytical work."""
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
            "-c statement_timeout=120000 "
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


def run_query(query_id: str, max_rows: int = 500) -> dict[str, Any]:
    """Execute one canonical SELECT and return a capped DataFrame plus metadata."""
    if not isinstance(max_rows, int) or max_rows < 1:
        raise ValueError("max_rows must be a positive integer.")

    query_path = _resolve_query_file(query_id)
    sql_text = query_path.read_text(encoding="utf-8")

    connection = connect_read_only()
    started = time.perf_counter()

    try:
        with connection.cursor() as cursor:
            cursor.execute(sql_text)
            if cursor.description is None:
                raise RuntimeError(
                    f"{query_id} did not return a result set. "
                    "Analytics work-order SQL files must return one SELECT result."
                )

            columns = [column.name for column in cursor.description]
            fetched = cursor.fetchmany(max_rows + 1)
            truncated = len(fetched) > max_rows
            visible_rows = fetched[:max_rows]
            frame = pd.DataFrame(visible_rows, columns=columns)

        elapsed = round(time.perf_counter() - started, 3)
        return {
            "query_id": query_id,
            "query_file": str(query_path.relative_to(PROJECT_ROOT)),
            "data": frame,
            "elapsed_seconds": elapsed,
            "rows_displayed": len(frame),
            "display_truncated": truncated,
            "max_rows": max_rows,
        }
    finally:
        connection.rollback()
        connection.close()

"""Run one canonical, read-only AN8 Part 3 diagnostic against oulad_an8_work."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql" / "05_part3"
OUTPUT_ROOT = ROOT / "outputs" / "an8" / "part3"
TARGET_DATABASE = "oulad_an8_work"
QUERY_PATTERN = re.compile(r"^P3\.0[0-8]$")
FETCH_SIZE = 10_000


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def resolve_query(query_id: str) -> Path:
    if not QUERY_PATTERN.fullmatch(query_id):
        raise ValueError("Use one query ID from P3.00 through P3.08.")
    matches = sorted(SQL_DIR.glob(f"{query_id}_*.sql"))
    if len(matches) != 1:
        raise FileNotFoundError(
            f"Expected exactly one SQL file for {query_id}; found {len(matches)}."
        )
    return matches[0]


def connect_read_only(statement_timeout_ms: int) -> tuple[psycopg.Connection, dict[str, Any]]:
    load_dotenv(ROOT / ".env", override=False)
    password = os.getenv("DB_PASSWORD")
    if not password or password == "CHANGE_ME":
        raise RuntimeError("DB_PASSWORD is missing or still set to CHANGE_ME.")

    options = (
        "-c default_transaction_read_only=on "
        f"-c statement_timeout={statement_timeout_ms} "
        "-c lock_timeout=5000"
    )
    connection = psycopg.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=TARGET_DATABASE,
        user=os.getenv("DB_USER", "postgres"),
        password=password,
        options=options,
        autocommit=False,
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT current_database(), version(), current_user, "
                "current_setting('transaction_read_only')"
            )
            database, version, user, read_only = cursor.fetchone()
        if database != TARGET_DATABASE:
            raise RuntimeError(
                f"Safety stop: connected to {database}, not {TARGET_DATABASE}."
            )
        if str(read_only).lower() != "on":
            raise RuntimeError("Safety stop: PostgreSQL transaction is not read-only.")
        identity = {
            "database": database,
            "postgresql_version": version,
            "user": user,
            "transaction_read_only": read_only,
        }
        return connection, identity
    except Exception:
        connection.close()
        raise


def export_result_set(
    cursor: psycopg.Cursor, output_path: Path, result_set_number: int
) -> dict[str, Any]:
    columns = [column.name for column in cursor.description]
    row_count = 0
    with output_path.open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(columns)
        while True:
            rows = cursor.fetchmany(FETCH_SIZE)
            if not rows:
                break
            writer.writerows(rows)
            row_count += len(rows)

    return {
        "result_set": result_set_number,
        "file": output_path.name,
        "rows": row_count,
        "columns": columns,
        "sha256": sha256_file(output_path),
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Execute exactly one read-only Part 3 SQL diagnostic."
    )
    parser.add_argument("--query", required=True, help="One ID: P3.00 through P3.08")
    parser.add_argument(
        "--statement-timeout-ms",
        type=int,
        default=900_000,
        help="Per-statement timeout in milliseconds (default: 900000; use 0 for no timeout).",
    )
    args = parser.parse_args()

    if args.statement_timeout_ms < 0:
        raise ValueError("statement-timeout-ms must be zero or a positive integer.")

    query_path = resolve_query(args.query)
    sql_text = query_path.read_text(encoding="utf-8")
    if not sql_text.strip():
        raise ValueError(f"{args.query} contains an empty SQL file.")

    run_stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    output_dir = OUTPUT_ROOT / run_stamp / args.query
    output_dir.mkdir(parents=True, exist_ok=False)

    connection, identity = connect_read_only(args.statement_timeout_ms)
    started = time.perf_counter()
    result_sets: list[dict[str, Any]] = []

    try:
        with connection.cursor() as cursor:
            cursor.execute(sql_text, prepare=False)
            statement_number = 0
            while True:
                if cursor.description is not None:
                    statement_number += 1
                    output_path = output_dir / f"result_set_{statement_number:02d}.csv"
                    result_sets.append(
                        export_result_set(cursor, output_path, statement_number)
                    )
                if not cursor.nextset():
                    break

        if not result_sets:
            raise RuntimeError(
                f"{args.query} returned no tabular result sets; expected SELECT output."
            )

        elapsed = round(time.perf_counter() - started, 3)
        connection.rollback()
        manifest = {
            "query_id": args.query,
            "query_file": str(query_path.relative_to(ROOT)).replace("\\", "/"),
            "query_sha256": sha256_file(query_path),
            "executed_at_utc": datetime.now(timezone.utc).isoformat(),
            "elapsed_seconds": elapsed,
            "database": identity,
            "statement_timeout_ms": args.statement_timeout_ms,
            "result_set_count": len(result_sets),
            "result_sets": result_sets,
            "read_only": True,
            "source_data_modified": False,
        }
        manifest_path = output_dir / "execution_manifest.json"
        manifest_path.write_text(
            json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

        print(f"Query: {args.query}")
        print(f"Database: {identity['database']}")
        print(f"Read-only: {identity['transaction_read_only']}")
        print(f"Elapsed seconds: {elapsed}")
        for item in result_sets:
            print(
                f"Result set {item['result_set']}: {item['rows']:,} rows "
                f"-> {item['file']}"
            )
        print(f"Manifest: {manifest_path.relative_to(ROOT)}")
        print("READ-ONLY EXECUTION COMPLETED. No source or database data was modified.")
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


if __name__ == "__main__":
    main()

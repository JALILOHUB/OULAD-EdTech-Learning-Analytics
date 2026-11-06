"""Execute the five canonical AN5 read-only SQL investigations.

Run from the repository root:
    python scripts/run_an5.py
    python scripts/run_an5.py --query AN5.01
    python scripts/run_an5.py --query AN5.04 --query AN5.05 --export-dir outputs/an5

The script uses the shared PostgreSQL runner. SQL remains canonical under
sql/04_analytics/. Each query opens its own read-only connection.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys
from typing import Iterable

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.analytics.db import run_query

AN5_QUERY_IDS = ("AN5.01", "AN5.02", "AN5.03", "AN5.04", "AN5.05")
EXPECTED_RESULT_SET_COUNTS = {
    "AN5.01": 3,
    "AN5.02": 1,
    "AN5.03": 1,
    "AN5.04": 1,
    "AN5.05": 2,
}
AN5_STATEMENT_TIMEOUT_MS = 600_000


def verify_read_only_preflight() -> dict:
    """Verify database identity and read-only settings using canonical AN0.01."""
    result = run_query("AN0.01", max_rows=10, statement_timeout_ms=120_000)
    if result["result_set_count"] != 1 or result["data"].empty:
        raise RuntimeError("AN0.01 preflight returned an unexpected result shape.")

    row = result["data"].iloc[0]
    checks = {
        "database_name": row["database_name"] == "oulad_analytics",
        "transaction_read_only": str(row["transaction_read_only"]).lower() == "on",
        "default_transaction_read_only": (
            str(row["default_transaction_read_only"]).lower() == "on"
        ),
    }
    print("AN5 read-only preflight:", checks)
    if not all(checks.values()):
        raise RuntimeError(
            "AN5 preflight failed. Stop; no AN5 analytical query was executed."
        )
    return result


def run_an5_query(query_id: str, *, max_rows: int = 500) -> dict:
    """Execute one canonical AN5 query and validate its result-set shape."""
    if query_id not in EXPECTED_RESULT_SET_COUNTS:
        raise ValueError(f"Unsupported AN5 query ID: {query_id}")

    result = run_query(
        query_id,
        max_rows=max_rows,
        statement_timeout_ms=AN5_STATEMENT_TIMEOUT_MS,
    )
    expected = EXPECTED_RESULT_SET_COUNTS[query_id]
    if result["result_set_count"] != expected:
        raise RuntimeError(
            f"{query_id} returned {result['result_set_count']} result sets; "
            f"expected {expected}. Stop and inspect the SQL definition."
        )
    return result


def _display_result(query_id: str, result: dict) -> None:
    """Print bounded result sets and execution metadata without hiding truncation."""
    print(
        f"\n{query_id} | {result['query_file']} | "
        f"{result['elapsed_seconds']} seconds | "
        f"{result['result_set_count']} result set(s)"
    )
    for item in result["result_sets"]:
        print(
            f"\nResult set {item['statement_number']}: "
            f"{item['rows_displayed']} displayed row(s); "
            f"truncated={item['display_truncated']}"
        )
        print(item["data"].to_string(index=False))


def _export_results(results: dict[str, dict], output_dir: Path) -> Path:
    """Export bounded result sets and a non-sensitive execution manifest."""
    output_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "database_name": "oulad_analytics",
        "read_only_preflight_passed": True,
        "queries": [],
    }
    for query_id, result in results.items():
        query_record = {
            "query_id": query_id,
            "query_file": result["query_file"],
            "elapsed_seconds": result["elapsed_seconds"],
            "statement_timeout_ms": result["statement_timeout_ms"],
            "result_set_count": result["result_set_count"],
            "result_sets": [],
        }
        for item in result["result_sets"]:
            filename = f"{query_id.replace('.', '_')}_result_{item['statement_number']:02d}.csv"
            item["data"].to_csv(output_dir / filename, index=False)
            query_record["result_sets"].append(
                {
                    "statement_number": item["statement_number"],
                    "file": filename,
                    "rows_displayed": item["rows_displayed"],
                    "display_truncated": item["display_truncated"],
                }
            )
        manifest["queries"].append(query_record)

    manifest_path = output_dir / "an5_execution_manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    return manifest_path


def run_an5_batch(
    query_ids: Iterable[str] = AN5_QUERY_IDS,
    *,
    max_rows: int = 500,
    export_dir: Path | None = None,
) -> dict[str, dict]:
    """Run selected AN5 queries sequentially after a fresh read-only preflight."""
    selected = tuple(query_ids)
    if not selected:
        raise ValueError("Select at least one AN5 query.")
    if len(set(selected)) != len(selected):
        raise ValueError("Duplicate query IDs are not allowed.")
    for query_id in selected:
        if query_id not in EXPECTED_RESULT_SET_COUNTS:
            raise ValueError(f"Unsupported AN5 query ID: {query_id}")

    verify_read_only_preflight()
    results: dict[str, dict] = {}
    for query_id in selected:
        result = run_an5_query(query_id, max_rows=max_rows)
        results[query_id] = result
        _display_result(query_id, result)

    if export_dir is not None:
        manifest = _export_results(results, export_dir)
        print("\nExecution artifacts exported to:", manifest)

    return results


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run the canonical AN5 engagement-sensitivity SQL package."
    )
    parser.add_argument(
        "--query",
        action="append",
        choices=AN5_QUERY_IDS,
        help="Run one or more selected query IDs. Omit to run all five in order.",
    )
    parser.add_argument(
        "--max-rows",
        type=int,
        default=500,
        help="Maximum rows retained per result set (default: 500).",
    )
    parser.add_argument(
        "--export-dir",
        type=Path,
        default=None,
        help="Optional local directory for CSV result sets and a JSON manifest.",
    )
    args = parser.parse_args()
    run_an5_batch(
        args.query or AN5_QUERY_IDS,
        max_rows=args.max_rows,
        export_dir=args.export_dir,
    )


if __name__ == "__main__":
    main()

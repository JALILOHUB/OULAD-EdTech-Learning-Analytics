"""Execute the canonical AN6 read-only SQL investigations.

Run from the repository root:
    python scripts/run_an6.py
    python scripts/run_an6.py --query AN6.01
    python scripts/run_an6.py --query AN6.02 --export-dir outputs/an6

AN6.01 is always executed first and must pass its readiness gate before any
downstream scan. SQL remains canonical under sql/04_analytics/.
"""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys

import psycopg
from typing import Iterable

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.analytics.db import run_query

AN6_QUERY_IDS = ("AN6.01", "AN6.02", "AN6.03", "AN6.04")
EXPECTED_RESULT_SET_COUNTS = {
    "AN6.01": 3,
    "AN6.02": 1,
    "AN6.03": 1,
    "AN6.04": 1,
}
AN6_READINESS_TIMEOUT_MS = 120_000
AN6_ANALYTICAL_TIMEOUT_MS = 600_000
_PREFLIGHT_VERIFIED = False
_READINESS_VERIFIED = False


def verify_read_only_preflight() -> dict:
    """Verify database identity and read-only settings using canonical AN0.01."""
    global _PREFLIGHT_VERIFIED, _READINESS_VERIFIED
    _PREFLIGHT_VERIFIED = False
    _READINESS_VERIFIED = False

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

    print("\nAN6 — PostgreSQL connection and safety preflight")
    print("Query:", result["query_file"])
    print("Elapsed seconds:", result["elapsed_seconds"])
    print("Returned result sets:", result["result_set_count"])
    print(result["data"].to_string(index=False))
    for name, passed in checks.items():
        print(f"{name}: {'PASS' if passed else 'FAIL'}")

    if not all(checks.values()):
        raise RuntimeError(
            "AN0.01 preflight failed. Stop; no AN6 analytical query was executed."
        )

    _PREFLIGHT_VERIFIED = True
    print("AN6 PREFLIGHT: PASS — intended database and read-only session confirmed.\n")
    return result


def readiness_gate(result: dict) -> bool:
    """Validate all AN6.01 result sets before permitting downstream scans."""
    global _READINESS_VERIFIED
    _READINESS_VERIFIED = False

    if result.get("query_id") != "AN6.01":
        raise RuntimeError("The readiness gate accepts only AN6.01 results.")
    if result["result_set_count"] != EXPECTED_RESULT_SET_COUNTS["AN6.01"]:
        raise RuntimeError("AN6.01 returned an unexpected number of result sets.")

    course, metadata, keys = (
        item["data"] for item in result["result_sets"]
    )
    if course.empty or metadata.empty or keys.empty:
        raise RuntimeError("AN6.01 returned an empty readiness result set.")

    course_checks = {
        "expected_22_course_presentations": len(course) == 22,
        "valid_course_windows": bool(course["valid_course_window"].fillna(False).all()),
        "unique_course_keys": bool((course["course_key_rows"] == 1).all()),
    }
    metadata_checks = {
        "unique_course_scoped_vle_resource_keys": int(metadata.iloc[0]["duplicate_resource_keys"]) == 0,
        "complete_vle_resource_key_components": int(metadata.iloc[0]["null_resource_key_component_rows"]) == 0,
    }
    key_checks = {
        "unique_registration_keys": int(keys.iloc[0]["duplicate_registration_keys"]) == 0,
        "registration_course_matches": int(keys.iloc[0]["registration_keys_without_course_window"]) == 0,
        "complete_student_vle_key_components": int(keys.iloc[0]["activity_rows_with_null_key_component"]) == 0,
        "student_vle_course_window_matches": int(keys.iloc[0]["activity_rows_without_course_window"]) == 0,
    }
    checks = {**course_checks, **metadata_checks, **key_checks}

    print("AN6.01 — readiness checks")
    for name, passed in checks.items():
        print(f"{name}: {'PASS' if passed else 'FAIL'}")

    if not all(checks.values()):
        failed = [name for name, passed in checks.items() if not passed]
        raise RuntimeError(
            "AN6.01 readiness gate failed; downstream scans blocked: "
            + ", ".join(failed)
        )

    metadata_fields = [
        "missing_activity_type_rows",
        "missing_week_from_rows",
        "missing_week_to_rows",
        "reversed_week_range_rows",
    ]
    print(
        "Metadata completeness diagnostics (reported, not used as filters):",
        metadata[metadata_fields].to_dict("records"),
    )
    _READINESS_VERIFIED = True
    print("AN6.01 READINESS: PASS — downstream queries are unlocked.\n")
    return True


def run_an6_query(
    query_id: str, *, max_rows: int = 500, display_results: bool = True
) -> dict:
    """Execute one canonical AN6 query after the required preflight/gates."""
    global _READINESS_VERIFIED
    if not _PREFLIGHT_VERIFIED:
        raise RuntimeError(
            "Run verify_read_only_preflight() successfully before any AN6 query."
        )
    if query_id not in EXPECTED_RESULT_SET_COUNTS:
        raise ValueError(f"Unsupported AN6 query ID: {query_id}")
    if query_id == "AN6.01":
        _READINESS_VERIFIED = False
    if query_id != "AN6.01" and not _READINESS_VERIFIED:
        raise RuntimeError("AN6.01 readiness must pass before downstream scans.")

    timeout = (
        AN6_READINESS_TIMEOUT_MS
        if query_id == "AN6.01"
        else AN6_ANALYTICAL_TIMEOUT_MS
    )
    try:
        result = run_query(
            query_id,
            max_rows=max_rows,
            statement_timeout_ms=timeout,
        )
    except psycopg.Error as exc:
        query_path = next(
            (PROJECT_ROOT / "sql" / "04_analytics").glob(f"{query_id}_*.sql"),
            None,
        )
        diagnostic = getattr(exc, "diag", None)
        primary = getattr(diagnostic, "message_primary", None)
        detail = getattr(diagnostic, "message_detail", None)
        hint = getattr(diagnostic, "message_hint", None)
        print(f"\n{query_id} FAILED — PostgreSQL rejected the SQL batch.")
        print("SQL file:", query_path.relative_to(PROJECT_ROOT) if query_path else "not resolved")
        print("PostgreSQL SQLSTATE:", getattr(exc, "sqlstate", None))
        if primary:
            print("Primary:", primary)
        if detail:
            print("Detail:", detail)
        if hint:
            print("Hint:", hint)
        print("No automatic retry was attempted. Review the SQL and server diagnostic before rerunning.")
        raise RuntimeError(
            f"{query_id} failed in PostgreSQL; see the diagnostic above. "
            "No automatic retry was attempted."
        ) from exc

    expected = EXPECTED_RESULT_SET_COUNTS[query_id]
    if result["result_set_count"] != expected:
        raise RuntimeError(
            f"{query_id} returned {result['result_set_count']} result sets; "
            f"expected {expected}. Stop and inspect its canonical SQL."
        )

    print(
        f"\n{query_id} | {result['query_file']} | "
        f"{result['elapsed_seconds']} seconds | "
        f"{result['result_set_count']} result set(s) | "
        f"timeout={result['statement_timeout_ms']} ms"
    )
    for item in result["result_sets"]:
        print(
            f"Result set {item['statement_number']}: "
            f"{item['rows_displayed']} displayed row(s); "
            f"truncated={item['display_truncated']}"
        )
        if display_results:
            print(item["data"].to_string(index=False))
    return result


def _export_results(results: dict[str, dict], output_dir: Path) -> Path:
    """Export returned result frames and an execution manifest."""
    output_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "database_name": "oulad_analytics",
        "read_only_preflight_passed": _PREFLIGHT_VERIFIED,
        "readiness_gate_passed": _READINESS_VERIFIED,
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
            filename = (
                f"{query_id.replace('.', '_')}_result_"
                f"{item['statement_number']:02d}.csv"
            )
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

    manifest_path = output_dir / "an6_execution_manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    return manifest_path


def run_an6_batch(
    query_ids: Iterable[str] = AN6_QUERY_IDS,
    *,
    max_rows: int = 500,
    export_dir: Path | None = None,
) -> dict[str, dict]:
    """Run AN6.01 first, validate it, then execute selected downstream queries."""
    selected = tuple(query_ids)
    if not selected:
        raise ValueError("Select at least one AN6 query.")
    if len(set(selected)) != len(selected):
        raise ValueError("Duplicate query IDs are not allowed.")
    for query_id in selected:
        if query_id not in AN6_QUERY_IDS:
            raise ValueError(f"Unsupported AN6 query ID: {query_id}")

    verify_read_only_preflight()
    results = {"AN6.01": run_an6_query("AN6.01", max_rows=max_rows)}
    readiness_gate(results["AN6.01"])

    for query_id in selected:
        if query_id == "AN6.01":
            continue
        results[query_id] = run_an6_query(query_id, max_rows=max_rows)

    if export_dir is not None:
        manifest = _export_results(results, export_dir)
        print("\nExecution artifacts exported to:", manifest)
    return results


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run the canonical AN6 recorded VLE activity investigations."
    )
    parser.add_argument(
        "--query",
        action="append",
        choices=AN6_QUERY_IDS,
        help="Run selected queries; AN6.01 readiness is always executed first.",
    )
    parser.add_argument("--max-rows", type=int, default=500)
    parser.add_argument("--export-dir", type=Path, default=None)
    args = parser.parse_args()

    run_an6_batch(
        args.query or AN6_QUERY_IDS,
        max_rows=args.max_rows,
        export_dir=args.export_dir,
    )


if __name__ == "__main__":
    main()

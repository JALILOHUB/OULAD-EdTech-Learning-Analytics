"""Execute canonical AN7 read-only SQL investigations sequentially."""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys
from typing import Iterable

import psycopg

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.analytics.db import run_query

AN7_QUERY_IDS = ("AN7.01", "AN7.02", "AN7.03", "AN7.04", "AN7.05")
EXPECTED_RESULT_SET_COUNTS = {"AN7.01": 3, "AN7.02": 1, "AN7.03": 1, "AN7.04": 1, "AN7.05": 1}
LIGHT_TIMEOUT_MS = 120_000
HEAVY_TIMEOUT_MS = 600_000
EXTRACT_MAX_ROWS = 33_000
_PREFLIGHT_VERIFIED = False
_COHORT_GATE_VERIFIED = False


def verify_read_only_preflight() -> dict:
    global _PREFLIGHT_VERIFIED, _COHORT_GATE_VERIFIED
    _PREFLIGHT_VERIFIED = False
    _COHORT_GATE_VERIFIED = False
    result = run_query("AN0.01", max_rows=10, statement_timeout_ms=LIGHT_TIMEOUT_MS)
    if result["result_set_count"] != 1 or result["data"].empty:
        raise RuntimeError("AN0.01 preflight returned an unexpected result shape.")
    row = result["data"].iloc[0]
    checks = {
        "database_name": row["database_name"] == "oulad_analytics",
        "transaction_read_only": str(row["transaction_read_only"]).lower() == "on",
        "default_transaction_read_only": str(row["default_transaction_read_only"]).lower() == "on",
    }
    print("\\nAN7 — PostgreSQL read-only preflight")
    print(result["data"].to_string(index=False))
    for name, passed in checks.items():
        print(f"{name}: {'PASS' if passed else 'FAIL'}")
    if not all(checks.values()):
        raise RuntimeError("AN7 preflight failed; no AN7 query may run.")
    _PREFLIGHT_VERIFIED = True
    return result


def verify_cohort_gate(result: dict) -> bool:
    global _COHORT_GATE_VERIFIED
    _COHORT_GATE_VERIFIED = False
    if not _PREFLIGHT_VERIFIED:
        raise RuntimeError("A successful AN0.01 preflight is required.")
    if result.get("query_id") != "AN7.03" or result.get("result_set_count") != 1:
        raise RuntimeError("The cohort gate accepts only AN7.03 results.")
    if result["display_truncated"]:
        raise RuntimeError("AN7.03 is truncated; heavy scans are blocked.")
    frame = result["data"]
    key = ["code_module", "code_presentation", "id_student"]
    checks = {
        "expected_32593_rows": len(frame) == 32_593,
        "unique_student_presentation_key": not frame.duplicated(key).any(),
        "registration_matches": bool(frame["registration_match"].fillna(False).all()),
        "course_window_matches": bool(frame["course_window_match"].fillna(False).all()),
        "missing_registration_dates_reconcile_45": int(frame["date_registration"].isna().sum()) == 45,
    }
    print("\\nAN7.03 — cohort readiness gate")
    for name, passed in checks.items():
        print(f"{name}: {'PASS' if passed else 'FAIL'}")
    print("Missing registration dates retained:", int(frame["date_registration"].isna().sum()))
    for column in ("risk_status_l28", "risk_status_l56", "risk_status_l84"):
        print(f"\\n{column}:\\n{frame[column].value_counts(dropna=False).to_string()}")
    if not all(checks.values()):
        raise RuntimeError("AN7.03 cohort gate failed: " + ", ".join(
            name for name, passed in checks.items() if not passed
        ))
    _COHORT_GATE_VERIFIED = True
    return True


def run_an7_query(query_id: str, *, max_rows: int | None = None,
                  display_results: bool = True) -> dict:
    if not _PREFLIGHT_VERIFIED:
        raise RuntimeError("Run verify_read_only_preflight() before AN7 queries.")
    if query_id not in EXPECTED_RESULT_SET_COUNTS:
        raise ValueError(f"Unsupported AN7 query ID: {query_id}")
    if query_id in ("AN7.04", "AN7.05") and not _COHORT_GATE_VERIFIED:
        raise RuntimeError("AN7.03 cohort gate must pass before heavy scans.")
    row_cap = max_rows if max_rows is not None else (
        EXTRACT_MAX_ROWS if query_id in ("AN7.03", "AN7.04", "AN7.05") else 500
    )
    timeout = HEAVY_TIMEOUT_MS if query_id in ("AN7.04", "AN7.05") else LIGHT_TIMEOUT_MS
    try:
        result = run_query(query_id, max_rows=row_cap, statement_timeout_ms=timeout)
    except psycopg.Error as exc:
        diag = getattr(exc, "diag", None)
        print(f"\\n{query_id} FAILED — PostgreSQL rejected the SQL batch.")
        print("SQLSTATE:", getattr(exc, "sqlstate", None))
        print("Primary:", getattr(diag, "message_primary", None))
        print("Detail:", getattr(diag, "message_detail", None))
        print("Hint:", getattr(diag, "message_hint", None))
        print("No automatic retry was attempted.")
        raise RuntimeError(f"{query_id} failed; inspect the diagnostic before rerunning.") from exc
    expected = EXPECTED_RESULT_SET_COUNTS[query_id]
    if result["result_set_count"] != expected:
        raise RuntimeError(f"{query_id} returned {result['result_set_count']} result sets; expected {expected}.")
    print(f"\\n{query_id} | {result['query_file']} | {result['elapsed_seconds']} seconds | "
          f"{result['result_set_count']} result set(s) | truncated={result['display_truncated']}")
    if display_results:
        for item in result["result_sets"]:
            print(f"Result set {item['statement_number']}: {item['rows_displayed']} rows; "
                  f"truncated={item['display_truncated']}")
            print(item["data"].to_string(index=False))
    return result


def run_an7_batch(query_ids: Iterable[str] = ("AN7.01", "AN7.02", "AN7.03"),
                  *, export_dir: Path | None = None) -> dict[str, dict]:
    selected = tuple(query_ids)
    if not selected or len(set(selected)) != len(selected):
        raise ValueError("Select one or more unique AN7 query IDs.")
    if any(q not in AN7_QUERY_IDS for q in selected):
        raise ValueError("Unsupported AN7 query ID.")
    if "AN7.04" in selected and "AN7.05" in selected:
        raise ValueError("Run only one high-cost scan per invocation; review its complete output before starting the other scan.")
    if any(q in ("AN7.04", "AN7.05") for q in selected):
        if not {"AN7.01", "AN7.02", "AN7.03"}.issubset(selected):
            raise ValueError("A batch with AN7.04/AN7.05 must include AN7.01–AN7.03.")
        if selected.index("AN7.03") > min(selected.index(q) for q in selected if q in ("AN7.04","AN7.05")):
            raise ValueError("AN7.03 must precede both high-cost scans.")
    verify_read_only_preflight()
    results = {}
    for query_id in selected:
        result = run_an7_query(query_id, display_results=False)
        results[query_id] = result
        if query_id == "AN7.03":
            verify_cohort_gate(result)
        if query_id in ("AN7.04","AN7.05") and result["display_truncated"]:
            raise RuntimeError(f"{query_id} is truncated; stop.")
    if export_dir is not None:
        export_dir.mkdir(parents=True, exist_ok=True)
        manifest = {
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "database_name": "oulad_analytics",
            "read_only_preflight_passed": True,
            "cohort_gate_passed": _COHORT_GATE_VERIFIED,
            "queries": []
        }
        for query_id, result in results.items():
            rec = {"query_id":query_id,"query_file":result["query_file"],
                   "elapsed_seconds":result["elapsed_seconds"],
                   "statement_timeout_ms":result["statement_timeout_ms"],
                   "result_sets":[]}
            for item in result["result_sets"]:
                name = f"{query_id.replace('.','_')}_result_{item['statement_number']:02d}.csv"
                item["data"].to_csv(export_dir/name,index=False)
                rec["result_sets"].append({"file":name,"rows_displayed":item["rows_displayed"],
                                           "display_truncated":item["display_truncated"]})
            manifest["queries"].append(rec)
        (export_dir/"an7_execution_manifest.json").write_text(
            json.dumps(manifest,indent=2,ensure_ascii=False),encoding="utf-8"
        )
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the gated read-only AN7 SQL package.")
    parser.add_argument("--query", action="append", choices=AN7_QUERY_IDS)
    parser.add_argument("--export-dir", type=Path, default=None)
    args = parser.parse_args()
    run_an7_batch(tuple(args.query) if args.query else ("AN7.01", "AN7.02", "AN7.03"),
                  export_dir=args.export_dir)


if __name__ == "__main__":
    main()

"""Gated read-only AN8 runner with cohort and result-set validation."""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import psycopg

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from src.analytics.db import run_query

LIGHT = {"AN8.01", "AN8.02", "AN8.03", "AN8.04", "AN8.10", "AN8.11", "AN8.12", "AN8.33", "AN8.40", "AN8.41"}
HEAVY = {"AN8.20"}
ALLOWED = LIGHT | HEAVY
DEFERRED = {"AN8.21", "AN8.22", "AN8.23", "AN8.30", "AN8.31", "AN8.32"}
EXPECTED_RESULT_SETS = {"AN8.04": 2}
PREFLIGHT_VERIFIED = False
COHORT_GATE_VERIFIED = False
COURSE_GATE_VERIFIED = False
COHORT_ROWS: int | None = None


def preflight() -> dict:
    """Require the project's approved database and a read-only session."""
    global PREFLIGHT_VERIFIED, COHORT_GATE_VERIFIED, COURSE_GATE_VERIFIED, COHORT_ROWS
    PREFLIGHT_VERIFIED = False
    COHORT_GATE_VERIFIED = False
    COURSE_GATE_VERIFIED = False
    COHORT_ROWS = None
    result = run_query("AN0.01", max_rows=10, statement_timeout_ms=120_000)
    if result["result_set_count"] != 1 or result["data"].empty or result["display_truncated"]:
        raise RuntimeError("AN0.01 preflight returned an empty, truncated, or unexpected result.")
    row = result["data"].iloc[0]
    checks = {
        "database_name": row["database_name"] == "oulad_analytics",
        "transaction_read_only": str(row["transaction_read_only"]).lower() == "on",
        "default_transaction_read_only": str(row["default_transaction_read_only"]).lower() == "on",
    }
    print("\nAN8 — read-only database preflight")
    print(result["data"].to_string(index=False))
    for name, passed in checks.items():
        print(f"{name}: {'PASS' if passed else 'FAIL'}")
    if not all(checks.values()):
        raise RuntimeError("AN8 blocked: database identity/read-only preflight failed.")
    PREFLIGHT_VERIFIED = True
    return result


def _check_all_result_sets(result: dict, expected_count: int) -> None:
    items = result.get("result_sets", [])
    if result.get("result_set_count") != expected_count or len(items) != expected_count:
        raise RuntimeError(
            f"{result['query_id']} returned {len(items)} result sets; expected {expected_count}."
        )
    truncated = [item["statement_number"] for item in items if item["display_truncated"]]
    if truncated:
        raise RuntimeError(
            f"{result['query_id']} has truncated result set(s) {truncated}; downstream work blocked."
        )


def verify_grain_gate(result: dict) -> bool:
    """Validate source key uniqueness and bidirectional key-set reconciliation."""
    global COHORT_GATE_VERIFIED, COHORT_ROWS
    COHORT_GATE_VERIFIED = False
    if not PREFLIGHT_VERIFIED:
        raise RuntimeError("Run preflight() before the AN8.02 grain gate.")
    if result.get("query_id") != "AN8.02":
        raise ValueError("The grain gate accepts AN8.02 only.")
    _check_all_result_sets(result, 1)
    frame = result["result_sets"][0]["data"]
    required = {"check_type", "check_name", "source_rows", "distinct_keys", "duplicate_key_groups", "null_key_rows", "key_count"}
    if not required.issubset(frame.columns):
        raise RuntimeError(f"AN8.02 is missing required columns: {sorted(required - set(frame.columns))}")
    source = frame.loc[frame["check_type"] == "SOURCE_GRAIN"].copy()
    diffs = frame.loc[frame["check_type"] == "KEY_DIFFERENCE"].copy()
    if set(source["check_name"]) != {"student_info", "student_registration"}:
        raise RuntimeError("AN8.02 did not return exactly the two expected source-grain records.")
    source["source_rows"] = source["source_rows"].astype("int64")
    source["distinct_keys"] = source["distinct_keys"].astype("int64")
    source["duplicate_key_groups"] = source["duplicate_key_groups"].astype("int64")
    source["null_key_rows"] = source["null_key_rows"].astype("int64")
    checks = {
        "no_duplicate_student_info_keys": int(source.loc[source.check_name == "student_info", "duplicate_key_groups"].iloc[0]) == 0,
        "no_duplicate_registration_keys": int(source.loc[source.check_name == "student_registration", "duplicate_key_groups"].iloc[0]) == 0,
        "student_info_rows_equal_distinct_keys": bool((source.loc[source.check_name == "student_info", "source_rows"] == source.loc[source.check_name == "student_info", "distinct_keys"]).all()),
        "registration_rows_equal_distinct_keys": bool((source.loc[source.check_name == "student_registration", "source_rows"] == source.loc[source.check_name == "student_registration", "distinct_keys"]).all()),
        "no_null_key_rows": bool((source["null_key_rows"] == 0).all()),
        "no_key_set_differences": bool((diffs["key_count"].fillna(-1).astype("int64") == 0).all()) and len(diffs) == 2,
    }
    print("\nAN8.02 — student-presentation grain gate")
    print(frame.to_string(index=False))
    for name, passed in checks.items():
        print(f"{name}: {'PASS' if passed else 'FAIL'}")
    if not all(checks.values()):
        raise RuntimeError("AN8.02 gate failed; AN8.03 and all downstream activity scans are blocked.")
    COHORT_ROWS = int(source.loc[source.check_name == "student_registration", "source_rows"].iloc[0])
    COHORT_GATE_VERIFIED = True
    return True



def verify_course_context_gate(result: dict) -> bool:
    """Verify course-key uniqueness and course-window completeness before activity joins."""
    global COURSE_GATE_VERIFIED
    COURSE_GATE_VERIFIED = False
    if not PREFLIGHT_VERIFIED or not COHORT_GATE_VERIFIED:
        raise RuntimeError("AN0.01 and AN8.02 gates must pass before the AN8.04 course gate.")
    if result.get("query_id") != "AN8.04":
        raise ValueError("The course-context gate accepts AN8.04 only.")
    _check_all_result_sets(result, 2)
    courses = result["result_sets"][0]["data"]
    assessments = result["result_sets"][1]["data"]
    course_key = ["code_module", "code_presentation"]
    required = set(course_key + ["module_presentation_length"])
    if not required.issubset(courses.columns):
        raise RuntimeError("AN8.04 result set 1 is missing course-key/window columns.")
    if not set(course_key + ["assessment_count", "missing_due_dates", "total_weight"]).issubset(assessments.columns):
        raise RuntimeError("AN8.04 result set 2 is missing assessment-context columns.")
    checks = {
        "course_context_nonempty": not courses.empty,
        "course_keys_non_null": not courses[course_key].isna().any().any(),
        "course_keys_unique": not courses.duplicated(course_key).any(),
        "course_lengths_non_null": not courses["module_presentation_length"].isna().any(),
        "assessment_context_keys_unique": not assessments.duplicated(course_key).any(),
        "assessment_context_covers_course_keys": set(map(tuple, courses[course_key].to_numpy())) == set(map(tuple, assessments[course_key].to_numpy())),
    }
    print("\nAN8.04 — course and assessment context gate")
    for name, passed in checks.items():
        print(f"{name}: {'PASS' if passed else 'FAIL'}")
    if not all(checks.values()):
        raise RuntimeError("AN8.04 course-context gate failed; AN8.20 is blocked.")
    COURSE_GATE_VERIFIED = True
    return True


def _validate_student_presentation_extract(query_id: str, result: dict) -> None:
    if query_id not in {"AN8.20", "AN8.22", "AN8.23"}:
        return
    if COHORT_ROWS is None:
        raise RuntimeError("No validated cohort denominator is available.")
    frame = result["result_sets"][0]["data"]
    key = ["code_module", "code_presentation", "id_student"]
    if not set(key).issubset(frame.columns):
        raise RuntimeError(f"{query_id} does not expose the declared student-presentation key.")
    checks = {
        "row_count_matches_validated_cohort": len(frame) == COHORT_ROWS,
        "unique_student_presentation_key": not frame.duplicated(key).any(),
        "non_null_student_presentation_key": not frame[key].isna().any().any(),
    }
    print(f"\n{query_id} — student-presentation extract gate")
    for name, passed in checks.items():
        print(f"{name}: {'PASS' if passed else 'FAIL'}")
    if not all(checks.values()):
        raise RuntimeError(f"{query_id} failed cohort-grain validation; stop before export/visualization.")


def run_one(query_id: str) -> dict:
    if not PREFLIGHT_VERIFIED:
        raise RuntimeError("Run preflight() first.")
    if query_id in DEFERRED:
        raise RuntimeError(f"{query_id} is retired/deferred and blocked. Use AN8.20 for consolidated activity measures.")
    if query_id not in ALLOWED:
        raise ValueError(f"Unsupported query ID: {query_id}")
    if query_id not in {"AN8.01", "AN8.02"} and not COHORT_GATE_VERIFIED:
        raise RuntimeError("AN8.02 grain/key-set gate must pass before this query.")
    timeout = 600_000 if query_id in HEAVY else 120_000
    row_cap = 33_000 if query_id in {"AN8.20", "AN8.22", "AN8.23"} else 1_000
    try:
        result = run_query(query_id, max_rows=row_cap, statement_timeout_ms=timeout)
    except psycopg.Error as exc:
        diag = getattr(exc, "diag", None)
        print(f"\n{query_id} FAILED — SQLSTATE={getattr(exc, 'sqlstate', None)}")
        print("Primary:", getattr(diag, "message_primary", None))
        print("Detail:", getattr(diag, "message_detail", None))
        print("Hint:", getattr(diag, "message_hint", None))
        print("No automatic retry was attempted.")
        raise RuntimeError(f"{query_id} failed; inspect PostgreSQL diagnostics before any rerun.") from exc
    expected = EXPECTED_RESULT_SETS.get(query_id, 1)
    _check_all_result_sets(result, expected)
    if query_id == "AN8.02":
        verify_grain_gate(result)
    if query_id == "AN8.04":
        verify_course_context_gate(result)
    if query_id == "AN8.20" and not COURSE_GATE_VERIFIED:
        raise RuntimeError("AN8.04 course-context gate must pass before AN8.20.")
    if query_id == "AN8.20":
        _validate_student_presentation_extract(query_id, result)
    print(f"{query_id}: {result['elapsed_seconds']} s; "
          f"{result['result_set_count']} result set(s); "
          f"{sum(x['rows_displayed'] for x in result['result_sets'])} displayed rows; no truncation")
    return result



def export_results(results: dict[str, dict], output_dir: Path | None = None) -> Path:
    """Persist reviewed query result sets as local CSVs plus a non-sensitive manifest."""
    from datetime import datetime, timezone

    destination = output_dir or (ROOT / "outputs" / "an8" / "extracts")
    destination.mkdir(parents=True, exist_ok=True)
    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "database_name": "oulad_analytics",
        "read_only_preflight_required": True,
        "queries": [],
    }
    for query_id, result in results.items():
        record = {
            "query_id": query_id,
            "query_file": result["query_file"],
            "elapsed_seconds": result["elapsed_seconds"],
            "statement_timeout_ms": result["statement_timeout_ms"],
            "result_sets": [],
        }
        for item in result["result_sets"]:
            filename = f"{query_id.replace('.', '_')}_result_{item['statement_number']:02d}.csv"
            item["data"].to_csv(destination / filename, index=False)
            record["result_sets"].append({
                "file": filename,
                "rows_displayed": item["rows_displayed"],
                "display_truncated": item["display_truncated"],
                "columns": list(item["data"].columns),
            })
        manifest["queries"].append(record)
    manifest_path = destination / "an8_execution_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"AN8 exports and manifest saved to: {destination}")
    return manifest_path


def run_batch(query_ids: list[str]) -> dict[str, dict]:
    selected = tuple(query_ids)
    if not selected or len(set(selected)) != len(selected):
        raise ValueError("Select one or more unique query IDs.")
    if any(q not in ALLOWED for q in selected):
        raise ValueError("Unknown or deferred query ID.")
    if any(q in HEAVY for q in selected):
        raise ValueError("AN8.20 must run alone via run_one() after reviewing AN8.02 and AN8.04 gates.")
    preflight()
    results = {}
    for query_id in selected:
        results[query_id] = run_one(query_id)
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--query", action="append", dest="queries")
    args = parser.parse_args()
    run_batch(args.queries or ["AN8.01", "AN8.02", "AN8.03"])


if __name__ == "__main__":
    main()

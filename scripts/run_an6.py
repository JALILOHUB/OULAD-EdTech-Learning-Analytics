"""Run the AN6 read-only SQL package; AN6.01 is a mandatory readiness gate."""
from __future__ import annotations
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys
from typing import Iterable

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
from src.analytics.db import run_query

QUERY_IDS=("AN6.01","AN6.02","AN6.03","AN6.04")
EXPECTED={"AN6.01":3,"AN6.02":1,"AN6.03":1,"AN6.04":1}
PREFLIGHT=False
READINESS=False

def preflight():
    global PREFLIGHT
    PREFLIGHT=False
    r=run_query("AN0.01",max_rows=10,statement_timeout_ms=120000)
    if r["result_set_count"]!=1 or r["data"].empty: raise RuntimeError("Unexpected AN0.01 result.")
    row=r["data"].iloc[0]
    checks={"database":row["database_name"]=="oulad_analytics",
            "transaction_read_only":str(row["transaction_read_only"]).lower()=="on",
            "default_transaction_read_only":str(row["default_transaction_read_only"]).lower()=="on"}
    print("AN6 preflight:",checks)
    if not all(checks.values()): raise RuntimeError("Read-only preflight failed; stop.")
    PREFLIGHT=True
    return r

def readiness_gate(r):
    global READINESS
    READINESS=False
    if r.get("query_id")!="AN6.01" or r["result_set_count"]!=3: raise RuntimeError("AN6.01 readiness result shape failed.")
    c,m,k=(x["data"] for x in r["result_sets"])
    if c.empty or not c["valid_course_window"].fillna(False).all() or not (c["course_key_rows"]==1).all():
        raise RuntimeError("Course windows/keys invalid; downstream scans blocked.")
    if int(m.iloc[0]["excess_rows_over_distinct_id_site"])!=0 or int(m.iloc[0]["null_id_site_rows"])!=0:
        raise RuntimeError("VLE id_site key invalid; downstream scans blocked.")
    if int(k.iloc[0]["duplicate_registration_keys"])!=0 or int(k.iloc[0]["activity_rows_with_null_key_component"])!=0:
        raise RuntimeError("Registration/activity keys invalid; downstream scans blocked.")
    print("Readiness passed; metadata missingness:",m[["missing_activity_type_rows","missing_week_from_rows","missing_week_to_rows"]].to_dict("records"))
    READINESS=True

def execute(qid,max_rows=500):
    if not PREFLIGHT: raise RuntimeError("AN0.01 preflight required.")
    if qid not in EXPECTED: raise ValueError(qid)
    if qid!="AN6.01" and not READINESS: raise RuntimeError("Review AN6.01 before downstream scans.")
    r=run_query(qid,max_rows=max_rows,statement_timeout_ms=120000 if qid=="AN6.01" else 600000)
    if r["result_set_count"]!=EXPECTED[qid]: raise RuntimeError(f"{qid}: unexpected result-set count.")
    print(f"\n{qid} | {r['elapsed_seconds']} sec")
    for x in r["result_sets"]:
        print(f"Result {x['statement_number']}: {x['rows_displayed']} rows; truncated={x['display_truncated']}")
        print(x["data"].to_string(index=False))
    return r

def export(results,folder):
    folder.mkdir(parents=True,exist_ok=True)
    manifest={"generated_at_utc":datetime.now(timezone.utc).isoformat(),"database":"oulad_analytics","queries":[]}
    for q,r in results.items():
        item={"query_id":q,"query_file":r["query_file"],"elapsed_seconds":r["elapsed_seconds"],"result_set_count":r["result_set_count"],"result_sets":[]}
        for x in r["result_sets"]:
            name=f"{q.replace('.','_')}_result_{x['statement_number']:02d}.csv"
            x["data"].to_csv(folder/name,index=False)
            item["result_sets"].append({"file":name,"rows_displayed":x["rows_displayed"],"display_truncated":x["display_truncated"]})
        manifest["queries"].append(item)
    p=folder/"an6_execution_manifest.json"
    p.write_text(json.dumps(manifest,indent=2),encoding="utf-8")
    return p

def run_batch(query_ids:Iterable[str]=QUERY_IDS,max_rows=500,export_dir:Path|None=None):
    selected=tuple(query_ids)
    if not selected or len(set(selected))!=len(selected) or any(q not in QUERY_IDS for q in selected):
        raise ValueError("Select unique valid AN6 query IDs.")
    if "AN6.01" not in selected: raise ValueError("AN6.01 is mandatory.")
    preflight()
    results={"AN6.01":execute("AN6.01",max_rows)}
    readiness_gate(results["AN6.01"])
    for q in selected:
        if q=="AN6.01": continue
        results[q]=execute(q,max_rows)
    if export_dir: print("Export:",export(results,export_dir))
    return results

def main():
    p=argparse.ArgumentParser(description="Execute AN6 read-only investigations sequentially.")
    p.add_argument("--query",action="append",choices=QUERY_IDS)
    p.add_argument("--max-rows",type=int,default=500)
    p.add_argument("--export-dir",type=Path,default=None)
    a=p.parse_args()
    run_batch(a.query or QUERY_IDS,a.max_rows,a.export_dir)

if __name__=="__main__": main()

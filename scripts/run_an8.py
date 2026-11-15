"""Gated read-only AN8 query runner; no database object deployment."""
from __future__ import annotations
import argparse,sys
from pathlib import Path
import psycopg
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
from src.analytics.db import run_query
HEAVY={"AN8.20","AN8.21","AN8.22","AN8.23"}
ALLOWED={"AN8.01","AN8.02","AN8.03","AN8.04","AN8.10","AN8.11","AN8.12","AN8.20","AN8.21","AN8.22","AN8.23","AN8.33","AN8.40","AN8.41"}
DEFERRED={"AN8.30","AN8.31","AN8.32"}
PREFLIGHT=False
def preflight():
 global PREFLIGHT
 PREFLIGHT=False
 r=run_query("AN0.01",max_rows=10,statement_timeout_ms=120000)
 if r["result_set_count"]!=1 or r["data"].empty: raise RuntimeError("AN0.01 unexpected result")
 x=r["data"].iloc[0]
 checks={"database":x["database_name"]=="oulad_analytics","transaction_read_only":str(x["transaction_read_only"]).lower()=="on","default_transaction_read_only":str(x["default_transaction_read_only"]).lower()=="on"}
 print(r["data"].to_string(index=False)); print(checks)
 if not all(checks.values()): raise RuntimeError("Read-only preflight failed; AN8 blocked")
 PREFLIGHT=True
 return r
def run_one(qid):
 if not PREFLIGHT: raise RuntimeError("Run preflight() first")
 if qid in DEFERRED: raise RuntimeError(f"{qid} deferred and blocked")
 if qid not in ALLOWED: raise ValueError(f"Unsupported query ID: {qid}")
 try: r=run_query(qid,max_rows=33000 if qid in HEAVY else 1000,statement_timeout_ms=600000 if qid in HEAVY else 120000)
 except psycopg.Error as exc: raise RuntimeError(f"{qid} failed; no automatic retry. Inspect PostgreSQL diagnostics.") from exc
 expected_sets = 2 if qid == "AN8.04" else 1
 if r["result_set_count"]!=expected_sets or r["display_truncated"]: raise RuntimeError(f"{qid} result shape invalid or truncated; expected {expected_sets} result set(s)")
 print(f"{qid}: {r['elapsed_seconds']} sec; {r['rows_displayed']} rows; truncated=False")
 return r
def run_batch(ids):
 ids=tuple(ids)
 if not ids or len(set(ids))!=len(ids): raise ValueError("Use unique query IDs")
 if any(q not in ALLOWED for q in ids): raise ValueError("Unknown or deferred query")
 if sum(q in HEAVY for q in ids)>1: raise ValueError("Run only one high-cost scan per invocation")
 preflight()
 return {q:run_one(q) for q in ids}
def main():
 p=argparse.ArgumentParser(); p.add_argument("--query",action="append"); a=p.parse_args()
 run_batch(a.query or ["AN8.01","AN8.02","AN8.03"])
if __name__=="__main__": main()

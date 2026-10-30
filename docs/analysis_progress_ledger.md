# OULAD Analysis — Progress Ledger

Updated: 2026-10-30
Repository commit observed before ledger creation: f5b0fbc633146638cab9dd00ffbb615cd8ed65c0
Working branch: work/wo1-reconciliation-cells
Pre-documentation safety snapshot: backup/pre-wo1-documentation-2026-10-30 at 7e28dbbc390da99f80eb0ee755b7da39fc0854d5

## Roadmap status

| Stage | Status | Evidence / note |
|---|---|---|
| Project inventory and evidence audit | done | Handbook, handover, repository files, work-order documents, and prior reports reviewed. |
| AN0 — analytical readiness | done | AN0.01–AN0.04 saved execution outputs reviewed; registry and STAGING baselines reconciled in the saved notebook. |
| AN1 — grain and join validation | done for WO-1 scope | AN1.01–AN1.09 saved execution evidence reviewed; student composite keys passed and join fan-out documented. |
| AN2 — student/presentation profile | done for WO-1 descriptive scope | AN2.01–AN2.09 outputs reviewed; targeted reconciliation for AN2.02, AN2.04, AN2.05 passed. |
| AN3 — outcomes and withdrawal | todo | Next bounded analytical work order. |
| AN4 — assessment analysis | todo | Define assessment grain, timing, score handling, and submission denominators. |
| AN5 — engagement sensitivity | branched / dependency open | R0/R1/R2 comparison required; repeated student_vle candidate key remains unresolved. |
| AN6 — engagement analysis | todo | Depends on an approved activity definition from AN5. |
| AN7 — outcome associations | todo | Requires validated outcomes and engagement measures; associative, not causal. |
| AN8 — predictive readiness | todo | Separate future scope; leakage-safe design only after analytical phase. |
| AN9 — KPI layer | todo | Requires approved metric definitions, grain, denominators, and tests. |
| AN10 — Power BI | todo | After curated reporting outputs and validated KPIs. |
| AN11 — final report | todo | After dashboard and evidence review. |

## Scripts executed (do not repeat without a concrete reason)

| ID | Artifact | Safety | Evidence / key result |
|---|---|---|---|
| AN0.01–AN0.04 | sql/04_analytics/AN0.*.sql, notebook | READ-ONLY | Saved notebook outputs: database oulad_analytics, PostgreSQL 18.6, read-only settings; registry 29 rows (25 PASS, 4 REVIEW, 0 FAIL); all seven STAGING row counts match historical baseline; relation/index inventory inspected. |
| AN1.01 | sql/04_analytics/AN1.01_student_key_uniqueness.sql | READ-ONLY | User-returned output: student_info and student_registration each 32,593 rows, 0 null keys, 32,593 distinct composite keys, 0 duplicate groups, gate PASS. |
| AN1.02–AN1.09 | Canonical SQL and saved notebook | READ-ONLY | Saved execution outputs reviewed. Key-set reconciliation and assessment join fan-out are documented; metadata and activity relationships are descriptive and retain caveats. |
| AN2.01–AN2.09 | Canonical SQL and saved notebook | READ-ONLY | Saved execution outputs reviewed; counts/profile/missingness by presentation recorded. |
| AN2.02 reconciliation | Notebook reconciliation cell | READ-ONLY | 22/22 module-presentation groups: counts and rounded percentages reconcile; 0/22 explicit <NULL> category; 0.078 s. |
| AN2.04 reconciliation | Notebook reconciliation cell | READ-ONLY | 66/66 presentation-dimension groups: counts and rounded percentages reconcile; 0/66 explicit <NULL> category; 0.082 s. |
| AN2.05 reconciliation | Notebook reconciliation cell | READ-ONLY | 44/44 presentation-dimension groups: counts and rounded percentages reconcile; 0/44 explicit <NULL> category; 0.061 s. |

Combined targeted reconciliation: 132/132 count groups passed, 132/132 rounded-percentage groups passed, one denominator per group, and 0/132 explicit <NULL> output categories. This does not establish source-wide absence of SQL NULL values.

## Decisions

| ID | Decision | Reason / evidence |
|---|---|---|
| D-WO1-01 | Close WO-1 and WO-1B defined scope. | AN0–AN2 saved outputs reviewed; AN1.01 passed; all 132 targeted category groups reconciled. |
| D-WO1-02 | Retain historical registry timestamps as NULL. | Exact historical execution times were not captured; no backfill. |
| D-WO1-03 | Do not create indexes during readiness. | Catalog inspection only; no approved cost/benefit case for persistent change. |
| D-WO1-04 | Do not deduplicate or aggregate RAW/STAGING student_vle. | Candidate key remains non-unique and repeated groups contain different sum_click values. |
| D-NEXT-01 | Start AN3 and AN4 as the next analytical work order. | Outcomes/withdrawal and assessment questions can proceed using validated student/presentation grain without first approving a VLE engagement definition. |
| D-NEXT-02 | Keep AN5 as a separate dependency-gated work order. | R0/R1/R2 are alternative metric definitions; repeated-record semantics are unresolved. |

## Open questions

| ID | Question | Status | Next justified work |
|---|---|---|---|
| OQ-01 | What do repeated student_vle rows represent? | open | AN5 sensitivity design and source-semantics investigation; no destructive changes. |
| OQ-02 | What do negative relative VLE dates mean? | open | Verify OULAD time conventions and evaluate only in a defined temporal metric. |
| OQ-03 | How should missing date_unregistration be interpreted alongside final_result? | open | AN3 outcome/withdrawal analysis with explicit outcome categories and date caveats. |
| OQ-04 | What explains missing assessment dates, and how do they relate to submissions? | open | AN4 assessment metadata/submission analysis. |
| OQ-05 | Why are 173 assessment scores missing and how do they relate to is_banked? | open | AN4 score completeness and banked-submission analysis. |
| OQ-06 | What is the meaning and denominator treatment of is_banked? | open | AN4, using source documentation and observed distributions. |
| OQ-07 | How do assessment weights behave by presentation and type? | open | AN4 weight/timing analysis; do not assume weights sum to 100. |
| OQ-08 | What explains IMD missingness? | open | Carry descriptive patterns forward; do not infer missingness mechanism or causation. |
| OQ-09 | What source reference establishes valid categorical values? | open | Documentation/source provenance review when a domain decision is needed. |

## Files changed on the working branch

| File | Status | Change |
|---|---|---|
| docs/analysis_log.md | updated | Added 30 Oct reconciliation evidence, decision, limitations, and next-stage routing. |
| docs/analytical_readiness_work_order.md | updated | WO-1 status changed to completed; acceptance evidence and limitations recorded. |
| docs/analytical_work_order_plan.md | updated | WO-1B reconciliation and exit criteria marked complete. |
| README.md | updated | Current status reflects completed WO-1 and justified next stages. |
| docs/analysis_progress_ledger.md | created | This progress ledger. |
| docs/repository_snapshot_2026-10-30.md | created | Identifies the pre-update backup branch and exact commit. |
| notebooks/04_sql_analytics.ipynb | existing branch artifact | Reconciliation cells are present on the branch; user executed them locally. Whether outputs were saved back into the local notebook and synchronized to GitHub remains to be confirmed. |

## Publication backlog

| Topic | Evidence ready? | Visual made? | Published? |
|---|---|---|---|
| WO-1 key and join validation | yes, subject to screenshot/output selection | not verified | not verified |
| Category reconciliation (AN2.02/04/05) | yes | not verified | not verified |
| Outcomes/assessment findings | no | no | no |

## Next Work Order

| Planned ID | Purpose | Dependency |
|---|---|---|
| WO-2 / AN3 | Analyze final outcomes, registration status, and withdrawal patterns with explicit denominators and date semantics. | WO-1 closed; use validated student-presentation keys. |
| WO-2 / AN4 | Analyze assessment structure, dates, weights, submission coverage, scores, and banked submissions. | WO-1 closed; assessment metadata join validated. |
| Later AN5 | Compare R0/R1/R2 activity definitions and document sensitivity. | Define the engagement question first; investigate repeated-key semantics without modifying RAW/STAGING. |

## Repository actions

| Action | Branch / PR | Verified outcome |
|---|---|---|
| Created pre-documentation safety branch | backup/pre-wo1-documentation-2026-10-30 | Created from work/wo1-reconciliation-cells at 7e28dbbc390da99f80eb0ee755b7da39fc0854d5, preserving the exact pre-documentation state. |
| Updated analytical log, WO-1 documents, and README | work/wo1-reconciliation-cells | Four sequential commits; latest observed before ledger creation: f5b0fbc633146638cab9dd00ffbb615cd8ed65c0. |
| Pull request #1 | work/wo-1-analytical-readiness → main | Merged on 2026-10-29; merge commit 0201b758f966ff514f8c187aa462c1b22330cb83. |
| Current working branch merge | not requested | Not merged. No merge into main performed during this update. |
| Local working-tree synchronization | user machine | Not verified by GitHub operations; requires local status/hash check. |

## Next session entry condition

Do not rerun AN0–AN2 by default. Begin with local/GitHub synchronization and confirm whether executed notebook outputs were saved. Then prepare a bounded WO-2 plan for AN3 and AN4, inspect existing business questions and SQL inventory, and only then prepare the next SQL batch. No Power BI or predictive modelling begins at this point.
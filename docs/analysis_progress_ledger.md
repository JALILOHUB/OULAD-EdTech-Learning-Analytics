# OULAD Analysis — Progress Ledger

Updated: 2026-10-30

Repository: JALILOHUB/OULAD-EdTech-Learning-Analytics  
Default branch: `main`  
WO-1 evidence branch: `work/wo1-reconciliation-cells`  
WO-1 notebook commit: `fab3a99b5223940443ae9e5f10edea893cb301ce`  
WO-1 integration PR: [#2](https://github.com/JALILOHUB/OULAD-EdTech-Learning-Analytics/pull/2), squash-merged on 2026-10-30  
WO-1 squash merge commit: `91d3369b41e7cfb39c0d58f87ef6f105291c1107`  
Documentation consistency branch: `docs/wo1-documentation-consistency-2026-10-30`  
Pre-documentation safety branch: `backup/pre-wo1-documentation-2026-10-30`  
Preserved backup commit: `7e28dbbc390da99f80eb0ee755b7da39fc0854d5`

The project owner previously verified that the local working tree was clean and that the local and remote WO-1 evidence branch heads matched at `fab3a99`. GitHub records confirm the subsequent PR #2 squash merge. The local machine state after that merge has not been independently verified in this ledger.

## Roadmap status

| Analytical ID | Status | Evidence / note |
|---|---|---|
| AN0 — Analytical readiness | WO-1 scope completed; AN0.07 open | AN0.01–AN0.04 saved execution evidence reviewed. AN0.07 RAW key verification remains a follow-up check; execution is not established by the reviewed evidence. |
| AN1 — Grain, keys, and join integrity | WO-1 scope completed; AN1.10 open | AN1.01–AN1.09 evidence reviewed. Student-presentation keys passed the tested checks; assessment join fan-out was quantified. AN1.10 remains an investigation of the observed 33,407-row increase; execution is not established by the reviewed evidence. |
| AN2 — Student and presentation profile | WO-1 descriptive scope completed; AN2.10 open | AN2.01–AN2.09 evidence reviewed. Targeted AN2.02, AN2.04, and AN2.05 reconciliation passed across 132 groups. AN2.10 remains open for extended IMD missingness analysis; execution is not established by the reviewed evidence. |
| AN3 — Outcomes and withdrawal | Planned | Analyze outcome categories, registration/unregistration dates, and recorded activity absence with explicit denominators and careful interpretation. |
| AN4 — Assessment analysis | Planned | Analyze assessment grain, timing, weights, score completeness, submission coverage, and `is_banked` semantics. |
| AN5 — Engagement sensitivity | Dependency open | R0/R1/R2 remain alternative metric definitions; repeated `student_vle` candidate-key semantics are unresolved. |
| AN6 — Engagement analysis | Pending AN5 | Requires an approved activity definition and documented limitations. |
| AN7 — Outcome associations | Pending validated measures | Associations only; no causal interpretation is implied. |
| AN8 — Predictive readiness | Future gate | Requires a leakage-safe readiness assessment; it does not automatically authorize model development. |
| AN9 — Validated KPIs and analytical marts | Future | Requires approved definitions, grains, denominators, and validation tests. |
| AN10 — Power BI | Future | Depends on curated reporting outputs and validated KPIs. |
| AN11 — Final analytical report | Future | Depends on completed analytical validation and reporting evidence. |

## Executed analytical queries and retained evidence

| Analytical ID | Artifact | Safety | Evidence / key result |
|---|---|---|---|
| AN0.01–AN0.04 | `sql/04_analytics/AN0.*.sql`, notebook | READ-ONLY | Saved notebook outputs: database `oulad_analytics`, PostgreSQL 18.6, read-only settings; registry 29 rows (25 PASS, 4 REVIEW, 0 FAIL); all seven STAGING row counts match the historical baseline; relation/index inventory inspected. |
| AN1.01 | `sql/04_analytics/AN1.01_student_key_uniqueness.sql` | READ-ONLY | User-returned output: `student_info` and `student_registration` each 32,593 rows, 0 null keys, 32,593 distinct composite keys, 0 duplicate groups, gate PASS. |
| AN1.02–AN1.09 | Canonical SQL and saved notebook | READ-ONLY | Saved execution outputs reviewed. Key-set reconciliation and assessment join fan-out are documented; metadata and activity relationships remain descriptive and retain caveats. |
| AN2.01–AN2.09 | Canonical SQL and saved notebook | READ-ONLY | Saved execution outputs reviewed; counts, profiles, and missingness by presentation recorded. |
| AN2.02 reconciliation | Notebook reconciliation cell | READ-ONLY | 22/22 module-presentation groups: counts and rounded percentages reconcile; 0/22 explicit `<NULL>` categories; 0.078 s. |
| AN2.04 reconciliation | Notebook reconciliation cell | READ-ONLY | 66/66 presentation-dimension groups: counts and rounded percentages reconcile; 0/66 explicit `<NULL>` categories; 0.082 s. |
| AN2.05 reconciliation | Notebook reconciliation cell | READ-ONLY | 44/44 presentation-dimension groups: counts and rounded percentages reconcile; 0/44 explicit `<NULL>` categories; 0.061 s. |

Combined targeted reconciliation: 132/132 count groups passed, 132/132 rounded-percentage groups passed, one denominator per group, and 0/132 explicit `<NULL>` output categories. This does not establish source-wide absence of SQL NULL values.

## Decisions

| ID | Decision | Reason / evidence |
|---|---|---|
| D-WO1-01 | Accept the executed WO-1 and WO-1B scope as analytically complete. | Saved AN0–AN2 evidence was reviewed; AN1.01 passed; all 132 targeted category groups reconciled. AN0.07, AN1.10, and AN2.10 remain separately identified follow-up questions. |
| D-WO1-02 | Retain historical registry timestamps as NULL. | Exact historical execution times were not captured; no backfill. |
| D-WO1-03 | Do not create indexes during readiness. | Catalog inspection only; no approved cost/benefit case for persistent change. |
| D-WO1-04 | Do not deduplicate or aggregate RAW/STAGING `student_vle`. | Candidate key remains non-unique and repeated groups contain different `sum_click` values. |
| D-NEXT-01 | Execute WO-2 in a dependency-aware sequence: AN0.07, AN1.10, and AN2.10 first, followed by AN3 and AN4 within the same work-order package. | The three readiness follow-ups close outstanding AN0–AN2 questions before outcome and assessment interpretation. AN3 and AN4 can then use the validated student-presentation and assessment grains; neither requires prior approval of a VLE engagement definition. |
| D-NEXT-02 | Keep AN5 as a separate dependency-gated work order. | R0/R1/R2 are alternative metric definitions; repeated-record semantics are unresolved. |

## Open questions

| ID | Question | Status | Next justified work |
|---|---|---|---|
| OQ-01 | What do repeated `student_vle` rows represent? | Open | AN5 sensitivity design and source-semantics investigation; no destructive changes. |
| OQ-02 | What do negative relative VLE dates mean? | Open | Verify OULAD time conventions and evaluate only in a defined temporal metric. |
| OQ-03 | How should missing `date_unregistration` be interpreted alongside `final_result`? | Open | AN3 outcome/withdrawal analysis with explicit outcome categories and date caveats. |
| OQ-04 | What explains missing assessment dates, and how do they relate to submissions? | Open | AN4 assessment metadata/submission analysis. |
| OQ-05 | Why are 173 assessment scores missing and how do they relate to `is_banked`? | Open | AN4 score completeness and banked-submission analysis. |
| OQ-06 | What is the meaning and denominator treatment of `is_banked`? | Open | AN4, using source documentation and observed distributions. |
| OQ-07 | How do assessment weights behave by presentation and type? | Open | AN4 weight/timing analysis; do not assume weights sum to 100. |
| OQ-08 | What explains IMD missingness? | Open | Carry descriptive patterns forward; do not infer missingness mechanism or causation. |
| OQ-09 | What source reference establishes valid categorical values? | Open | Documentation/source provenance review when a domain decision is needed. |

## Files changed on the working branch

| File | Status | Change |
|---|---|---|
| `docs/analysis_log.md` | Updated | Added 30 October reconciliation evidence, decision, limitations, and next-stage routing. |
| `docs/analytical_readiness_work_order.md` | Updated | WO-1 scope, accepted evidence, and follow-up boundary recorded. |
| `docs/analytical_work_order_plan.md` | Updated | WO-1B reconciliation and exit criteria recorded. |
| `README.md` | Updated | Current status reflects completed WO-1 scope and remaining analytical questions. |
| `docs/analysis_progress_ledger.md` | Created, then refreshed | Records query evidence, decisions, repository integration, and next work. |
| `docs/repository_snapshot_2026-10-30.md` | Created, then extended | Preserves the pre-update snapshot and records later repository state. |
| `notebooks/04_sql_analytics.ipynb` | Updated and synchronized | Executed reconciliation cells and saved outputs were committed as `fab3a99` and included in PR #2. |

## Publication backlog

| Topic | Evidence ready? | Visual made? | Published? |
|---|---|---|---|
| WO-1 key and join validation | Yes, subject to output selection | Not verified | Not verified |
| Category reconciliation (AN2.02/04/05) | Yes | Not verified | Not verified |
| Outcomes/assessment findings | No | No | No |

## Next Work Order

| Planned ID | Purpose | Dependency |
|---|---|---|
| WO-2 / AN0.07 | Verify documented RAW key expectations against existing source structures. | Read-only inspection; no RAW/STAGING modifications. |
| WO-2 / AN1.10 | Investigate the observed 33,407-row increase in the assessment join path and isolate its cause. | Reinspect grain and join cardinality; cause remains unproven. |
| WO-2 / AN2.10 | Extend the descriptive analysis of IMD missingness, including presentation and region patterns. | Preserve denominators; do not infer missingness mechanism or causation. |
| WO-2 / AN3 | Analyze final outcomes, registration status, and withdrawal patterns with explicit denominators and date semantics. | Use validated student-presentation keys. |
| WO-2 / AN4 | Analyze assessment structure, dates, weights, submission coverage, scores, and banked submissions. | Use validated assessment metadata join. |
| Later AN5 | Compare R0/R1/R2 activity definitions and document sensitivity. | Define the engagement question first; investigate repeated-key semantics without modifying RAW/STAGING. |

## Repository actions

| Action | Branch / PR | Verified outcome |
|---|---|---|
| Created pre-documentation safety branch | `backup/pre-wo1-documentation-2026-10-30` | Created from the working branch at `7e28dbbc390da99f80eb0ee755b7da39fc0854d5`, preserving the pre-documentation state. |
| Saved executed analytical notebook | `work/wo1-reconciliation-cells` | Commit `fab3a99b5223940443ae9e5f10edea893cb301ce`; local and remote branch heads were previously verified identical by the project owner. |
| Pull request #1 | `work/wo-1-analytical-readiness` → `main` | Merged on 2026-10-29; merge commit `0201b758f966ff514f8c187aa462c1b22330cb83`. |
| Pull request #2 | `work/wo1-reconciliation-cells` → `main` | Squash-merged on 2026-10-30; merge commit `91d3369b41e7cfb39c0d58f87ef6f105291c1107`. |
| Documentation consistency updates | PR #3: `docs/wo1-documentation-consistency-2026-10-30` → `main` | Squash-merged on 2026-10-30; merge commit `2d78f16c0bb3097250eb6b498c68886ef0b6a90e`. |

## Current analytical handover

The WO-1 execution evidence and targeted category reconciliations are retained in `main` through PR #2. The local notebook was saved, committed, and synchronized to the remote working branch at `fab3a99`, as previously verified by the project owner.

The WO-1 notebook evidence and documentation consistency updates have been integrated into `main` through PRs #2 and #3. PR #4 subsequently corrected the repository integration record. The local working-tree state after these merges has not yet been independently verified.

WO-2 is sequenced as one bounded work-order package: first AN0.07, AN1.10, and AN2.10 to close the remaining readiness questions; then AN3 outcomes and withdrawal; then AN4 assessment analysis. This ordering keeps the remaining AN0–AN2 validation ahead of the dependent interpretation work while avoiding unnecessary re-execution of completed diagnostics. The execution status of the three follow-up checks is not established by the evidence reviewed.

AN5 remains separate because the repeated `student_vle` candidate-key semantics and the implications of R0/R1/R2 have not been resolved. AN6 depends on an approved activity definition. Power BI and predictive modelling remain downstream of validated analytical outputs.

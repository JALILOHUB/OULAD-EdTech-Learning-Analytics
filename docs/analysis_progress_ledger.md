# OULAD Analysis — Progress Ledger

Updated: 2026-11-22

## Current authoritative snapshot — AN8 Part 2 review and Part 3 preparation

- **Roadmap:** AN8 remains OPEN pending integrated diagnostics, metric contracts, and reporting-output approval. AN9 Power BI remains blocked. AN10 predictive readiness and AN11 final consolidated report remain downstream. Separate ML training is not authorized.
- **Verified local execution evidence reported by owner and saved in Notebook 10:** AN8.01–AN8.04, AN8.10–AN8.12, AN8.20, and AN8.30–AN8.36. Export manifest: 15 query records, 17 CSV result sets, 37,584 rows, six passing gates, zero export errors. The CSV review cells 17.00–18.1 are saved with execution counts and visual outputs; final inventory assertion passed.
- **Key evidence:** cohort 32,593 student-presentations; Pass 12,361, Withdrawn 10,156, Fail 7,052, Distinction 3,024. Registration dates: 32,312 before start, 234 after, 2 on start, 45 missing. Withdrawal/date conflicts: 93 Withdrawn without unregistration date and 9 Fail with date. Score states: 173,410 nonzero, 329 observed zero, 173 NULL.
- **Concrete AN8.30 finding:** R0 = 10,655,280 rows / 39,605,099 clicks. R1 = 9,868,110 rows / 38,343,063 clicks (787,170 fewer rows; 1,262,036 fewer clicks; 7.39%/3.19% reduction). R2 = 8,459,320 rows / 34,402,738 clicks (2,195,960 fewer rows; 5,202,361 fewer clicks; 20.61%/13.14% reduction). 1,614,505 repeated five-key groups; 1,179,074 with multiple click values; maximum group size 10. Neither R1 nor R2 is accepted as source truth.
- **Temporal/activity finding:** 688,988 pre-course rows (6.47%) and 2,147,947 pre-course clicks (5.42%); 9,966,292 in-course rows; no post-course/no-course-window rows in the saved reconciliation. 3,365 student-presentations have no recorded activity row. 45 have unknown registration-relative exposure.
- **New Notebook 10 work:** Sections 19–20 add integrated diagnostics for activity reconciliation, scenario impact, zero-inclusive distributions, exposure, outcome heterogeneity, assessment states, profile missingness/small cells, and an evidence-to-decision register. These 16 cells are PREPARED, NOT EXECUTED. Their computed summaries are not verified.
- **Reports and plans:** `reports/AN8_part2_analytical_findings_report.md` created; `docs/AN8_part3_deep_cleaning_analysis_plan.md` created. Updated `docs/AN8_implementation_specification.md`, `docs/AN8_phase1_execution_handover.md`, `reports/AN8_initial_results_and_scope_extension.md`, and `docs/analysis_log.md` to distinguish completed extension from pending integrated diagnostics.
- **Part 3 direction:** purpose-specific, versioned derived datasets only. First investigate repeated-row semantics; temporal/pre-course definitions; 45 unknown registration dates; 3,365 no-recorded-activity records; assessment-opportunity/banked/NULL/zero states; profile missingness and small cells; presentation heterogeneity. Preserve original files and RAW/STAGING. No blanket deletion, imputation, or deduplication.
- **Repository:** branch `feat/an8-csv-review-visualizations`, PR #27 open, draft, unmerged. Base `feat/an8-preparation-review`. Latest Notebook 10 and report/plan updates are on the feature branch. No merge attempted. The user's local branch and working tree still require confirmation after sync.
- **Safety:** no SQL rerun, database connection, persistent database object, index, source modification, or Power BI build occurred during this review/update. No model training occurred.
- **Next work order:** synchronize the feature branch locally; run Notebook 10 Sections 19–20 only (after CSV section DataFrames are loaded); synchronize the saved Notebook back to the same branch; then finalize the Part 2 report and LinkedIn visual/post using the now-complete diagnostics. After Part 2 closure, execute Part 3 packages from the dedicated plan.

---

## Current authoritative snapshot — 2026-11-19 (AN8 CSV review preparation)

- **Roadmap:** AN8 — Validated Metrics & Curated Reporting Tables remains OPEN. AN9 Power BI remains blocked pending metric and reporting-contract validation. AN10 Predictive Readiness Gate and AN11 Consolidated Final Analytical Report remain downstream. The separate Data Science / ML phase remains deferred.
- **Owner-reported AN8 execution evidence:** the owner previously executed AN8.03, AN8.10–AN8.12, AN8.20, and AN8.30–AN8.36 and verified the export locally. The export contains 15 query records, 17 CSV result files, 37,584 rows, zero export errors, and six passing gates. PowerShell verification on 2026-11-19 confirmed that `outputs/an8/extracts/an8_execution_manifest.json` exists and that the directory contains 17 CSV files. No AN8 SQL was executed during this repository repair.
- **Reviewed results retained:** AN8.03 outcome denominators reconcile to the 32,593 student-presentation cohort; AN8.10 reports 45 missing registration dates; AN8.11 preserves withdrawal-date states; AN8.12 distinguishes 173 NULL scores and 329 observed zero scores. AN8.20 contains 32,593 student-presentation rows, with the 45 missing-registration-date cases retained as NULL in the registration-relative measures. AN8.30 R0/R1/R2 remain sensitivity scenarios, not approved source-cleaning rules. AN8.31–AN8.36 are descriptive extracts; candidate metrics remain unapproved and final_result remains retrospective.
- **Notebook 10 CSV review:** added 17 CSV-specific loading/display cells and dedicated visualizations, explanatory interpretation boundaries, a cross-result review, and Part 3 investigation prompts. The new section starts at cell 17.00 and reads only local CSV files and the manifest. Its setup does not import or call the AN8 database runner, open PostgreSQL, rerun SQL, or load the full `student_vle` table.
- **CSV setup repair:** replaced the incomplete setup cell with a standalone initializer that locates the project root from the manifest, verifies all six export gates, the exact 15 query IDs, 17 result-set entries, 37,584 manifest rows, non-truncated result sets, exact local CSV/manifest filename parity, and each CSV's row/column contract when loaded. Updated the two boxplots to use Matplotlib's `tick_labels` parameter for the pinned dependency version.
- **Static verification boundary:** the notebook JSON was parsed after the edits; the manifest structure was checked against `scripts/run_an8.py`; output-field assumptions were cross-checked against the canonical AN8 SQL files where available. The CSV section has NOT been executed against the owner's local files in this environment. Python runtime behavior, every chart, and the final inventory output remain pending local verification.
- **Repository:** branch `feat/an8-csv-review-visualizations`, based on `feat/an8-preparation-review`. Draft PR #27 remains OPEN and UNMERGED; the latest branch head is `90e0af72b1c3d17a7c162dce83b87cbdaa95f14d`. The PR contains the Notebook 10 changes and this progress-ledger update. GitHub currently reports `mergeable=false`; no merge was attempted. The owner’s local branch/HEAD and working-tree state have not been rechecked during this repair.
- **Safety:** no database connection or SQL execution occurred during this repair; no RAW, QUALITY, or STAGING data changed; no persistent database objects, indexes, marts, KPI approvals, cleaning decisions, or Power BI datasets were created.
- **Next work order:** synchronize the named feature branch locally while preserving the pre-sync modified notebook copy; restart the Jupyter kernel; execute cell 17.00 and then run the remaining cells in the CSV-review section only. Do not rerun earlier SQL/preflight cells. Review the actual loader checks, charts, and 17-result-set inventory; report any traceback before changing source. Keep PR #27 open until local execution and review are complete.

---

## Current authoritative snapshot — 2026-11-17 (AN8 initial execution and extension)

- **Roadmap:** AN5–AN7 closed within approved scopes. AN8 — Validated Metrics & Curated Reporting Tables is OPEN. AN9 Power BI is blocked pending AN8 metric and reporting-contract validation. AN10 Predictive Readiness Gate follows AN9; AN11 is the consolidated final analytical report. A separate Data Science / ML phase remains conditional on AN10 and analytical-phase exit criteria.
- **AN8 execution evidence:** owner-executed local Notebook 10 outputs verify AN0.01 and AN8.01–AN8.04, AN8.10–AN8.12, AN8.20, export, and Python reconciliation. The saved outputs show 32,593 validated student-presentations; 10,655,280 source activity rows; 39,605,099 recorded clicks; zero unmatched activity rows; 9,966,292 in-course rows; and 688,988 pre-course rows. The notebook has not been re-executed during this repository update.
- **AN8 extended scope:** AN8.30–AN8.36 SQL and Notebook 10 cells are prepared but NOT EXECUTED. Their outputs must not be reported as findings. AN8.30/31/34 are high-cost and must run individually; AN8.32/33/35/36 are separately gated by the runner. Course-context validation is required before activity/exposure/assessment analyses.
- **AN8 report:** `reports/AN8_initial_results_and_scope_extension.md` records initial outputs, analytical gaps, the approved extension, and cleaning rationale.
- **Data-cleaning decision:** the owner intends to preserve a copy of the local `data` directory (reported 487 MB) outside the project before any local cleanup. Backup completion is not verified. Original files and RAW remain evidence; purpose-specific derived datasets may be cleaned under documented, reversible rules with row/key impact and metric sensitivity evidence. No blanket deletion or automatic deduplication is approved.
- **Notebook 05:** expanded from a three-section placeholder into a Python advanced-analysis workbench. This is prepared documentation only; no statistical tests, feature engineering, or ML execution is claimed.
- **Safety:** RAW, QUALITY, and STAGING unchanged; no database DDL, tables, views, materialized views, indexes, or data loads created; no PR or merge reported. Local synchronization and Windows working-tree status remain unverified.
- **Next work order:** owner completes and verifies the external source-file backup; then synchronizes this branch, checks the local diff, and executes AN8.30–AN8.36 through the read-only runner in the documented order. Review all result sets before deciding which cleaning scenarios and derived datasets are justified. Do not start Power BI or ML yet.

---

## Current authoritative snapshot — 2026-11-16 (AN8 preparation review)

- **Roadmap:** AN5–AN7 remain closed within their approved scopes. The current sequence is AN8 — Validated Metrics & Curated Reporting Tables; AN9 — Power BI; AN10 — Predictive Readiness Gate; AN11 — Consolidated Final Analytical Report; any Data Science / Machine Learning phase remains separate and conditional on AN10 and analytical-phase exit criteria.
- **AN8 status:** PREPARATION ONLY — NOT EXECUTED. No AN8 SQL has been run against PostgreSQL, no AN8 metrics have been validated, no extract CSV/manifest has been produced from a live run, and no curated reporting objects have been created or loaded.
- **Repository checkpoint:** working branch `feat/an8-preparation-review`, based on `main` at `44af2a2117e524b469e3cf8df9ee77e9f863f250`. The branch was updated with the preparation corrections recorded in this snapshot. Local synchronization and Windows working-tree status remain unverified. No PR or merge is authorized or reported.
- **Current AN8 design:** retain the registered student-presentation grain; STAGING remains the analytical source; preserve all R0 `student_vle` rows. AN8.01 is catalog-only; AN8.02 is a hard grain/key-set gate; AN8.03 is a retrospective denominator profile; AN8.04 returns course and assessment result sets; AN8.10–AN8.12 provide descriptive context; AN8.20 is the sole high-cost consolidated activity scan. AN8.21–AN8.23 are retired; AN8.30–AN8.32 are deferred; AN8.33/AN8.40/AN8.41 remain SELECT-only proposals.
- **Architecture decision:** source extraction remains strictly read-only through `src.analytics.db`. Curated reporting deployment will be direct programmatic Python/Psycopg, independent of pgAdmin, through a separate least-privilege write component with explicit object allowlists, validated retained extracts, transactional rollback, and post-load reconciliation. This is a design decision only; the component, DDL, grants, and data loads are not implemented or authorized.
- **Prepared static corrections in this work order:** strengthen AN8.01/AN8.02/AN8.03/AN8.04 and AN8.20 execution gates; prevent export before complete reviewed extracts; protect AN8.20 against accidental repeat attempts; add query-file hashes and non-sensitive execution metadata to the export manifest; align architecture, AN8 specifications, SQL inventory, notebook guidance, and this ledger. These are repository changes, not database execution evidence.
- **First local batch after synchronization and file confirmation:** `AN0.01 → AN8.01 → AN8.02 → AN8.03`. Then review AN8.04 and AN8.10–AN8.12. Run AN8.20 once, alone, only after all gates and outputs are reviewed. Preserve complete result sets under ignored `outputs/an8/extracts/`.
- **Open validation:** local branch synchronization; static Python compilation and notebook JSON validation in the project environment; PostgreSQL SQL syntax/runtime; actual gate outputs; AN8.20 source-row/click/temporal reconciliation and AN6 comparison; retained CSV/manifest review; curated mart contract; separate write-path implementation and approval; deployment and post-load validation.
- **Safety:** no RAW/QUALITY/STAGING modifications, no deduplication/deletion, no indexes on `staging.student_vle`, no persistent DDL or loads, no KPI/threshold/weighted score/ranking/predictive feature approval, no ML training, no PR, and no merge.
- **Next work order:** complete static remediation and validation of AN8 preparation files, then request local synchronization and the first read-only execution batch. Do not mark any AN8 query executed until owner-supplied local evidence is reviewed.

---


Updated: 2026-11-14

## Current authoritative snapshot — 2026-11-14 (AN7 analytical closeout)

- **Roadmap:** RAW / QUALITY / STAGING engineering foundation complete within documented scope; WO-1 and WO-2 complete; AN5 CLOSED; AN6 CLOSED and merged; **AN7 analytically CLOSED** for its approved observational scope; AN8 Validated Metrics & Marts is the next workstream; AN9 Power BI follows; the former AN8 Predictive Readiness Gate is renumbered AN10 and scheduled after Power BI; AN11 is the consolidated final analytical report. GitHub Release v1.1.0 was published on 12 November 2026 for the completed investigative milestone through AN6. The separate Data Science / ML phase remains deferred until the analytical phase exit criteria are met.
- **AN7 execution evidence:** owner-executed, read-only AN7.01–AN7.05 are retained in `notebooks/09_an7_outcome_associations.ipynb`. Seven result sets were returned: AN7.01 = 20 + 15 + 22 rows (0.121 s); AN7.02 = 171 (0.010 s); AN7.03 = 32,593 (0.405 s); AN7.04 = 32,593 (96.683 s); AN7.05 = 32,593 (93.835 s). Total SQL-file batch runtime: 191.054 s. AN7.04 and AN7.05 ran sequentially. No result truncation was reported.
- **Notebook evidence:** the reviewed pre-closeout notebook blob was `a61a9f777327505272ddce1ab7e579fb743ef5b9`: 73 cells, 32 Python code cells, all 32 with execution counts; 30 cells produced saved outputs, while two setup/helper-definition cells intentionally have no display output. The closeout revision preserved all original code cells, execution counts, and outputs, and added the result-specific sensitivity interpretation. The subsequent visual-review revision contains 77 cells. Before the latest source refinement, 33 Python code cells had execution counts and the final visualization cell had nine saved figures from retained CSV exports. The current refinement standardizes series colors across paired charts, adds explicit one-to-one key and 22-presentation denominator assertions, derives timing-chart labels from the validated denominator, and retains the legend below the chart. Its prior saved figures have been cleared because they do not represent the revised source. The notebook now retains 32 executed Python code cells; only the final visualization cell is pending owner execution. It reads retained CSV exports only and does not run SQL or statistical analysis.
- **Reconciliation:** 32,593 registered student-presentations; 28,785 distinct people; 28,500 in-course activity-bearing registrations; 9,966,292 in-course source activity rows; 28,500 resource-bearing registrations; zero NULL resource-key groups. AN7.03–AN7.05 each reconcile to 32,593 unique full three-column keys; the one-to-one merge retains 32,593 rows. Pre-course active days: 107,752; registrations with at least one pre-course active day: 23,809. No in-course active day preceded known registration.
- **O1:** median Cliff's delta ranges from -0.178 to -0.197; 20–22 of 22 presentation estimates are negative, and 18–19 CIs are wholly below zero. The direction is broadly consistent, but some presentation intervals include zero.
- **O2:** median Cliff's delta ranges from -0.407 to -0.572; all 22 presentation estimates are negative at every landmark-feature combination, and all reported CIs are wholly below zero.
- **O3:** median Spearman rho ranges from 0.340 to 0.470; all 22 presentation estimates are positive at every landmark-feature combination, and all reported CIs are wholly above zero.
- **Sensitivity:** 660 presentation-level rows (132 primary O1, 132 alternative O1 including eligible undated Withdrawn cases, 132 O2 excluding Fail/date-unregistration cases, 264 O1 timing-stratum rows) and a 30-row summary. O1 retained direction in 130/132 paired comparisons; the two sign changes were near-zero resource-breadth estimates in GGG/2013J at L56/L84. Median absolute paired change ≈0.00166; maximum ≈0.06233. O2 remained negative in 22/22 presentations after exclusion. The on/before-start stratum broadly reproduced primary O1. The after-start stratum had 12/22 estimable and 10/22 non-estimable estimates; median comparison-group size 5 (range 1–49), so no strength claim is justified.
- **Decisions:** active-day rate is the primary candidate for AN10 predictive-readiness review; resource breadth is secondary because it is not exposure-normalized. Neither is an approved production KPI or predictive feature. Keep final_result as outcome only; preserve the 93/9 anomalies, 45 missing registration dates, 11 missing assessment due dates, 173 NULL scores, and 329 genuine zero scores. Do not infer score availability from due dates or truncate activity at unregistration.
- **Limitations:** observational design; changing landmark risk sets; repeated people across presentations; resource-breadth exposure sensitivity; same-day temporal ambiguity; score/feedback publication times unavailable; unresolved repeated student_vle source semantics; no multiple-comparison adjustment; unmeasured confounding. No causal, predictive-performance, intervention, or model claim is approved.
- **Files prepared on integration branch:** updated Notebook 09, AN7 plan, new `reports/AN7_final_report.md`, five AN7 canonical SQL files, `scripts/run_an7.py`, README, architecture, business questions, notebook README, SQL README, analysis log, progress ledger, and .gitignore. The consolidated `reports/final_report.md` remains a later project deliverable and is not replaced by the AN7 stage report.
- **Repository:** original execution branch `work/an7-outcome-associations` diverged from current main (20 ahead / 10 behind) after v1.1.0 release updates. A clean integration branch `work/an7-outcome-associations-closeout` was created from current main. PR #19 was squash-merged into main on 2026-11-14; merge commit `a3c321bc1536aec81c82541da77085e39784cd8e`. It integrated 18 changed files while preserving the v1.1.0 release baseline. The original execution branch's 32 Python code cells, execution counts, and saved outputs match the integrated Notebook 09 exactly; `main` adds one explanatory Markdown cell. The AN7 runner and all five canonical SQL files have identical blob SHAs on the original branch and `main`. Its remaining documentation is older than the integrated closeout. It is safe to delete after local synchronization.
- **Database and source safety:** no SQL was rerun during closeout; no database connection was made; no persistent database object or index was created; RAW, QUALITY, and STAGING were not modified; no source row was deleted, deduplicated, or aggregated.
- **Publication backlog:** prepare the AN7 closure LinkedIn post and visual only from this validated evidence; publication remains subject to owner approval. A two-part AN7 LinkedIn draft and two evidence-led motion-visual prompts have been prepared in the project handover. Publication and visual rendering remain subject to owner approval; no post has been published.
- **Next work order:** AN7 is integrated into main. The approved next workstream is AN8 — Validated Metrics & Marts, followed by AN9 — Power BI, AN10 — Predictive Readiness Gate, and AN11 — Consolidated Final Analytical Report. Do not begin ML before the analytical phase exit criteria and AN10 decision.

## Repository cleanup and roadmap decision — 2026-11-14

- Verified `main` head before this documentation branch: `b1eb092255525299814f6360e4d824016f90f0f5` (PR #21 documentation clarification is present).
- Confirmed AN7 closeout commit `a3c321bc1536aec81c82541da77085e39784cd8e`, follow-up documentation commits `6e68f3bf1be1e392895d3cfc373e46a4b865f955` and `b1eb092255525299814f6360e4d824016f90f0f5` are already on `main`.
- Reviewed 23 remote branches: `main`, two intentional backup branches, and 20 temporary branches. Branches fully behind `main` have no unique commits; divergent branches were checked against current file content. The retained AN5/AN7 notebook execution evidence, SQL files, runners, and current documentation are present in `main` or superseded by newer `main` versions. All 20 temporary branches are deletion candidates after local synchronization. No remote branch was deleted because the connected GitHub interface does not expose a branch-delete operation. Keep both backup branches.
- `work/an7-outcome-associations-closeout` contains the same Notebook 09 blob and identical five AN7 SQL files and runner as `main`; its AN7 closeout content is integrated. Its notebook, runner, and five canonical AN7 SQL files match `main`; the documentation versions on the branch are older than the current main versions. Its 22-commit history is represented by the squash-integrated AN7 content. It is safe to delete after local synchronization.
- `work/an7-outcome-associations` is the older execution branch and is not a deletion candidate until its unique commit history and notebook evidence are reconciled with the integrated closeout.
- The next-stage sequence is formally revised: AN8 — Validated Metrics & Marts; AN9 — Power BI; AN10 — Predictive Readiness Gate; AN11 — Consolidated Final Analytical Report. Data Science / ML remains a separate subsequent phase, conditional on analytical-phase exit criteria and the AN10 decision.
- PR #22 (`docs: align repository status and analytical roadmap after AN7`) was squash-merged into `main` at `7130d9dba315561a2134c432d0d373a13613ea7a`. PR #23 (`docs: finalize current roadmap wording in project records`) was squash-merged at `db01d3d144c121f5e203a58c4eae423ab3195cd6`. Both were documentation-only. Local repository synchronization remains unverified.

---

# OULAD Analysis — Progress Ledger

Updated: 2026-11-12

## Historical snapshot — 2026-11-12 (superseded by the 2026-11-14 snapshot)

- **Main baseline:** `main` points to `4b707623e5dc0ecf16e93311c2b466d822ad9d35`, the verified merge commit for PR #16. PR #16 is closed and merged; AN6 is integrated.
- **Completed analytical investigations:** WO-1 and WO-2 are complete within their documented scopes. AN5 — Engagement Sensitivity and AN6 — Recorded VLE Activity Patterns are closed. Their execution evidence and limitations remain in the retained notebooks, plans, analysis log, and merged PR records.
- **AN5 evidence:** five read-only investigations, eight result sets, 623 retained rows, quantitative sensitivity review, and eight visual summaries. R0 preserves all source rows; R1/R2 are metric-only sensitivity alternatives. Overall any-window activity coverage is 89.68%.
- **AN6 evidence:** four read-only investigations and six complete, untruncated result sets. Registered student-presentations: 32,593; in-course activity-bearing: 28,500 (87.44%); outside-window-only: 728; no recorded activity in any observed window: 3,365. Temporal summaries reconcile to 10,655,280 activity rows: 9,966,292 in-course and 688,988 pre-course. All activity rows match resource metadata; no unmatched resource, missing activity_type, or unmatched-registration activity rows were returned.
- **AN6 interpretation boundary:** these are recorded platform activity measures, not learning quality, attention, effort, achievement, or causality. Activity-row/click volumes remain sensitive to unresolved repeated source-row semantics. No production KPI, composite score, causal claim, intervention threshold, or predictive feature was approved.
- **Historical AN7 status at this checkpoint (superseded):** the package was prepared on `work/an7-outcome-associations`; 11 commits ahead of `main`, 0 behind at that earlier review. The statement that the five SQL investigations had not been executed and Notebook 09 was unexecuted was correct only at that historical checkpoint. The owner subsequently executed AN7 locally; the verified execution, findings, and analytical closure are recorded in the 2026-11-14 snapshot at the beginning of this ledger.
- **Documentation release closeout:** PR #17 (`docs: reconcile repository status for v1.1.0 release`) is open from `docs/v1.1.0-release-readiness` to `main`. It changes only `README.md`, this ledger, `docs/architecture.md`, and `reports/final_report.md`. No database, SQL, analytical notebook, or AN7 branch content is changed.
- **Proposed release:** `v1.1.0` is a proposed stable milestone for completed investigations through AN6 only. It has not been tagged or published. The release point must be the eventual documentation PR merge commit after review, not the AN7 branch or the current pre-closeout main commit.
- **Outstanding analytical roadmap:** AN8 predictive-readiness gate; AN9 validated metrics and curated analytical marts; AN10 Power BI; AN11 final evidence-based analytical report. The separate Data Science / Machine Learning phase remains deferred until the analytical phase is complete and a justified readiness decision is approved.
- **Repository hygiene:** remote branches were inventoried. Preserve `backup/pre-an5-integration-2026-11-07` and `backup/pre-wo1-documentation-2026-10-30` as intentional historical recovery points. Zero-ahead branches that are cleanup candidates after local synchronization: `docs/wo2-an5-consistency-2026-11-06`, `docs/wo2-an5-consistency-resolved`, `work/an5-engagement-sensitivity`, `work/an5-engagement-sensitivity-resolved`, `work/wo2-execution-foundation`, `work/wo2-pre-execution-readiness`, and `work/an6-recorded-vle-activity-patterns`. Do not delete diverged branches until their unique commits are reviewed: `backup/pre-wo1-documentation-2026-10-30`, `docs/ops-repository-consistency-2026-10-31`, `docs/record-consistency-closeout`, `docs/repository-consistency-and-an6-readiness`, and `work/an5-five-query-execution`. `work/an7-outcome-associations` is active and must be retained. No branch has been deleted.

The dated entries below are retained as a chronological audit trail. Earlier statements that PR #16 is open/unmerged, AN6 is the next workstream, or AN7 is not yet authorized are historical checkpoints and are superseded by this snapshot.

## Historical snapshot — 2026-11-11 (superseded by the 2026-11-12 snapshot)

- **AN6 — Recorded VLE Activity Patterns: CLOSED.** Owner-supplied local execution evidence is retained in `notebooks/08_an6_recorded_vle_activity_patterns.ipynb`: AN6.01 returned 3 result sets; AN6.02 returned 88 rows; AN6.03 returned 971 rows; AN6.04 returned 254 rows. All six result sets were complete and untruncated. Batch runtimes: AN6.01 27.348 s; AN6.02 156.565 s; AN6.03 154.189 s; AN6.04 247.918 s.
- AN6.01 readiness passed for 22 module-presentations, 6,364 course-scoped resource keys, 32,593 registration keys, complete activity-key components, and matching course windows. AN6.02 partitioned 32,593 registered student-presentations into 28,500 with in-course activity (87.44%), 728 outside-window-only, and 3,365 with no recorded activity in any observed window.
- AN6.03 reconciled temporal-bucket and relative-period totals independently to 10,655,280 activity rows; AN6.02/AN6.03 denominators and in-course reach matched; all 88 boundary diagnostics were present. Returned buckets were IN_COURSE (9,966,292 rows; 93.53%) and PRE_COURSE (688,988; 6.47%); no POST_COURSE bucket was returned.
- AN6.04 reconciled all 10,655,280 activity rows to resource metadata, with zero unmatched resource rows, zero missing activity_type rows, and zero unmatched-registration activity rows. In-course activity-type totals reconciled across all 22 module-presentations. VLE week_from and week_to each remain missing in 5,243 of 6,364 resource rows; overlap/distribution of these missingness sets was not tested.
- Notebook review: removed the duplicate Section 13 Markdown cell (including its duplicate cell ID) and the final empty code cell; corrected the stale Figure 1 saved-output note. All 12 executed code cells, SQL outputs, figures, and reconciliation outputs were preserved. No SQL or notebook code cell was rerun during documentation closeout.
- AN6's operational scope remains descriptive recorded VLE activity, not learning quality, engagement quality, causality, an approved KPI, a composite score, a threshold, an intervention rule, or a predictive feature. RAW, QUALITY, and STAGING remain unchanged; no persistent database objects or indexes were created.
- **Next workstream:** AN7 — Outcome Associations, not yet authorized. Before AN7 SQL is designed, freeze outcome/withdrawal definitions, is_banked and CMA semantics, assessment-weight/score coverage, and leakage-safe observation cutoffs.
- PR #16 remains open and unmerged. The owner-reported local/remote synchronization at `b9effc8` and clean working tree occurred before the documentation-closeout commits in this update. The remote PR branch has advanced with the closeout documentation commits; the local branch must be synchronized again before further local work. GitHub comparison confirms the PR branch is ahead of `main` and not behind; no merge to `main` was performed.

## Historical snapshot — 2026-11-08

- AN6 package prepared on `work/an6-recorded-vle-activity-patterns`, based on `main` commit `81b25b0f9839ceb75d1f9039df743e8e3618c6cd`. Four canonical read-only SQL files, one Python runner, one notebook, and one plan are added; six existing documentation/configuration files are updated. Static review confirms required SQL headers and read-only statement content; the notebook JSON is valid with seven unexecuted code cells. PR #16 is open and unmerged for review. No AN6 SQL has executed and no database findings are approved.
- Local synchronization verified on 2026-11-08: the local branch is tracking `origin/work/an6-recorded-vle-activity-patterns`, the working tree is clean, and both local and remote HEAD match at `aad58ea93ad451a56792b67b321f91d3381d6c09`.
- Expected AN6 result sets: AN6.01 = 3; AN6.02 = 1; AN6.03 = 1; AN6.04 = 1 (six total by design). AN6.01 is the mandatory readiness gate; the runner and notebook require AN0.01 preflight and sequential execution.

## Current authoritative snapshot — 2026-11-08

- Repository baseline for the consistency review: `main` at `6f2bc9b88fd55c641c1d9ec8f38a262aac46c1eb`. PR #13 was squash-merged by `17766f03ec87ac2deebefc763006053addf46281`. The subsequent repository-consistency PR #14 was squash-merged on 2026-11-08 as `72133e9c3603222da730b8a2a21ed4b38bb0bd05`.
- WO-1 and WO-2 are complete within their documented investigative scopes. WO-2 retains 21 executed canonical queries, 28 result sets, 857 displayed rows, 34 executed code cells, no saved tracebacks, and no runner row-cap truncation. This documentation review did not reconnect to PostgreSQL or rerun SQL.
- AN5 — Engagement Sensitivity is **CLOSED**. Five read-only investigations, eight expected result sets, 623 retained rows, quantitative review/export, and eight visualizations are recorded in `notebooks/07_an5_engagement_sensitivity.ipynb`. The accepted definition is in Section 17 of `docs/AN5_engagement_sensitivity_plan.md`.
- Accepted activity grain: one registered student-presentation `(code_module, code_presentation, id_student)`, joined on all three columns. The in-course window is relative day 0 through `module_presentation_length`, inclusive. Pre-course and post-course activity remain separate diagnostics.
- The 89.68% AN5.02 result is overall any-recorded-activity coverage, not in-course-only coverage. AN6 must calculate its own in-course numerator and denominator.
- Primary AN6 dimensions: in-course recorded activity presence/coverage, distinct in-course active days, and distinct in-course `id_site` values. Click volume remains secondary and scenario-sensitive.
- R0/R1/R2 remain metric-only sensitivity alternatives. No source deduplication rule, composite engagement score, causal claim, intervention threshold, or predictive feature is approved. RAW, QUALITY, and STAGING remain unchanged.
- Next work order: AN6 design and pre-execution metric contract. No AN6 SQL has been executed or approved in this snapshot. AN7 remains downstream and requires explicit outcome definitions and leakage-safe temporal design.
- `requirements.txt` was inspected as UTF-8 with BOM and CRLF line endings; a previous description of it as UTF-16 LE was incorrect. No dependency versions or packages were changed in this consistency pass.
- Repository-only review does not verify local synchronization, local working-tree state, or the current local database state.

## Repository consistency and WO-2 documentation closeout — 2026-11-08

PR #14, `docs: reconcile project records and close AN5 handover`, was squash-merged into `main` as `72133e9c3603222da730b8a2a21ed4b38bb0bd05`.

### Files reconciled

- `README.md`, `docs/architecture.md`, `docs/analysis_log.md`, and `docs/analysis_progress_ledger.md`: current state, AN5 closure, next work order, and historical supersession labels.
- `docs/AN5_engagement_sensitivity_plan.md`: superseded pre-closure checkpoint qualified; Section 17 remains the authoritative accepted definition and AN5 closure.
- `sql/04_analytics/README.md`: five-query AN5 inventory, execution status, and retained unexecuted engagement template clarified.
- `sql/04_analytics/AN3.07_outcome_rates_by_attempts_education.sql`: expectation text now matches the category-level small-group flag; SQL logic is unchanged.
- `notebooks/05_wo2_analytical_investigation.ipynb`: interpretation and closeout notes completed from retained outputs; the false statement that the notebook contained no saved outputs was corrected. All 34 saved code-cell execution counts and outputs were preserved.
- `notebooks/00_project_plan.ipynb` and `notebooks/03_data_quality.ipynb`: repository-facing prose standardized to professional English; the project plan now reflects AN5 closure and AN6 as the next work order.
- `notebooks/01_data_access_and_source.ipynb`, `02_data_profiling.ipynb`, `05_wo2_analytical_investigation.ipynb`, and `07_an5_engagement_sensitivity.ipynb`: machine-specific absolute project paths replaced with portable `<project-root>` references; retained outputs were not removed.
- `notebooks/README.md` and `reports/final_report.md`: AN5 and downstream reporting status clarified; new notebook naming and execution conventions documented.

### Validation boundary

- The original OQ-01–OQ-09 identifiers were recovered from Git history and restored; new administrative tracking questions begin at OQ-10.
- `requirements.txt` is UTF-8 with BOM and CRLF line endings, not UTF-16 LE. No dependencies were changed.
- The analytics SQL logic, database schema, RAW, QUALITY, and STAGING data were not changed. No SQL was rerun and no notebook was re-executed.
- The WO-2 notebook remains 92 cells with 34 saved executed code cells. The AN5 notebook retains its eight result sets and eight visualizations.
- GitHub confirms PR #14 merged. Local working-tree synchronization and local PostgreSQL state remain unverified.

### Next work order

Prepare the AN6 — Recorded VLE Activity Patterns package from the accepted AN5 entry contract. Freeze the business question, grain, eligible registration population, in-course numerator/denominator, active-day and resource-breadth definitions, temporal diagnostics, scenario policy, join/cardinality checks, and acceptance criteria before authoring canonical SQL. No AN6 query is marked executed at this point.

The chronological entries below are retained as an audit trail. Any former status or next-step instruction that conflicts with this snapshot or the later dated closure record is historical and superseded; its original wording is preserved for provenance.

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

## Historical snapshot — 2026-11-06

This section records the state verified on 2026-11-06. It is retained as a historical checkpoint; the 2026-11-07 AN5 closure and repository integration records supersede its former current-status statements and next-step instructions. Historical references to synthetic tests and GitHub Actions are retained only as history and are superseded by the 2026-11-06 retirement decision.


## Historical repository decision — 2026-11-06

- WO-2 PR #9 and PR #10 are merged into `main`; the saved 21-query execution evidence remains in `notebooks/05_wo2_analytical_investigation.ipynb`.
- Documentation PR #11 and AN5 preparation PR #12 are also merged into `main`.
- Merge commits: #9 `937fa7d0012775b92ba3d30d2897742ab8381222`; #10 `f58ca14800a447b1cc6498c979070ec54419a6ca`; #11 `2303e83f6e522883545172e7e48448c83203a4bf`; #12 `541b4237fe7df677d1a0c49ed077dc1ddb38d889`.
- GitHub Actions and synthetic runner tests are retired. The workflow and synthetic-only test files are absent from `main`. They did not validate the actual OULAD analytical workload and are not acceptance gates. Do not retry historical runner jobs or treat their shutdown signals as analytical failures.
- The project owner reports that repository Actions were disabled in GitHub settings. No workflow definition or synthetic-only test suite remains in `main`; the setting itself was not independently verified through the repository integration.
- Accepted validation evidence: read-only SQL executed against `oulad_analytics`, reviewed result sets, grain/join/denominator reconciliations, retained notebook outputs, and repository diff inspection.
- AN5.01–AN5.03 were the original package; AN5.04 (ranking sensitivity) and AN5.05 (outcome-group activity sensitivity) were the owner-approved additions. The project owner returned saved local execution outputs for all five queries on `work/an5-five-query-execution`. **Historical status at this checkpoint:** AN5 interpretation review remained open. This was superseded by the 2026-11-07 owner acceptance and closure recorded below.

### AN5 execution evidence — 2026-11-06

The project owner returned saved local outputs from `notebooks/07_an5_engagement_sensitivity.ipynb`. The read-only preflight passed on `oulad_analytics`, PostgreSQL 18.6; both read-only settings were `on`.

| Query | Result-set row counts | Batch elapsed seconds |
|---|---:|---:|
| AN5.01 | 1, 3, 66 | 660.747 |
| AN5.02 | 69 | 268.471 |
| AN5.03 | 132 | 456.240 |
| AN5.04 | 66 | 70.314 |
| AN5.05 | 264, 22 | 282.843 |
| **Total** | **623 rows / 8 result sets** | **1,738.615** |

All five SQL files returned the expected result-set counts. No saved SQL traceback or runner-level 500-row truncation was recorded. Batch durations are not per-statement timings or total notebook wall-clock time.

Key visible findings:
- AN5.01: R0 10,655,280 rows; R1 9,868,110 distinct six-column tuples; R2 8,459,320 five-column keys. Excess fully identical rows: 787,170. Five-column groups with multiple `sum_click` values: 1,179,074. R1 is 7.39% below R0; R2 is 20.61% below R0.
- AN5.02 R0 overall: 32,593 registered student-presentations, 28,785 distinct students, 29,228 activity-bearing student-presentations, 3,365 without a matching activity row, and 89.68% coverage. Recorded clicks: 39,605,099; student-active-day pairs: 1,808,119; student-active-site pairs: 1,960,496.
- AN5.03 visible AAA 2013J R0 rows: 10,847 pre-course activity rows and 170,135 in-course rows. Negative relative days remain a distinct category; their cause is unknown.
- AN5.04: high Spearman correlation coexists with individual rank changes. AAA 2013J R0/R1 correlation 0.999703 with 276 of 383 ranks changed; GGG 2014B R0/R2 correlation 0.998118 and top-decile Jaccard 0.8876.
- AN5.05: 264 outcome-group rows; small groups occur. All 22 profile-match diagnostic rows show unique matches and zero missing, duplicate, or conflicting profile matches in this extract. Final result is retrospective descriptive grouping, not a predictor.

The saved pandas HTML output abbreviates long DataFrames even though the runner did not truncate them. Therefore, full totals and presentation-level extrema must come from complete retained DataFrames or CSV exports, not from the abbreviated display.

The notebook now includes interpretation/decision Markdown below each query output and a Python-only review/export cell. That cell calculates scenario deltas, denominator invariants, temporal summaries, ranking ranges, outcome summaries, and profile-match totals, then exports complete retained result sets to the ignored local `outputs/an5/` folder without rerunning SQL. The new cell is unexecuted; the notebook has 24 cells, 9 code cells, 8 previously executed code cells, and one new unexecuted review/export cell.

**Historical decision at the 2026-11-06 checkpoint (superseded):** AN5 was not yet closed because the Python-only review/export cell and owner acceptance were outstanding. The cell was subsequently completed from retained result frames, and AN5 was formally closed on 2026-11-07. No KPI, source-cleaning rule, causal claim, predictive feature, or intervention is approved. AN6 and AN7 remain separate roadmap stages.

### Historical roadmap status — 2026-11-06 (superseded by the 2026-11-14 authoritative snapshot)

| Analytical ID | Current status | Evidence / next dependency |
|---|---|---|
| AN0 — Analytical readiness | WO-1 scope and AN0.07 completed | AN0.07 catalog outputs reviewed: six expected RAW primary keys match; `student_vle` has no primary key; no RAW `student_vle` index rows were returned. |
| AN1 — Grain, keys, and join integrity | WO-1 scope and AN1.10 completed | AN1.10 reconciled the 33,407-row naive-join excess; metadata-aware path returned 173,912 rows and zero unmatched rows. |
| AN2 — Student and presentation profile | WO-1 scope and AN2.10 completed | AN2.10 found 1,111 missing IMD rows across 971 students; no alternative value in the tested comparison. |
| AN3 — Outcomes and withdrawal | WO-2 queries executed and reviewed | AN3.01–AN3.08 saved outputs reviewed; descriptive and denominator caveats retained. |
| AN4 — Assessment analysis | WO-2 queries executed; interpretation review bounded | AN4.01–AN4.10 executed. Separate human review checkpoints are not recorded for each of AN4.07–AN4.10; do not describe every interpretation as individually approved. |
| AN5 — Engagement sensitivity | CLOSED on 2026-11-07 | Five SQL investigations, eight result sets, quantitative review/export, eight figures, and accepted activity definition are retained. See Section 17 of the AN5 plan. |
| AN6 — Recorded VLE activity patterns | Next work order; design not yet executed | Use the accepted AN5 definition; freeze metric contracts and validate presentation lengths, joins, grain, denominators, and missing/unmatched states before SQL. |
| AN7 — Outcome associations | Future | Requires validated measures and explicit hypotheses; association is not causation. |
| AN8 — Predictive readiness | Future decision gate | Requires a defined prediction point, leakage-safe predictors, and temporal validation design. |
| AN9 — Validated metrics and analytical marts | Future | Requires approved metric definitions, grains, denominators, and reconciliation. |
| AN10 — Power BI | Future | Depends on curated reporting outputs and validated metrics. |
| AN11 — Final analytical report | Future | Closes the analytical phase after validated findings, limitations, and recommendations are documented. |

### WO-2 execution evidence

The saved notebook `notebooks/05_wo2_analytical_investigation.ipynb` on `work/wo2-pre-execution-readiness` is the retained execution record. Its reviewed blob SHA is `e94a9d40876fa638718a12152f572ef1562e55d8`.

| Evidence item | Verified saved result |
|---|---:|
| Canonical WO-2 queries executed | 21 / 21 |
| Result sets returned | 28 |
| Displayed rows across result sets | 857 |
| Notebook cells | 92 |
| Code cells executed | 34 / 34 |
| Saved error/traceback outputs | 0 |
| Runner row-cap truncation | None |
| Sum of query-batch elapsed times | 10.099 seconds |

The 10.099-second value is the sum of runner-reported SQL-file batch durations, not an independently measured end-to-end notebook runtime. Pandas text displays may abbreviate middle rows; this is distinct from runner row-cap truncation. AN0.01 preflight and AN1.01 dependency refresh are additional to the 21 canonical WO-2 queries.

### Key WO-2 findings and interpretation boundaries

- **AN0.07:** Six expected RAW primary keys match. `student_vle` has the expected absence of a primary key. The catalog query returned no index rows for `raw.student_vle`; this does not establish uniqueness or justify index creation.
- **AN1.10:** The naive `id_student`-only join returned 207,319 rows versus 173,912 source rows. The 33,407-row excess reconciled to students appearing in multiple presentations. The metadata-aware path returned 173,912 rows with zero unmatched rows.
- **AN2.10:** 1,111 missing IMD rows represent 971 distinct students; all were classified `NO_ALTERNATIVE_VALUE` in the tested comparison. No imputation is approved.
- **AN3.01–AN3.05:** 10,156 Withdrawn student-presentations comprise 10,063 with an unregistration date and 93 without; nine Fail rows also have an unregistration date. These are definition conflicts, not grounds for silently changing outcomes.
- **AN3.04:** The 86.67% withdrawal share for missing registration dates is based on only 45 rows (39 withdrawn), so it is unstable as a general pattern.
- **AN3.06:** Recorded-activity absence is a source-match result, not proof of no learning or no activity elsewhere.
- **AN3.07:** `small_category_flag` tests category totals, not individual outcome cells. Small cells remain possible; align wording and flag semantics before reuse.
- **AN4.02/AN4.04:** Eleven assessments lack due dates; three have 2,865 submission rows in total, while eight have none.
- **AN4.05/AN4.06:** 173 NULL scores are distinct from 329 numeric zero scores. Banked `date_submitted = -1` is a sentinel, not a calendar date.
- **AN4.07–AN4.08:** Outcome and score comparisons are retrospective and cannot be reused as predictors of the same final outcome.
- **AN4.09:** A submission after unregistration does not prove that it was accepted, graded, or valid.
- **AN4.10:** Coverage denominators are status-specific; a student may appear in both banked and non-banked groups. No final weighted-score definition is approved.

### Decisions

| ID | Current decision |
|---|---|
| D-WO2-01 | Accept WO-2 execution as complete for the 21 canonical queries and the saved-output review documented in the 2026-11-06 handover. |
| D-WO2-02 | Treat the saved notebook as historical local execution evidence; this repository review did not reconnect to PostgreSQL or rerun queries. |
| D-WO2-03 | Do not approve KPIs, causal findings, a final weighted score, predictive features, or business rules from WO-2 exploratory outputs alone. |
| D-WO2-04 | Preserve RAW, QUALITY, and STAGING. No persistent database objects were created during WO-2. |
| D-AN5-01 | Compare R0 (all rows), R1 (exact six-column duplicate exclusion for metric calculation only), and R2 (maximum `sum_click` per five-column candidate-key group) without modifying source data. |
| D-AN5-02 | Define the activity measure, grain, common eligible population, time basis, and missing-match handling before interpreting R0/R1/R2 differences. |
| D-AN5-03 | Keep AN6–AN11, KPI/mart approval, Power BI, and predictive modelling dependency-gated. |

### Current open questions

| ID | Question | Status / next action |
|---|---|---|
| OQ-01 | What do repeated `student_vle` rows represent? | Open. AN5 quantified R0/R1/R2 sensitivity but did not establish source-event semantics or a true event grain. Preserve RAW/STAGING; retain R0/R1/R2 as metric-only alternatives. |
| OQ-02 | What do negative relative VLE dates mean? | Open as a source-semantic question. AN5 established a separate pre-course category and its exclusion from explicitly in-course measures; it did not establish the relationship to each student's registration date. |
| OQ-03 | How should missing `date_unregistration` be interpreted alongside `final_result`? | Open. WO-2 documented conflicts: 93 Withdrawn rows without a date and nine Fail rows with a date. No unified withdrawal rule is approved; resolve before AN7. |
| OQ-04 | What explains missing assessment dates, and how do they relate to submissions? | Open. WO-2 found 11 assessments without due dates; three Exam assessments account for 2,865 submission rows. CMA due-date semantics remain unresolved; do not infer lateness without a valid reference. |
| OQ-05 | Why are 173 assessment scores missing and how do they relate to `is_banked`? | Open. WO-2 found 173 NULL scores (172 non-banked TMA and one banked TMA) and 329 numeric zero scores. Missingness and banked semantics remain separate questions; no imputation is approved. |
| OQ-06 | What is the meaning and denominator treatment of `is_banked`? | Open. The observed flag is not a student-level partition; the same student-presentation may appear in banked and non-banked groups. Resolve source semantics and `date_submitted = -1` before AN7 or score metrics. |
| OQ-07 | How do assessment weights behave by presentation and type? | Open. AN4.10 is a grain/coverage diagnostic, not a final weighted-score definition. Zero-weight CMA/TMA components must not be treated as missing values; do not assume weights sum to 100. |
| OQ-08 | What explains IMD missingness? | Open. AN2.10 found 1,111 missing rows across 971 students with no alternative value in the tested comparison. The missingness mechanism and any imputation remain unapproved. |
| OQ-09 | What source reference establishes valid categorical values? | Open. The remaining B5.2 categorical-domain review requires source-documentation/provenance evidence; WO-2/AN5 analysis does not close it. |
| OQ-10 | Were all WO-2 interpretations individually reviewed? | AN4.07–AN4.10 passed saved result-count checks, but separate human review checkpoints were not recorded for each query. Their interpretation boundaries remain explicit. |
| OQ-11 | Is repository integration complete? | PR #13 is merged; the current repository head and integration commits are recorded in the authoritative snapshot. Local synchronization remains unverified. |
| OQ-12 | Is synthetic runner CI part of project acceptance? | No. Retired on 2026-11-06 because synthetic fixtures did not validate the actual OULAD workload. |
| OQ-13 | Is the local working tree synchronized with current remote `main`? | Not verified by this repository-only review. |

### Historical repository and CI state — 2026-11-06

- PRs #9–#12 are closed as merged into `main`; their merge commits are recorded above.
- At this historical checkpoint, PR #13 (`AN5: extend engagement sensitivity to five queries`) was open as Draft from `work/an5-five-query-execution` into `main`; head `574d437f48527a8c5aae218bf73ba63be41027ce`. It was subsequently squash-merged on 2026-11-07 by `17766f03ec87ac2deebefc763006053addf46281`.
- At this historical checkpoint, `main` contained the WO-2 SQL bundle, saved WO-2 notebook, documentation updates, and initial AN5 design/three-query preparation. The five-query AN5 extension was then on `work/an5-five-query-execution` under Draft PR #13; the later merge is recorded in the 2026-11-07 closure.
- No file remains under `.github/workflows/`; the synthetic runner test files and their README were removed. No `tests/` directory remains in the current tree.
- The repository-level GitHub Actions feature has not been disabled because the available integration does not expose an Actions-settings write operation. No workflow definition remains to trigger in the current repository tree.
- Run #42140281401 attempt 2 remained `in_progress` at the last verified check. The available integration does not expose a cancellation action. No retry was requested. This run is not a project acceptance gate.
- The merged source branches remain as historical refs; branch deletion was not available through the connected GitHub operations. No branch was deleted.
- Local synchronization and working-tree status have not been verified by this repository-only session.

### Historical next work order — superseded by AN5 closure on 2026-11-07

**AN5 — Engagement Sensitivity.** At this checkpoint, five canonical read-only SQL files, `scripts/run_an5.py`, and the direct-cell notebook were on `work/an5-five-query-execution`. All five queries had been executed locally after the read-only preflight; their eight result sets, Python-only review/export, and eight figures are retained in the notebook. Formal closure was then pending owner acceptance. The owner subsequently accepted the activity definition and limitations and closed AN5 on 2026-11-07. The next work order is now AN6; see the current authoritative snapshot at the beginning of this ledger.


## 2026-10-31 — Repository synchronization and maintenance

The project owner confirmed the current repository synchronization state after PR #7. The verified main commit is `87fd73b467a1d3dd64f43c2a89ec8f47261e5c75`; the local `main` and `origin/main` were reported aligned with a clean working tree. PR #7 was squash-merged and corrected only the introductory reconciliation status and a stale explanatory notebook cell; it did not rerun SQL or modify the database, RAW, QUALITY, or STAGING layers.

The owner also confirmed removal of the temporary work/documentation branches while retaining the two safety backups:
- Local: `backup/local-main-before-sync-2026-10-31` at `62fb8dd`.
- Remote: `backup/pre-wo1-documentation-2026-10-30` at `7e28dbb`.

These backups are intentionally retained. No backup branch is to be deleted as part of routine synchronization.

**Current analytical routing:** WO-2 remains one bounded package in the sequence AN0.07 → AN1.10 → AN2.10 → AN3 → AN4. AN0.07, AN1.10, and AN2.10 are not marked executed by this repository maintenance. AN5 remains a separate dependency-gated stage.

**Repository maintenance:** A focused consistency update is being prepared on `docs/ops-repository-consistency-2026-10-31`. Its scope is limited to the analysis-log handover, this ledger, architecture wording, and the `student_vle` grain caveat in the data dictionary. No SQL, notebook execution, database object, RAW/STAGING data, dependency manifest, or roadmap architecture is changed.

## 2026-11-02 — WO-2 execution foundation preparation

### Repository state and provenance

The project owner reported that local `main` was synchronized with `origin/main` at `51643e63b7c2c6f1398215be965ce4fe61bd6333`, `git diff --quiet` returned 0, and the working tree was clean. This is owner-reported evidence, not a local Git command executed by this update. No reset, rebase, or repeat synchronization was performed.

Changes are being prepared on `work/wo2-execution-foundation`, created from the reported main commit. The branch is not merged into `main`.

### Roadmap status

| Workstream | Status | Evidence / boundary |
|---|---|---|
| WO-1 / `notebooks/04_sql_analytics.ipynb` | Historical evidence retained | Not modified or repurposed. |
| WO-2 runner | Implementation prepared | `src/analytics/db.py` now exposes all result sets and preserves legacy first-result keys; local execution tests remain pending. |
| WO-2 synthetic tests | Authored, not executed | `tests/test_analytics_db_runner.py`; no test pass is claimed. |
| WO-2 SQL bundle | Review pending | External archive review does not establish repository integration. |
| WO2-A through WO2-E notebooks | Planned grouping | Final paths require inventory review; no execution notebooks or live outputs are claimed here. |
| WO2-F | Documentation closeout | No separate notebook planned. |
| AN5 | Dependency-gated | Remains separate; no RAW/STAGING deduplication or aggregation. |

### Executed query IDs

No WO-2 query IDs were executed as part of this update. Historical WO-1 execution evidence remains unchanged and is not relabelled as new execution.

### Files changed or prepared on the work branch

- `src/analytics/db.py` — backward-compatible multi-result execution path using Psycopg simple-query mode and `nextset()`.
- `tests/test_analytics_db_runner.py` — synthetic test cases authored; execution not yet verified.
- `sql/04_analytics/README.md` — clarified canonical SQL ownership, WO-1 evidence status, and WO-2 preparation boundary.
- `notebooks/README.md` — documented the grouped WO-2 notebook architecture and preserved the WO-1 notebook.
- `docs/analysis_log.md` — recorded technical decisions and explicitly marked unexecuted work.
- `docs/analysis_progress_ledger.md` — updated roadmap and evidence status.

### Decisions and controls

- SQL files remain the canonical query definitions; notebooks orchestrate and interpret.
- The existing WO-1 notebook remains unchanged.
- Multi-result SQL is not split on semicolons.
- Legacy result keys refer to the first result set; `result_sets` carries all result sets.
- `elapsed_seconds` is a total batch duration. Per-statement server timings are not represented as measured values.
- Preserve read-only connection mode, statement timeout, lock timeout, rollback, and connection closure.
- AN3.06 is a high-runtime query and must run alone.
- Execute AN4.06 before AN4.03; do not pre-exclude banked submissions.
- Do not modify RAW/STAGING, create indexes or constraints, or claim WO-2 findings before actual database execution.

### Repository actions

Created branch `work/wo2-execution-foundation` from `51643e63b7c2c6f1398215be965ce4fe61bd6333`. Changes are not merged. No PR merge, local machine modification, or database operation is claimed.

### Next work order

1. Run the synthetic test module in the local project environment and fix any failures.
2. Review the complete 21-file SQL bundle against the WO-2 plan and the corrected review notes; integrate SQL only after file-level approval.
3. Inspect the current notebook inventory and then create grouped WO2-A–WO2-E notebooks with Markdown rationale before each code cell.
4. Complete review and closeout documentation (WO2-F).
5. Only after local runner and SQL validation, begin AN0.07 and continue in the approved dependency-aware order. No live WO-2 query is authorized by this preparation record alone.


## 2026-11-02 — WO-2 SQL and notebook preparation

### Roadmap status

| Workstream | Status | Evidence / boundary |
|---|---|---|
| WO-1 / `notebooks/04_sql_analytics.ipynb` | Historical evidence retained | Preserved; not modified or re-executed. |
| WO-2 SQL AN0.07, AN1.10, AN2.10, AN3.01–AN3.08, AN4.01–AN4.10 | Prepared; static review applied | 21 canonical SQL files added on the preparation branch. No live database execution is claimed. |
| WO-2 runner | Existing multi-result implementation retained | `src/analytics/db.py` already supports Psycopg simple-query batches, `nextset()`, per-result display caps, and legacy first-result aliases. |
| Synthetic runner tests | Authored; execution not verified here | Existing `tests/test_analytics_db_runner.py`; no passing test run is claimed. |
| WO-2 notebook | Prepared | One notebook, `notebooks/05_wo2_analytical_investigation.ipynb`; live-execution flag defaults to False and review gates are explicit. |
| WO2-F | Pending actual evidence | Documentation closeout follows returned PostgreSQL outputs; no results are fabricated. |
| AN5–AN11 | Not started / dependency-gated | No activity metric, KPI, mart, Power BI, or predictive model is approved. |

### Executed query IDs

**None.** No WO-2 query was executed against `oulad_analytics` during this preparation. No test execution is claimed.

### Static review corrections

- AN3.03: the after-course-end condition precedes the in-course week buckets.
- AN3.06: registration is LEFT JOINed; `NO_REGISTRATION_MATCH` is distinct from matched registration with NULL `date_unregistration`.
- AN4.08: the distinct count is at student-presentation grain.
- AN4.10: removed `zero_weight_rows` exactly as requested; no change to the submitted-weight aggregation, banked-status groups, or coverage shares.
- Historical and directional expectations in selected AN3/AN4 queries are framed as hypotheses or reconciliation references rather than acceptance criteria.

### Files added or updated on the preparation branch

- Added 21 canonical SQL files under `sql/04_analytics/`.
- Added `notebooks/05_wo2_analytical_investigation.ipynb`.
- Updated `sql/04_analytics/README.md` with the full query inventory and static correction notes.
- Updated `notebooks/README.md` to specify one WO-2 notebook and preserve the existing notebook inventory.
- Updated `docs/analysis_progress_ledger.md` and `docs/analysis_log.md` with preparation status and approved technical decisions.
- `src/analytics/db.py`, its synthetic tests, `notebooks/04_sql_analytics.ipynb`, `docs/analytical_work_order_plan.md`, and `docs/data_dictionary.md` were not modified in this change set.

### Decisions and constraints

- Canonical SQL remains the sole source of query logic; the notebook orchestrates and interprets.
- One notebook is used for all WO-2 work, as approved by the project owner.
- The notebook's live-execution gate defaults to disabled; explicit authorization is required before live queries.
- AN3.06 is executed alone with a 600,000 ms runner timeout; no SQL `SET` statement is added.
- AN4.06 must be reviewed before AN4.03; banked status remains a dimension, not an exclusion rule.
- AN4.10 coverage shares remain calculated among student-presentations with the relevant status; the full student-presentation denominator is shown separately for context.
- RAW/STAGING are unchanged; no indexes, constraints, views, marts, or other persistent database objects are created.

### Repository actions

Changes are prepared on `work/wo2-pre-execution-readiness`, based on commit `aacf56fc3ae7698a7f951e1ac469b9fb2e038140`. The branch is not merged. A draft integration PR is to be opened for review; no merge is authorized.

### Next work order

1. Review the preparation diff and the exact SQL corrections.
2. Run the synthetic unit-test suite in the user's local environment and return the actual result.
3. After separate explicit approval, run AN0.07 and inspect all three result sets before deciding whether AN1.10 can proceed.
4. Continue through WO2-A–WO2-E only at the defined review gates.


## 2026-11-02 — Runner validation hardening

The project owner requested a clear separation between synthetic runner tests, isolated PostgreSQL integration tests, and the later live WO-2 investigation. The existing mocked unit tests do not connect to PostgreSQL and cannot alone validate Psycopg's actual multi-result behavior.

To address this without accessing the user's local database, an isolated integration test and GitHub Actions workflow were added on the existing `work/wo2-pre-execution-readiness` branch. The workflow provisions a disposable PostgreSQL 18 service named `oulad_runner_test`, installs the repository-pinned Psycopg 3.3.6 and required runtime dependencies, then runs the unit and integration tests. The integration test issues three SELECT statements, verifies all result sets and their order, checks `transaction_read_only = on`, and asserts the database name is exactly `oulad_runner_test`. It contains no DDL or DML.

The runner comments were corrected to avoid claiming that `prepare=False` alone selects the simple-query protocol. The documented Psycopg contract supports multiple statements without parameters and exposes subsequent results through `nextset()`; the isolated integration test is the empirical gate for the pinned version.

**Validation status:** workflow and integration test have been authored but have not yet run. No CI pass is claimed. No user database connection was opened and no OULAD data was read or changed. The live execution gate remains separate and requires the user's explicit approval.


## 2026-11-05 — WO-2 notebook structure correction

### Roadmap status

| Workstream | Status | Evidence / boundary |
|---|---|---|
| WO-1 notebook | Preserved | `notebooks/04_sql_analytics.ipynb` was inspected as the structural reference and was not modified. |
| WO-2 notebook | Rebuilt; repository write verified | `notebooks/05_wo2_analytical_investigation.ipynb` now follows the WO-1-style setup → readiness checks → database preflight → query → interpretation/review sequence. |
| WO-2 SQL | Existing canonical files retained | The 21 SQL definitions were not changed by this notebook correction. |
| Live WO-2 execution | Not verified in this work order | No AN0.07–AN4.10 query was executed by this documentation change. |
| Database state | Not inspected or modified | No connection to the user's local `oulad_analytics` database was opened by this repository edit. |

### Notebook corrections

- Replaced the single oversized setup cell with separate repository/import, environment-readiness, database-preflight, execution-helper, and helper-validation cells.
- Added a fresh AN0.01 preflight that displays database identity, PostgreSQL version, read-only settings, statement timeout, and lock timeout. The notebook stops if the database is not `oulad_analytics` or either read-only setting is not `on`.
- Added an explicit live-execution authorization cell. The switch remains `False` by default and must be deliberately changed after the successful preflight.
- Preserved one canonical SQL source per query and the existing shared runner.
- Added expected result-set-count checks for all 21 WO-2 query IDs; AN0.07, AN1.10, and AN2.10 expect three result sets, AN4.05 expects two, and the remaining queries expect one.
- Added a current AN1.01 student-presentation key refresh as an explicit dependency before AN1.10; this is a dependency check, not an additional WO-2 query.
- Added per-query Question, Expectation, Grain, Source, Safety, Runtime, and Read as context, followed by interpretation and manual review checkpoints.
- Preserved AN3.06 as a standalone high-runtime query with a 600,000 ms timeout, AN4.06 before AN4.03, and AN4.10 without `zero_weight_rows`.
- Added stable notebook cell IDs. The 04 notebook and canonical SQL files were not modified.

### CI warning and execution evidence

The earlier PR workflow run `41541198803` installed dependencies successfully, but its test step was cancelled after the hosted runner received a shutdown signal. The log also contains a Node.js 20 deprecation warning from GitHub Actions. The available log does not establish a Python assertion failure or a notebook execution failure. A later push workflow run `41940696084` was in progress at the time of this ledger update; its outcome is not claimed.

No separate warning output from the user's local Jupyter kernel is stored in the repository snapshot. Any local-only warning not present in the saved notebook or Actions log remains unverified.

### Files changed

- Updated `notebooks/05_wo2_analytical_investigation.ipynb`.
- This ledger entry records the verified repository change.
- `notebooks/04_sql_analytics.ipynb`, `src/analytics/db.py`, the 21 canonical SQL files, and RAW/STAGING data were not changed in this correction.

### Executed query IDs

**None in this repository correction.** AN0.01 is now the notebook's first local database preflight, but it has not been executed by this change.

### Next work order

1. Pull or sync the updated notebook from `work/wo2-pre-execution-readiness` into the user's local working copy without overwriting unrelated local work.
2. Restart the Jupyter kernel and run the environment cells individually.
3. Run the AN0.01 preflight and verify the displayed database identity and read-only settings.
4. Only after that succeeds, deliberately enable the live-execution switch and begin AN0.07.
5. Review all three AN0.07 result sets before the current AN1.01 key refresh and AN1.10.

## 2026-11-05 — First local WO-2 execution attempt and AN0.07 correction

### Verified local evidence reported by the project owner

- The local notebook located the project root and canonical SQL folder, imported the shared runner, and passed environment validation.
- AN0.01 executed against `oulad_analytics` and returned one row. The reported PostgreSQL version was 18.6; both `transaction_read_only` and `default_transaction_read_only` were `on`; statement timeout was 2 minutes and lock timeout was 5 seconds.
- The notebook's execution helper validation passed and the preflight gate was marked verified.
- The owner explicitly authorized live WO-2 execution. The notebook authorization switch was enabled locally; this local state is not independently inspectable from the repository.
- AN0.07 was attempted but failed before returning result sets with PostgreSQL `DatatypeMismatch`: JOIN/USING types `character` and internal `"char"` cannot be matched. No AN0.07 output is accepted as evidence, and no AN1.10 execution is authorized by this failed attempt.

### Root cause and correction

The mismatch was in AN0.07 statement 2: the CTE supplied `CHAR` values while `pg_constraint.contype` is PostgreSQL's internal `"char"` type. The join using `constraint_type` therefore compared incompatible types. The canonical SQL was corrected to cast both sides to `TEXT`:
- constraint type literals now use `'p'::TEXT`, `'u'::TEXT`, `'f'::TEXT`, and `'c'::TEXT`;
- `con.contype` is selected as `con.contype::TEXT`.

The correction was committed to `work/wo2-pre-execution-readiness` in commit `0f948ba18d4f6489f0440260bd2fa2a35faa5821`. The updated file was fetched back and the corrected casts were verified in the repository. This is a source-level correction only; it has not yet been executed against PostgreSQL.

### Execution status and next action

- Executed WO-2 query IDs with returned results: **none**.
- AN0.01 is a successful local preflight, not a WO-2 analytical query.
- AN0.07: failed attempt; corrected SQL committed; rerun pending.
- AN1.10 and all later WO-2 queries: not run.
- No RAW/STAGING data or database objects were changed.

Next: synchronize the corrected AN0.07 SQL file into the local working copy, verify that the local file matches the branch version, then rerun only AN0.07. Inspect all three result sets and their row counts, truncation flags, runtime, and semantics before proceeding to AN1.01 refresh / AN1.10. Do not rerun AN0.01 unless the connection/kernel state has changed.

## 2026-11-05 — AN0.07 local execution evidence and review-gate correction

### Verified AN0.01 preflight

The project owner returned a fresh local AN0.01 output from `oulad_analytics` on PostgreSQL 18.6. The session reported `transaction_read_only = on`, `default_transaction_read_only = on`, `statement_timeout = 2min`, and `lock_timeout = 5s`. Environment validation and the shared runner import passed. This verifies the reported local read-only session at that time; it does not establish future connection state after a kernel restart or environment change.

### AN0.07 execution — user-returned output

The corrected canonical SQL executed locally and returned all three expected result sets in 0.191 seconds. The display cap was 500 rows per result set; no result set was truncated.

| Result set | Returned rows | Verified observation |
|---|---:|---|
| 1 — RAW primary-key inventory | 7 | Six documented primary keys returned `MATCH` and `is_validated = True`; `student_vle` returned `EXPECTED_NO_PK`. |
| 2 — Constraint-type counts | 4 | `p = 6`; `u = 0`; `f = 0`; `c = 0`. |
| 3 — Index inventory for `raw.student_vle` | 0 | No index rows were returned for this table in the RAW schema. |

**Interpretation:** the six expected RAW primary keys are present and validated. The expected absence of a primary key on `student_vle` is confirmed. No indexes were found on `raw.student_vle` by this catalog query. The empty index inventory is a metadata finding, not proof of row uniqueness or a reason to create an index. No index or other persistent database object was created.

The project lead reviewed the three user-returned result sets in this conversation and accepted the AN0.07 findings. The local notebook checkpoint output showed `AN0.07 reviewed: False`; this is a closed manual-review flag, not an SQL execution failure. The user had not recorded the required `REVIEWED` input in that local checkpoint. No AN1.01 refresh or AN1.10 query was executed as part of this result.

### SQL correction and static cross-query review

The AN0.07 failure was traced to a JOIN/USING comparison between PostgreSQL internal `"char"` (`pg_constraint.contype`) and SQL `character` literals. Both sides were cast to `TEXT`. The corrected SQL was committed to `work/wo2-pre-execution-readiness` in commit `0f948ba18d4f6489f0440260bd2fa2a35faa5821`; the user subsequently returned successful execution output from that corrected file.

A static scan of all 21 WO-2 SQL files found no other explicit `::CHAR` or internal `"char"` casts. Remaining `USING` joins occur in AN1.10, AN3.03, AN3.06, and AN4.10 on shared key columns; this static inspection is not a substitute for live execution of those queries.

### Notebook execution-flow correction

The notebook was updated on the same preparation branch to make expected workflow gates non-exceptional:

- A dependent query attempted before its review gate opens now prints `NOT EXECUTED`, identifies the missing approval, and returns without sending SQL to PostgreSQL or raising a traceback.
- A review checkpoint with missing, truncated, stale, or incomplete outputs now prints `REVIEW BLOCKED` and returns `False`; it does not raise a traceback for a normal closed gate.
- The checkpoint prompt explicitly requires the project lead's approval before the user enters `REVIEWED`.
- AN1.01's direct dependency refresh now checks the live-authorization and AN0.01 preflight flags as well as AN0.07 review. A closed gate returns without opening a database connection.
- Re-running an upstream query invalidates its own review flag and all downstream approvals/results.
- Reinitializing the execution helper retains the AN0.01 preflight output but clears prior WO-2 outputs and resets review flags, preventing stale in-memory results from opening gates.
- Genuine SQL/database exceptions and unexpected result-set counts remain visible and are not suppressed.

The notebook update was committed in `a9871f6aa1fd9c253cb42f66192c949672fbb969`, followed by a small safety refinement that clears stale WO-2 outputs on helper reinitialization in commit `c341ff78f93c880fdc30ac8b8535eab17427b20b`. The notebook still contains 92 cells. The new helper and AN1.01 refresh code cells passed Python AST parsing; this is a syntax check, not a local Jupyter execution test.

### Current execution status

- AN0.01 fresh local preflight: **executed; user-returned output verified**.
- AN0.07: **executed; three result sets returned; reviewed and accepted in conversation**. The local notebook review flag has not yet been recorded in the corrected notebook.
- AN1.01 current dependency refresh: **not yet executed**.
- AN1.10, AN2.10, AN3.01–AN3.08, AN4.01–AN4.10: **not executed in WO-2**.
- No RAW, QUALITY, or STAGING data was modified. No persistent database objects were created.

### Next work order

1. Synchronize the corrected notebook and canonical AN0.07 SQL file from `work/wo2-pre-execution-readiness` to the local project. Preserve a backup of the current local notebook first if it contains unsaved execution outputs.
2. Restart the Jupyter kernel and run the setup, environment, AN0.01 preflight, helper, and authorization cells individually. A fresh preflight is required for the new kernel session.
3. Execute AN0.07 once in the updated notebook so the result is stored with the current SQL hash; send the three outputs for confirmation. The query reads catalog metadata only and previously completed in 0.191 seconds.
4. After the project lead confirms the output, run the AN0.07 review checkpoint and type `REVIEWED`.
5. Run the AN1.01 dependency refresh cell. Proceed to AN1.10 only if it returns PASS; then submit all three AN1.10 result sets for review.

The requested concise interpretation/commentary cells for each query will be added after WO-2 execution results are complete and reviewed, using actual returned outputs rather than generic or speculative annotations.

### Post-edit validation of the notebook controls

The updated helper and AN1.01 refresh cells passed Python AST parsing. A small isolated control-flow check confirmed that (a) a query attempted with live authorization disabled returns `None` without calling the database runner, (b) a review checkpoint with missing output returns `False` without a traceback, and (c) AN1.01 returns without calling the runner while the AN0.07 review gate is closed. These are isolated logic checks, not a full Jupyter execution or a live PostgreSQL test.

The six updated repository files were fetched back from `work/wo2-pre-execution-readiness` after commit. The notebook contains 92 cells (34 code cells); the corrected AN0.07 SQL and all documentation updates are present. No merge to `main` was performed.


## 2026-11-06 — WO-2 execution completed; interpretation reviewed

### Roadmap status

| Workstream | Status | Evidence / boundary |
|---|---|---|
| AN0.01 preflight | Executed in saved notebook | `oulad_analytics`, PostgreSQL 18.6; both read-only settings on; 2-minute statement timeout and 5-second lock timeout. Saved output only; not rerun during this review. |
| AN0.07 | Executed; checkpoint True | 3 result sets (7, 4, 0); six expected RAW primary keys match; `student_vle` has expected no PK; no RAW student_vle index rows. |
| AN1.01 dependency refresh | Executed; PASS | Two expected tables, 32,593 rows each; zero NULL key rows, duplicate groups, or excess rows. Not one of the 21 WO-2 query IDs. |
| AN1.10 | Executed; checkpoint True | 3 result sets (5, 22, 1); 33,407-row naive-join excess fully reconciled; correct path 173,912 rows and zero unmatched. |
| AN2.10 | Executed; checkpoint True | 3 result sets (7, 95, 1); 1,111 missing IMD rows across 971 students; no alternative value in the tested comparison. |
| AN3.01–AN3.08 / WO2-C | Executed; WO2-C checkpoint True | Eight queries; 76-row AN3.06 output; descriptive withdrawal, registration, and activity findings with denominator and causality caveats. |
| AN4.01, AN4.02, AN4.04, AN4.05 / WO2-D | Executed; WO2-D checkpoint True | Four queries; AN4.05 returns 2 result sets. AN4.02's 11 no-due-date exams include 2,865 submission rows across three exams. |
| AN4.06 | Executed; checkpoint True | 5 rows; banked and non-banked profiles retained. |
| AN4.03, AN4.07–AN4.10 | Executed; result-count checks passed | Seven queries; AN4.03 correctly followed AN4.06 review. No separate human review checkpoint is recorded for each of AN4.07–AN4.10. |
| AN5–AN11 | Not started | AN5 design is next; no engagement metric or R0/R1/R2 sensitivity result is approved. |

### Saved notebook integrity

Reviewed GitHub branch `work/wo2-pre-execution-readiness`, file `notebooks/05_wo2_analytical_investigation.ipynb`, saved blob SHA `e94a9d40876fa638718a12152f572ef1562e55d8`.

- 92 total cells; 34 code cells; 34 executed; 0 unexecuted.
- 0 saved error/traceback outputs.
- 21 WO-2 queries; 28 result sets; 857 displayed rows.
- Sum of saved query batch runtimes: 10.099 seconds.
- All expected result-set-count checks passed; no runner row-cap truncation.
- AN0.01 preflight and AN1.01 dependency refresh are additional to the 21 WO-2 queries.
- Saved notebook evidence was inspected; no live database connection or query rerun was performed during this review.

### Query execution register

| Query | Result sets | Displayed rows | Seconds |
|---|---:|---:|---:|
| AN0.07 | 3 | 11 | 0.159 |
| AN1.10 | 3 | 28 | 0.718 |
| AN2.10 | 3 | 103 | 0.079 |
| AN3.01 | 1 | 6 | 0.046 |
| AN3.02 | 1 | 15 | 0.058 |
| AN3.03 | 1 | 111 | 0.031 |
| AN3.04 | 1 | 6 | 0.039 |
| AN3.05 | 1 | 4 | 0.061 |
| AN3.06 | 1 | 76 | 4.898 |
| AN3.07 | 1 | 36 | 0.086 |
| AN3.08 | 1 | 22 | 0.044 |
| AN4.01 | 1 | 57 | 0.014 |
| AN4.02 | 1 | 11 | 0.032 |
| AN4.04 | 1 | 3 | 0.035 |
| AN4.05 | 2 | 83 | 0.333 |
| AN4.06 | 1 | 5 | 0.408 |
| AN4.03 | 1 | 17 | 0.141 |
| AN4.07 | 1 | 27 | 0.197 |
| AN4.08 | 1 | 20 | 1.391 |
| AN4.09 | 1 | 178 | 0.411 |
| AN4.10 | 1 | 38 | 0.918 |
| **Total** | **28** | **857** | **10.099** |

### Validated observations and caveats

- AN0.07: six documented RAW primary keys match; `student_vle` has no primary key as expected; the catalog query returned no index rows for `raw.student_vle`. Do not infer uniqueness or create an index from this result.
- AN1.10: the naive `id_student`-only join produces 207,319 rows versus 173,912 source rows. The 33,407 excess rows reconcile exactly to students appearing in multiple presentations. The metadata-aware path returns 173,912 rows with zero unmatched rows.
- AN2.10: 1,111 missing IMD rows represent 971 distinct students; all are classified `NO_ALTERNATIVE_VALUE`. No automatic imputation.
- AN3.01–AN3.05: 10,156 Withdrawn rows comprise 10,063 with an unregistration date and 93 without. Nine Fail rows have an unregistration date. AN3.02 exposes nine non-withdrawn/date conflicts. AN3.05 categories reconcile to 32,593 student-presentations. AN3.04's 86.67% rate is based on only 45 rows (39 withdrawn).
- AN3.06: activity absence and timing are descriptive recorded-row findings, not proof of no learning or causal withdrawal. Registration mismatch, missing unregistration date, and no recorded activity remain distinct categories.
- AN3.07: `small_category_flag` checks category totals, not individual outcome-cell counts. Individual cells can still be below 100 (including a cell with two rows); the SQL comment and flag semantics should be aligned before reuse.
- AN3.08: withdrawal proportions range from 6.93% (GGG 2013J) to 46.38% (CCC 2014B), descriptive only.
- AN4.02 correction: all 11 no-due-date assessments are Exam, but three have submission records totalling 2,865 rows; eight have none. AN4.04 returns the three submission-bearing assessment groups.
- AN4.05/AN4.06: 173 NULL scores, 329 zero scores, zero out-of-range scores; 173,739 scored rows out of 173,912. Banked `date_submitted = -1` is a sentinel, not a calendar date.
- AN4.07/AN4.08: outcome and score groupings are retrospective; do not use final outcome/score to predict the same outcome. Small cells need caution.
- AN4.09: timing categories do not prove acceptance or validity of a submission after unregistration.
- AN4.10: coverage averages use the student-presentations with the relevant banked status; the full cohort count is displayed separately. A student can appear in both status groups. The GGG 0.000 coverage pattern is consistent with zero-weight CMA/TMA and a 100-weight Exam in the assessment structure, but does not prove absence of learning activity. No final weighted-score definition is approved.

### Decisions

- WO-2's 21-query execution is complete in the saved notebook.
- Interpretations are descriptive and bounded by the saved execution; this review did not rerun PostgreSQL.
- No KPI, causal finding, final weighted score, predictive feature set, or business rule is approved.
- RAW, QUALITY, and STAGING remain unchanged; no persistent database objects were created.
- The `student_vle` repetition problem remains open. Preserve all 10,655,280 rows and do not deduplicate or aggregate source data.

### Open questions / next work order

1. Define the AN5 engagement metric, grain, time window, denominator, and treatment of negative relative dates and missing matches.
2. Specify R0 (all rows), R1 (exact six-column duplicate exclusion for metric calculation only), and R2 (maximum `sum_click` per five-column key group) as sensitivity alternatives, not data-cleaning rules.
3. Quantify metric and denominator changes under each alternative; preserve the raw/staging source unchanged.
4. Reconcile AN3.07's small-cell wording with its implemented flag before reusing the flag as an automated warning.
5. Keep AN5–AN11, KPIs, marts, Power BI, and predictive modelling dependency-gated.

### Repository and database actions

- Updated only `docs/analysis_log.md` and `docs/analysis_progress_ledger.md` on `work/wo2-pre-execution-readiness` to record this review.
- No notebook, canonical SQL, Python source, RAW/STAGING data, or database objects were changed by this documentation update.
- No merge to `main`, PR retargeting/closure, branch deletion, or database modification was performed.


## 2026-11-07 — AN5 quantitative review, figure explanations, and report

### Roadmap status

| Workstream | Status | Evidence / boundary |
|---|---|---|
| RAW / QUALITY / STAGING | Preserved | No source-layer changes or persistent database objects. |
| WO-1 / WO-2 | Completed within documented scope | Existing saved evidence unchanged; no repeat execution. |
| AN5 | Five SQL queries executed; Python review/export and visual summaries executed; formal closure pending owner acceptance | Saved notebook: five queries, eight result sets, 623 rows, no runner row-cap truncation. |
| AN6 / AN7 | Not started | Separate, dependency-gated stages. |
| KPIs / marts / Power BI / final report | Downstream | Require validated and accepted metric definitions. |

### Execution evidence

- AN5.01–AN5.05 executed in the owner's local PostgreSQL session; expected eight result sets returned.
- Result-set row counts: AN5.01 (1, 3, 66), AN5.02 (69), AN5.03 (132), AN5.04 (66), AN5.05 (264, 22).
- Total: 623 rows; sum of SQL batch durations 1,738.615 seconds. This is not total notebook runtime.
- Saved preflight: `oulad_analytics`, PostgreSQL 18.6; both read-only settings `on`.
- Python-only review/export completed using retained frames; all bounded result sets exported locally to Git-ignored `outputs/an5/` with a JSON manifest. No SQL rerun.
- Visualization cell completed; eight figures generated. No runner row-cap truncation or SQL traceback is recorded.

### Key results

- R1: 9,868,110 rows (-7.39% vs R0); R2: 8,459,320 (-20.61%). There are 1,179,074 repeated five-column key groups with multiple `sum_click` values.
- All scenarios reconcile to 32,593 registered and 29,228 activity-bearing student-presentations; zero unmatched activity records in the tested reconciliation.
- Click totals: 39,605,099 (R0), 38,343,063 (R1, -3.19%), 34,402,738 (R2, -13.14%). Coverage 89.68%; 3,365 student-presentations without activity. Active-day pairs 1,808,119 and active-site pairs 1,960,496 are invariant.
- R0 pre-course activity: 688,988 rows (~6.47%) and 2,147,947 clicks (~5.42%). Negative course-relative days do not establish timing relative to personal registration.
- Median Spearman: 0.999850 (R0/R1), 0.998870 (R0/R2), 0.999205 (R1/R2). Rank changes affect 82.44%, 86.51%, 85.47% of paired student-presentations. Median top-decile Jaccard: 0.97710, 0.91565, 0.91930; minimum 0.8286 (GGG 2013J R0/R2).
- Pooled outcome groups: 3,024 Distinction (100.00% coverage), 7,052 Fail (94.70%), 12,361 Pass (99.98%), 10,156 Withdrawn (70.58%). Profile diagnostic reconciles 32,593 registered keys to unique profiles with zero missing, duplicate, or conflicting matches.

### Decisions and limitations

R0/R1/R2 remain sensitivity alternatives, not source-cleaning rules. Click volume is sensitive to repeated-row treatment; presence/day/site measures are invariant under these scenarios but are not automatically approved KPIs. High Spearman correlation does not guarantee stable top-decile membership. `final_result` is retrospective and descriptive, not predictive or causal. No KPI, causal claim, operational threshold, intervention, or predictive feature is approved. RAW, QUALITY, and STAGING remain unchanged.

Formal AN5 closure awaits owner review and acceptance of the activity definition and limitations. AN6 and AN7 remain separate.

### Files changed on the existing PR branch

- Updated `notebooks/07_an5_engagement_sensitivity.ipynb` with five query interpretations, corrected section numbering, eight figure explanations, and a final project-continuity cell; retained outputs preserved.
- Updated the AN5 plan, analysis log, progress ledger, README, notebook guide, SQL inventory, and data-dictionary status.
- Local `outputs/an5/` exports remain Git-ignored and were not committed.

### Repository state and next work order

Branch: `work/an5-five-query-execution`. PR #13 remains open, draft, and unmerged. At the latest repository comparison, the branch was 41 commits ahead of `main` and zero behind. No merge, branch deletion, or database modification occurred.

Next: review the notebook interpretations and analytical evidence; confirm the activity-measure definition and limitations; record the owner decision and AN5 exit status; then scope AN6 separately. Keep AN7 separate.


## Current authoritative closure — 2026-11-07

### AN5 disposition

**AN5 — Engagement Sensitivity: CLOSED.** The project owner reviewed the five-query execution evidence and accepted the operational definition of recorded in-course VLE activity documented in `docs/AN5_engagement_sensitivity_plan.md`, Section 17.

The accepted definition uses registered student-presentation grain `(code_module, code_presentation, id_student)`, joined on all three columns. In-course activity is bounded by course-relative day 0 through `module_presentation_length`, inclusive. Pre-course and post-course activity remain separate diagnostics. The primary dimensions are recorded in-course activity presence/coverage, distinct in-course active days, and distinct in-course resource breadth. Click volume remains secondary and scenario-sensitive. The 89.68% AN5.02 coverage result counts any recorded activity across the scenario comparison; it is not the accepted in-course-only coverage rate. AN6 must calculate the in-course denominator/numerator explicitly.

R0/R1/R2 are metric-only sensitivity alternatives, not source-cleaning rules. Missing activity rows describe the absence of a matching record in the defined source/window, not absence of learning. `final_result` remains retrospective descriptive grouping only.

### Execution and evidence register

- Five canonical SQL investigations executed locally after successful AN0.01 read-only preflight.
- Eight expected result sets; 623 rows retained; no runner-level row-cap truncation or saved SQL traceback.
- Sum of SQL batch durations: 1,738.615 seconds (not total notebook runtime).
- Python-only review/export completed from retained result frames; local exports remain Git-ignored.
- Eight figures and their explanations retained in `notebooks/07_an5_engagement_sensitivity.ipynb`.
- No SQL rerun during final documentation and repository integration work.

### Main findings retained

- R0/R1/R2 row counts: 10,655,280 / 9,868,110 / 8,459,320.
- Recorded clicks: 39,605,099 / 38,343,063 / 34,402,738; R1 -3.19%, R2 -13.14% versus R0.
- Recorded activity coverage: 89.68% in all three scenarios; active-day pairs 1,808,119 and active-site pairs 1,960,496 were invariant in the tested overall comparison.
- R0 pre-course activity: 688,988 rows (~6.47%) and 2,147,947 clicks (~5.42%).
- Median Spearman correlations: 0.999850 / 0.998870 / 0.999205 for R0/R1, R0/R2, R1/R2; minimum top-decile Jaccard overlap 0.8286.
- AN5.05 outcome-group comparisons remain retrospective descriptive summaries; profile matching reconciled 32,593 registered keys to unique profiles in the returned diagnostic.

### Decisions and exclusions

- RAW, QUALITY, and STAGING remain unchanged.
- No persistent database objects were created.
- No deduplication rule, composite engagement score, causal claim, intervention threshold, or predictive feature is approved.
- AN6 may now be planned using the accepted definition and must have its own metric contract before SQL implementation.
- AN7 remains separate and requires an explicit outcome definition and leakage-safe temporal design.
- The data-science phase remains downstream of the completed analytical phase.

### Repository integration

PR #13 integrates AN5 into `main`. The previous `main` state remains preserved in Git history; no duplicate project snapshot directory is needed. The pre-WO-1 backup branch is a separate historical safety point and should be retained.

The GitHub connector available in this session supports branch listing and branch creation but exposes no branch-delete operation. Therefore, obsolete branch cleanup cannot be completed through this connection. Do not delete branches containing unique commits until their history has been reviewed.


### Remote branch inventory after AN5 integration

Verified remote branches on 2026-11-07:

- `main`: current integrated project head.
- `backup/pre-an5-integration-2026-11-07`: snapshot of the exact pre-AN5-integration main head; retain as a rollback point.
- `backup/pre-wo1-documentation-2026-10-30`: earlier historical safety point; retain.
- `work/an5-five-query-execution`: PR #13 head, now merged by squash; retain until the owner synchronizes locally, then it can be removed.
- `work/an5-engagement-sensitivity` and `work/an5-engagement-sensitivity-resolved`: same commit; both are seven commits behind main and contain no commits ahead of main.
- `docs/wo2-an5-consistency-2026-11-06` and `docs/wo2-an5-consistency-resolved`: same commit; both are 21 commits behind main and contain no commits ahead of main.
- `work/wo2-execution-foundation`: 64 commits behind main, no commits ahead.
- `work/wo2-pre-execution-readiness`: 31 commits behind main, no commits ahead.
- `docs/ops-repository-consistency-2026-10-31`: diverged from main, with four unique commits; inspect those commits before any deletion.

The available GitHub integration in this session does not expose a remote branch-delete operation. No branch was deleted. The five stale/duplicate work branches with zero commits ahead can be removed after local synchronization; the diverged documentation branch must first have its four unique commits inspected. Keep the two intentional backup branches.


### AN6 local execution issue and correction — 2026-11-08

- **Observed:** First AN6.01 attempt failed in PostgreSQL with `UndefinedColumn: key_rows` in result set 3. The failure occurred during SQL parsing/planning; it is not evidence of a Python connection failure.
- **Root cause:** The grouped registration CTE produced `key_rows`, but the next CTE did not project it. The outer aggregate then referenced a column outside its scope.
- **Correction:** Projected `key_rows` through the intermediate CTE and isolated duplicate/excess calculations in a one-row registration aggregate CTE.
- **Additional integrity correction:** Treat VLE resource identity as `(code_module, code_presentation, id_site)`; use the same composite key in AN6.01 and both AN6.04 joins. Add an explicit readiness check for activity rows without a course window.
- **Runner:** Aligned `scripts/run_an6.py` with the AN5 execution pattern: canonical AN0.01 preflight, displayed returned identity/settings, explicit PASS/FAIL checks, AN6.01 gate, result-set counts, row/truncation/runtime reporting, sequential execution, and export manifest. Readiness state resets on each new preflight and AN6.01 run.
- **Notebook:** AN0.01 now displays its result frame and a check table. The AN6.01 cell displays all three result sets and validates corrected metadata columns. Downstream AN6.02–AN6.04 cells retain their direct `run_query` calls; no subsequent query cells need replacement.
- **Not executed:** No corrected SQL, Python runner, or notebook cells have been executed against the local database. No connection success, readiness pass, or analytical result is claimed.
- **Next validation:** User synchronizes corrected branch/PR files, restarts the Jupyter kernel, runs setup and AN0.01, then AN6.01 only. Stop on any failed preflight/readiness assertion; preserve the output for review.


### AN6 execution and AN6.03 repair — 2026-11-09

- **Owner-supplied execution evidence:** AN0.01 passed on database oulad_analytics; both read-only settings were on. AN6.01 returned 22 valid course presentations, 6,364 unique course-scoped VLE resource keys, 32,593 unique registration keys, and 10,655,280 activity rows with no missing key components or missing course-window matches. VLE week_from and week_to were each missing in 5,243 resource rows; metadata missingness remains descriptive.
- **AN6.02:** Owner supplied 88 returned rows, corresponding to 22 presentations × four measures. Coverage partitions the registration denominator into in-course activity, outside-window-only, and no-recorded-activity.
- **AN6.03 failure:** PostgreSQL returned OutOfMemory in the TupleSort memory context. The failure occurred during server-side query execution; max_rows=500 and the Python result fetch limit do not constrain server-side sorting/aggregation memory.
- **AN6.03 correction:** Removed the composite student-resource-day distinct count; pre-aggregated activity to student-presentation × temporal bucket/period using GROUPING SETS; counted unique student-level groups rather than sorting all activity rows for COUNT(DISTINCT id_student); removed final global ORDER BY. Preserved activity-row totals, registered student-presentation reach, unmatched activity-row counts, secondary click totals, PRE/IN/POST/NO_COURSE_WINDOW classifications, relative seven-day periods, and boundary diagnostics.
- **Python/notebook:** Runner reports query ID, SQL path, PostgreSQL SQLSTATE, primary diagnostic, detail, and hint; exception chaining is retained and no retry is attempted. Notebook 08 delegates preflight, readiness, and all query execution to the same runner functions used by the script.
- **Not verified:** Repaired AN6.03 has not been executed. No claim is made that the memory issue is fully resolved. SQL query plan, actual memory use, runtime, and result reconciliation await the next local run.
- **Repository:** All changes are on the existing AN6 PR branch. No merge or database modification occurred.


### Repository correction after connector write-target issue — 2026-11-09

Three repair commits were initially written to main rather than the intended PR branch by the repository connector. This was detected during branch comparison. Main was restored by a compensating commit that removes only the three misplaced AN6 files; no prior main project files were overwritten. The repaired runner, notebook, and AN6.03 SQL were then integrated into the existing AN6 branch using a two-parent merge commit. The branch now contains the current main head as an ancestor, is not behind main, and remains the head of open PR #16. No PR merge was performed.


### Final AN6.03 repair handoff — 2026-11-09

- PR #16 head: b4cb971a542b60d9db4de6fb67de5eae746460e6.
- Main head: 948fc9f4f16ee7e653feb0f7504d8b96889be720. The three misplaced repair files were removed from main by a compensating commit; the original project tree was restored.
- PR branch includes the restored main head as an ancestor; latest comparison: 57 commits ahead, 0 behind. PR #16 remains open, unmerged, and GitHub reports mergeable/clean.
- Static checks on the final branch: SQL headers present; no write/DDL statements in AN6.03; composite distinct and final global ORDER BY removed; notebook JSON valid with 16 cells and seven code cells, all unexecuted; notebook uses canonical runner for preflight, readiness, and downstream queries; PostgreSQL error diagnostics and no-retry behavior present.
- The repaired AN6.03 has not been run. No successful memory/performance claim is made.


- **Final repair-package head:** 92e34c592f9b3a1fb319715f0c437375fafb813d. Notebook cells call the canonical runner with DataFrame text rendering disabled so each returned frame is displayed once as a notebook table.
- **Final branch comparison:** 59 commits ahead of main, 0 behind; 13 changed files. PR #16 remains open and unmerged.


### AN6 execution interpretation and notebook update — 2026-11-10

- **Execution evidence reviewed:** owner-supplied local notebook outputs for AN0.01 and AN6.01–AN6.04. Read-only preflight passed on `oulad_analytics` / PostgreSQL 18.6.
- **AN6.01:** 22 valid module-presentations; 6,364 unique course-scoped VLE resource keys; 32,593 unique registration keys; 10,655,280 activity rows with complete key components and course-window matches. `week_from` and `week_to` each have 5,243 missing values among 6,364 resources; overlap not yet tested.
- **AN6.02:** 88 rows, no truncation. Population partition passed: 28,500 in-course activity-bearing registrations (87.44% pooled coverage), 728 outside-window-only, 3,365 with no recorded activity in any observed window; denominator 32,593.
- **AN6.03:** 971 rows, no truncation, 145.074 sec. Temporal buckets and relative periods each reconcile to 10,655,280 activity rows; reach and denominator reconcile to AN6.02; 88 boundary diagnostics pass. IN_COURSE 9,966,292 (93.53%); PRE_COURSE 688,988 (6.47%); no POST_COURSE bucket returned.
- **AN6.04:** 254 rows, no truncation, 128.551 sec. 10,655,280 resource metadata matches; zero unmatched resource rows, zero missing activity_type, zero unmatched registration/activity rows. Type-level totals reconcile across all 22 presentations.
- **Figure 1:** median presentation-level activity-row volume fluctuates over relative seven-day periods. Later-period contributors decline from 22 to 21, 13, and 9 due to complete-period eligibility. This is not evidence of within-cohort disengagement. Values are not normalized for registered cohort size and remain sensitive to source-row repetition.
- **Figure 2:** top five types (forumng, oucontent, subpage, homepage, quiz) account for 84.89% of in-course activity rows. Row volume differs from reach; homepage has the highest mean presentation reach among the top five. Type reach is non-additive; type-specific R1/R2 sensitivity has not been tested.
- **Notebook change:** interpretation section added for both figures, with numerical context, limits, new questions, and AN7 dependencies. Corrected the diagnostic to count distinct `(code_module, code_presentation)` keys (rather than distinct presentation labels). The notebook's saved diagnostic output is historical until the plotting cell is rerun locally.
- **Documentation:** appended verified execution evidence and interpretation to `docs/analysis_log.md`.
- **Repository:** updates committed to `work/an6-recorded-vle-activity-patterns`; PR #16 remains the review vehicle. No merge, main-branch update, or database modification was performed.
- **Decisions:** AN6 evidence is ready for project-lead review. No KPI, causal claim, engagement score, threshold, predictive feature, or AN7 approval is implied.
- **Open questions / next work order:** investigate cohort-normalized temporal row volumes, activity-type reach versus volume, targeted type-specific repeat sensitivity if needed, pre-course activity relative to personal registration, overlap/distribution of missing week metadata, and the observed absence of post-course rows. Scope AN7 only after its outcome, withdrawal, banked-assessment, score/weight, CMA timing, and leakage-safe cutoff rules are frozen.

- **Additional repository documentation:** `sql/04_analytics/README.md` now reflects verified AN6 execution rather than the obsolete pre-execution status; `docs/business_questions.md` now includes the evidence-led follow-up questions. Both updates remain on the AN6 branch.


### Repository integration verification — 2026-11-14

- PR #19, “AN7: close outcome associations analysis and document findings”, is CLOSED and MERGED.
- Merge method: squash. Merge commit: `a3c321bc1536aec81c82541da77085e39784cd8e`.
- The merged PR contains 18 files: Notebook 09, AN7 plan and stage report, five canonical SQL investigations, runner, README, architecture, business questions, notebook guide, SQL guide, analysis log, progress ledger, final-report scope, and .gitignore.
- The closeout branch was created from the v1.1.0 main baseline and did not carry the obsolete 20-ahead/10-behind divergent branch history.
- Main now contains the AN7 analytical closeout. The original execution branch and the temporary closeout branch have not been deleted.


### Branch pruning decision

The following 20 non-backup remote branches are approved cleanup candidates after the local `main` branch is fast-forwarded and the working tree is confirmed clean: `docs/an7-merge-verification`, `docs/branch-cleanup-review-2026-11-14`, `docs/an7-notebook-evidence-clarification`, `docs/ops-repository-consistency-2026-10-31`, `docs/record-consistency-closeout`, `docs/record-roadmap-merges-2026-11-14`, `docs/repository-consistency-and-an6-readiness`, `docs/roadmap-consistency-2026-11-14`, `docs/roadmap-final-wording-2026-11-14`, `docs/v1.1.0-release-readiness`, `docs/wo2-an5-consistency-2026-11-06`, `docs/wo2-an5-consistency-resolved`, `work/an5-engagement-sensitivity`, `work/an5-engagement-sensitivity-resolved`, `work/an5-five-query-execution`, `work/an6-recorded-vle-activity-patterns`, `work/an7-outcome-associations`, `work/an7-outcome-associations-closeout`, `work/wo2-execution-foundation`, and `work/wo2-pre-execution-readiness`.

Retain `backup/pre-an5-integration-2026-11-07` and `backup/pre-wo1-documentation-2026-10-30` as deliberate recovery points. The GitHub connector used for this review has no remote branch-delete action; the approved deletions must be performed with `git push origin --delete` after local synchronization. No branch deletion has yet been executed.


## Sensitivity visualization review — 2026-11-15

- **Branch:** `feat/an7-sensitivity-visuals`; owner-pushed initial commit `df92fdad10ec4929248dc02b161dfea1a3051291`. Draft PR #26 is open against `main` (`https://github.com/JALILOHUB/OULAD-EdTech-Learning-Analytics/pull/26`); it has not been merged.
- **Verified notebook execution before refinement:** the final Python cell had execution count 2 and nine embedded PNGs, with a completion stream reporting 660 sensitivity rows, 30 summary rows, and `No SQL was executed.` Those outputs were cleared after the source refinement because they no longer represent the current source. The final cell is now intentionally unexecuted pending the owner's single-cell run.
- **Notebook update prepared:** a Markdown explanation is placed before the visualization code and a result-specific interpretation/handover after it; closeout and report-generation Markdown cells now refer to AN10 predictive readiness rather than the superseded AN8 label. The latest source uses fixed primary/alternative colors, neutral connectors, distinct median markers, one-to-one full-key pairing assertions, and a denominator derived from validated timing totals. The prior nine figure outputs were cleared; rerun only the final visualization cell to regenerate them.
- **Interpretation:** O1 retained direction in 130/132 paired comparisons; the two near-zero sign changes concern resource breadth in GGG/2013J at L56/L84. Median absolute paired change ≈0.00166; maximum ≈0.06233. O2 remained negative in 22/22 presentations after the specified exclusion. The after-course-start stratum had 12/22 estimable and 10/22 non-estimable comparisons; median comparison-group size 5 (range 1–49).
- **Visual inventory:** 15 existing AN7 visualizations plus nine sensitivity figures = 24 saved visualizations in Notebook 09. The nine new figures are presentation-level point-estimate displays; they do not show confidence intervals and must not be described as pooled, causal, or predictive evidence.
- **Roadmap:** AN8 — Validated Metrics & Marts; AN9 — Power BI; AN10 — Predictive Readiness Gate; AN11 — Consolidated Final Analytical Report. The separate Data Science / Machine Learning phase remains after analytical-phase completion and the AN10 decision.
- **Safety:** no SQL rerun, no database modification, and no changes to RAW, QUALITY, or STAGING. The branch remains unmerged pending review; local synchronization of these follow-up documentation changes is not yet verified.


## 2026-11-15 — AN7 final visualization source refinement

- Updated only the final Python visualization cell in Notebook 09. Primary and sensitivity series now use fixed colors across O1/O2 figures; paired connectors use neutral grey; median diamonds use a distinct neutral marker.
- Replaced the inner merge with an outer one-to-one merge plus explicit key-completeness, finite-effect, and 22-presentation assertions. A missing comparison row can no longer disappear silently from the plotted denominator.
- Registration-timing charts now derive the displayed denominator from the validated grouped total rather than hardcoding `/22`; the cell asserts the expected 22-presentation denominator and expected feature/stratum coverage.
- Cleared the nine stale saved figure outputs and reset only this cell's execution count. The owner should execute **only the final visualization cell (cell 75 in the current 77-cell notebook)** after synchronizing the two changed files. It reads the three existing AN7 CSV exports, writes nine refreshed PNGs under `outputs/an7/figures`, and runs no SQL or statistical analysis.
- No other notebook code cell, SQL file, database object, RAW, QUALITY, or STAGING data was changed. AN7 is not being rerun. PR #26 remains open and unmerged pending the local single-cell execution, synchronization of the updated notebook, and final owner review.


## 2026-11-15 — AN8 preparation branch

- Created `feat/an8-preparation-review` from `main` at `44af2a2117e524b469e3cf8df9ee77e9f863f250`. Prepared 14 canonical read-only SQL files (AN8.01–04, AN8.10–12, AN8.20–23, AN8.33, AN8.40–41), `scripts/run_an8.py`, `notebooks/10_an8_validated_metrics_and_marts.ipynb`, and three AN8 preparation/handover documents.
- Initial 15 November runner design required AN0.01 read-only preflight, treated AN8.20–23 as separate high-cost scans, and deferred AN8.30–32. The 16 November static remediation supersedes that design: AN8.20 now consolidates the activity measures into one scan, AN8.21–23 are retired, and AN8.04 has an explicit two-result-set/course-context gate.
- First proposed local batch: AN0.01 → AN8.01 → AN8.02 → AN8.03. No AN8 SQL was executed; no database connection, metric refresh, notebook execution, mart object, view, index, DDL/DML, or RAW/QUALITY/STAGING modification occurred during preparation.
- At the time of the 15 November preparation entry, the Notebook 09 visual discrepancy was still open. The 16 November independent review subsequently inspected all nine saved sensitivity figures; the notebook, analysis log, final report, and Notebook README now consistently record 24 visuals (15 original plus nine sensitivity figures). No AN7 SQL or analysis was rerun.
- Candidate measures remain unapproved. No decisions were made on persisted mart design, DDL mechanism, index creation, suppression threshold, K6 denominator, Power BI dimensions, or weighted score. No PR was opened and no merge to main was performed.
- Static preparation is not equivalent to SQL parser validation or local execution. The first batch remains pending owner-side execution after branch review.


## 2026-11-16 — AN8 static remediation and documentation reconciliation

**Status: preparation only. AN8 has not started.** The owner has not synchronized the working branch locally or confirmed the local files. No AN8 SQL was executed, no database connection was made, no metrics were refreshed or approved, and no curated reporting tables were created.

### Static remediation prepared on `feat/an8-preparation-review`

- Reworked AN8.01 to use PostgreSQL catalog statistics rather than a full `COUNT(*)` scan of `staging.student_vle`; estimates are explicitly non-exact.
- Strengthened AN8.02 with duplicate composite-key, NULL-key, row/distinct-key, and bidirectional key-set checks. The Python runner enforces these as a stop/go gate before AN8.03 or downstream extraction.
- AN8.03 remains retrospective denominator context and is gated by AN8.02.
- Runner checks expected result-set count and truncation for every result set, including both AN8.04 result sets. AN8.04 also validates unique/non-NULL course keys, complete course lengths, and assessment-context key-set agreement before AN8.20.
- Consolidated the previously separate activity scans into AN8.20: one high-cost pass returns R0 row/click totals, pre/in/post/no-course-window partitions, in-course active days/resource breadth, post-registration active days/resource breadth/exposure/rate, and source-level matched/unmatched row and click totals.
- AN8.21–AN8.23 are retired audit markers and must not be executed; their measures are included in AN8.20. AN8.20 output is checked against the observed AN8.02 registration denominator and key uniqueness.
- Added local CSV export and a non-sensitive manifest under `outputs/an8/extracts/`; `outputs/an8/` is ignored by Git.
- Rebuilt Notebook 10 as a staged workflow. SQL execution and Python visualization are separate; visualizations consume retained extracts or future curated reporting tables and must not rerun SQL.
- Updated AN8 specification, handover, independent review, SQL inventory, notebook README, and documentation index.

### Adopted owner instruction: extract once, visualize independently

The source queries are to be executed once and their complete results retained. After review, those retained extracts are intended to populate curated PostgreSQL reporting tables through a separately reviewed and explicitly approved DDL/load work order. Visuals and Power BI must read those curated tables or retained exports, not rerun expensive source queries. The tables are planned only; none has been created.

### AN7 documentation reconciliation

The current Notebook 09 evidence and AN7 report/log record 24 visualizations: 15 original plus nine sensitivity figures. The independent review supplied on 2026-11-16 reports that all nine sensitivity figures were visually inspected. The prior Notebook README count of 15 was corrected to 24. No AN7 SQL or notebook analysis was rerun.

### Execution and approval boundaries

- First local batch after synchronization and file confirmation: `AN0.01 → AN8.01 → AN8.02 → AN8.03`.
- AN8.20 is a later standalone high-cost scan, executed once after review of the light outputs.
- No Run All.
- No DDL, table/view/materialized-view/index creation, data load, RAW/QUALITY/STAGING modification, deduplication, PR, or merge.
- No candidate KPI, threshold, weighted score, predictive feature, causal claim, or intervention rule is approved.
- Static review is not SQL parser validation or PostgreSQL execution evidence.

### Repository and archive organization

Added `docs/README.md` as a documentation index distinguishing current authoritative references, historical evidence, superseded/working references, and duplicate/archive policy. No historical files were deleted or moved. The repository remains the source of truth for changing project state; conversation memory stores only durable owner instructions and working preferences.

### Next work order

Wait for local synchronization and explicit confirmation of the branch/files. Then review the actual local working tree and execute the first read-only batch only. After validated extracts, prepare the curated-table DDL/load specification for approval; do not create persistent objects before approval.


---

## Current authoritative snapshot — 2026-11-22 (AN8 Part 2 correction and Part 3 design)

- **Roadmap:** AN8 Part 2 integrated review is represented in Notebook 10 Sections 19–21 with saved execution outputs. AN8 remains OPEN because Part 3 semantic validation, transformation approvals, metric contracts, and reporting outputs remain outstanding. AN9 is planned as a source-faithful baseline, validated working representation, and educational impact comparison. No dashboard has been built.
- **Notebook correction:** Notebook 10 was updated on `feat/an8-csv-review-visualizations` at commit `cd243908bdcf581a9ac9b553dc70813991531330`. The notebook has 149 cells. Sections 19.01–19.07 retain execution counts 37–43 and saved outputs; Section 20 now contains the integrated decision register; new Section 21 summarizes educational findings. Notebook metadata now records the integrated diagnostics as executed with saved outputs reviewed. This was a documentation/metadata update only; no SQL or database session was run.
- **Saved integrated findings:** 32,593 student-presentations; 3,365 without any recorded VLE activity row; 4,093 without in-course activity; 4,093 zero values across each of four zero-inclusive metrics (12.56%); 32,548 known positive registration-relative exposure and 45 unknown; 728 is the arithmetic difference between no in-course activity and no activity row and remains a candidate pre-course-only cohort pending record-level verification. Assessment opportunities: 323,925; submission rows: 173,912; no-submission opportunities: 150,013; submitted NULL scores: 173; observed-zero scores: 329. These are saved Notebook outputs, not a fresh SQL execution in this update.
- **Relative-date semantics:** official OULAD documentation confirms that `studentVle.date`, `studentRegistration.date_registration/date_unregistration`, `assessments.date`, and `studentAssessment.date_submitted` are day offsets relative to module-presentation start, with day 0 as the reference. Negative values are valid pre-start offsets, not automatic errors. Exact calendar dates still require an authoritative exact start-date anchor for each presentation. The meaning of `date_submitted=-1` as a possible sentinel remains unresolved and must be tested against linked `is_banked`, score, assessment, and student records. No date values have been transformed.
- **Part 3 plan:** `docs/AN8_part3_deep_cleaning_analysis_plan.md` expanded with source-semantics protocol, full candidate field inventory, temporal representation, sentinel investigation, snapshot protocol, isolated `oulad_an8_work` schema proposal, AN9-A/B/C educational reporting design, P3.00–P3.08 query groups, and branch integration gates. This is a plan, not executed SQL or approved cleaning.
- **Workspace decision:** `data/raw/` remains immutable; `data/Backup/raw/` is the recovery copy; `data/working/raw/` is the active working copy; `data/Backup/working/<snapshot_id>/raw/` stores immutable named checkpoints. No raw data has been copied or modified in this GitHub work order. The isolated database `oulad_an8_work` is proposed but not created.
- **Repository topology:** main is `44af2a2117e524b469e3cf8df9ee77e9f863f250`; preparation branch is `fa355d7b6cebac39e8392717307135d24c000b75`; feature branch is `cd243908bdcf581a9ac9b553dc70813991531330`. At the comparison checkpoint, the feature branch was 136 commits ahead of main and 0 behind, with 38 changed paths in the full comparison. PR #27 remains OPEN and DRAFT, targets `feat/an8-preparation-review`, and currently reports `mergeable=false`. The PR contains 11 changed paths relative to its preparation-branch base. The full comparison includes inherited AN8 SQL, runner, Notebook 05, documentation, README, and the later Part 2/Part 3 updates. A direct-main integration therefore requires review of the full 37-file diff, not only PR #27's current 8-file diff.
- **Actions performed:** updated Notebook 10; expanded the Part 3 plan; no merge, retarget, database creation, SQL execution, raw file copy, or Power BI build performed. No local working-tree state has been inspected.
- **Next work order:** update Part 2 report, AN8 implementation specification, phase handover, analysis log, documentation index, and current README status; review all 37 branch changes and historical status conflicts; then present the proposed integration route for approval. Only after Part 2 integration is agreed should a dedicated Part 3 branch and final SQL query pack be prepared.


## Current repository state refresh — 2026-11-22 (after documentation alignment)

- Notebook 10, Part 3 plan, Part 2 report, AN8 specification, phase handover, data dictionary, analysis log, progress ledger, historical scope report, documentation index, README, and PR #27 description were updated on the feature branch.
- The historical AN8 specification and handover paragraphs that described Section 19 as pending were explicitly labelled as superseded checkpoint statements; the current saved execution state is stated separately.
- PR #27 currently contains 11 changed paths relative to `feat/an8-preparation-review`; the complete feature branch comparison to `main` contains 38 paths and was 136 commits ahead / 0 behind at the latest comparison checkpoint. The branch is a descendant of main. GitHub's PR mergeability flag currently reports false, so merge readiness is not established even though the branch comparison is ahead-only.
- No merge, PR retarget, branch deletion, local sync, SQL execution, database creation, working-copy file copy, or Power BI build occurred.

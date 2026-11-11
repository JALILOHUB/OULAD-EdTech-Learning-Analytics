# AN6 — Recorded VLE Activity Patterns

**Status:** CLOSED — all four canonical investigations executed; six result sets retained and reconciled in Notebook 08.  
**Entry dependency:** AN5 closure, Section 17.  
**Grain:** One registered student-presentation: `(code_module, code_presentation, id_student)`.

## Purpose and frozen metric contract

AN6 describes recorded VLE activity within the course-relative presentation window. The eligible population is every unique registered student-presentation in `staging.student_registration`; registrations without in-course activity remain in the denominator. Join registration/activity on all three key columns and course metadata on `code_module, code_presentation`.

The inclusive in-course window is `0 <= student_vle.date <= courses.module_presentation_length`. Temporal classes are PRE_COURSE (`date < 0`), IN_COURSE (0 through course length inclusive), and POST_COURSE (greater than course length). Primary measures are in-course recorded-activity presence/coverage, distinct active days, distinct resource IDs, and first in-course activity day. Distinguish OUTSIDE_WINDOW_ONLY from NO_RECORDED_ACTIVITY. R0 is used for presence/day/resource measures; AN5 found these invariant across R0/R1/R2. Click volume remains secondary and sensitivity-qualified. Do not repeat R1/R2 scans.

Fixed seven-day bins begin at relative day 0; they are not academic weeks and do not replace VLE week_from/week_to. Use the fixed registered cohort; do not exclude registrations based on date_unregistration. Missing platform rows do not mean absence of learning.

## Research questions

| ID | Question | Acceptance evidence |
|---|---|---|
| Q01 | Are course windows valid? | One non-negative length per presentation; missing/duplicate keys reported. |
| Q02 | Are VLE resource metadata and keys usable? | (code_module, code_presentation, id_site) uniqueness; missing activity_type/week_from/week_to; registration-key, registration-to-course match, and activity-key integrity. |
| Q03 | What is in-course activity coverage? | Numerator/denominator per presentation; separate outside-only and no-recorded-activity states. |
| Q04 | How are active days/resource breadth distributed? | Zero-inclusive cohort; P25, median, P75, P90, mean, zero count. |
| Q05 | When is first in-course activity recorded? | Distribution among activity-bearing presentations; zero cohort separately visible. |
| Q06 | How does activity distribute over PRE/IN/POST and relative seven-day periods? | Temporal totals reconcile; final period may be partial. |
| Q07 | How is survivorship handled? | Fixed registered cohort; no date_unregistration filtering. |
| Q08 | How does activity composition vary by activity_type? | Distinct resources and registered student-presentation reach; unknown/unmatched metadata retained. |
| Q09 | What is the state of VLE week metadata? | Completeness only; no filtering or academic-week equivalence. |
| Q10 | Is another repeated-row sensitivity run needed? | No; use R0 for invariant measures; clicks remain secondary. |
| Q11 | Do boundaries reconcile? | Day -1, day 0, final in-course day, length+1, registrations/activity without course metadata, and temporal totals. |

## Canonical SQL package

| Query | File | Expected result sets | Purpose |
|---|---|---:|---|
| AN6.01 | AN6.01_activity_readiness_and_metadata.sql | 3 | Course windows, VLE metadata, registration/activity keys. |
| AN6.02 | AN6.02_in_course_student_presentation_metrics.sql | 1 | Coverage, zero-inclusive distributions, first activity, no-activity states. |
| AN6.03 | AN6.03_relative_time_patterns.sql | 1 | PRE/IN/POST and relative seven-day periods. |
| AN6.04 | AN6.04_activity_type_resource_patterns.sql | 1 | Activity-type resource breadth/reach and metadata matching. |

Expected total: six result sets by design, not execution evidence.

## Runner, notebook, and safety

`scripts/run_an6.py` uses the existing `src.analytics.db.run_query`; the shared helper is unchanged. It runs AN0.01 preflight, AN6.01 first, checks readiness, then executes selected downstream queries sequentially. High-cost scans use 600,000 ms. Optional bounded CSV outputs and a non-sensitive manifest go to Git-ignored `outputs/an6/`.

`notebooks/08_an6_recorded_vle_activity_patterns.ipynb` explains each question before its code cell, stores outputs in `query_results`, displays result sets/runtime/truncation, and creates figures only from returned frames. It contains no invented outputs. Run cells individually, not Run All.

AN6.01 blocks downstream analysis if course windows, course-scoped VLE resource keys, registration keys, activity key components, or activity-to-course matches are invalid. Missing activity_type/week metadata is reported, not filtered. Do not modify RAW/STAGING, create persistent objects/indexes, deduplicate source rows, load all student_vle into Pandas, or run concurrent large scans.

## Interpretation and downstream boundaries

These measures describe records in the VLE source, not attention, learning, effort, comprehension, or achievement. Negative course-relative days do not establish timing relative to personal registration. Resource breadth is not time spent. No composite score, threshold, causal effect, outcome association, predictive feature, or intervention is approved.

AN7 may examine outcome associations only after resolving CMA due-date semantics, is_banked, assessment weights, withdrawal definitions, and leakage-safe temporal boundaries. AN8 must define prediction cutoff and feature window. AN9 validates metrics/marts; AN10 Power BI follows metric approval; AN11 is the final evidence-based report. A separate data-science phase begins only after the analytical phase is complete.


## 2026-11-08 implementation correction

The first local AN6.01 attempt exposed an aggregate-scope defect in the registration-key summary: `key_rows` was referenced in the outer aggregate without being carried out of the grouped registration CTE. The corrected query carries `key_rows` through `registration_course_match` and performs duplicate/excess-row calculations in a dedicated one-row `registration_profile` aggregate. This is a SQL-definition correction, not a Python or database-connection failure.

VLE resource identity is validated and joined using the course-scoped key `(code_module, code_presentation, id_site)`, rather than assuming `id_site` is globally unique across all presentations. AN6.04 applies this complete key in both its activity-type and metadata-reconciliation joins. The readiness gate checks duplicate/null resource-key components, duplicate registration keys, registration-to-course matches, student_vle key completeness, and activity-to-course-window matches.

The notebook's AN6.01 cell displays all three bounded result sets before evaluating the readiness gate. The AN0.01 cell displays the returned database identity and read-only session settings, plus explicit PASS/FAIL checks and elapsed time. Notebook 08 delegates preflight, AN6.01 readiness, and downstream query execution to the canonical `scripts.run_an6` functions so the script and notebook share identical execution gates and PostgreSQL diagnostics.

**Validation boundary:** static file review only. The corrected SQL has not been executed against the local PostgreSQL database, and no successful AN6 preflight or readiness result is claimed.


## 2026-11-09 — AN6.03 memory-pressure correction

The first local AN6.03 run reached PostgreSQL execution but failed with PostgreSQL OutOfMemory in the TupleSort memory context. This is a server-side sort/aggregation memory failure, not a Python dataframe allocation or a connection/preflight failure.

AN6.03 was redesigned to:
- Remove the composite COUNT(DISTINCT (id_student, id_site, date)) metric, which is not required by the temporal-pattern question.
- Avoid COUNT(DISTINCT id_student) over the full activity-row set by first aggregating to student-presentation × temporal bucket/period grain using GROUPING SETS, then summing row counts and counting the already-unique student-level groups.
- Preserve exact activity-row and secondary click totals, registered-student reach, unmatched-registration activity-row counts, PRE/IN/POST/NO_COURSE_WINDOW classifications, seven-day periods, and the four boundary-day diagnostics.
- Remove the final global ORDER BY; consumers should not rely on implicit row order.

The boundary diagnostic still uses a distinct-student count, but only over the four explicit boundary dates per course presentation rather than the full 10.6M-row activity population.

The notebook now calls the canonical AN6 runner for preflight, readiness, and downstream queries. PostgreSQL exceptions are reported with query ID, SQL file, SQLSTATE, primary message, detail, and hint, then re-raised with exception chaining. No automatic retry is performed.

**Execution evidence supplied by the project owner:** AN0.01 preflight passed; AN6.01 returned three result sets and its readiness checks passed; AN6.02 returned 88 rows across 22 presentations and four measures per presentation. AN6.03 then failed with PostgreSQL OutOfMemory in TupleSort. These are owner-supplied local execution outputs, not executions performed by this repository review.

**Validation boundary:** SQL and Python changes are statically reviewed only. AN6.03 has not been rerun after this correction. The new query plan, runtime, memory use, and result reconciliation remain unverified until the owner executes the updated notebook.


## 2026-11-11 — Execution review and analytical closure

All four canonical investigations were executed locally after the AN0.01 read-only preflight passed on `oulad_analytics` (PostgreSQL 18.6). The saved notebook retains all six result sets without truncation.

| Query | Result sets | Returned rows | Batch runtime |
|---|---:|---:|---:|
| AN6.01 | 3 | 22, 1, 1 | 27.348 s |
| AN6.02 | 1 | 88 | 156.565 s |
| AN6.03 | 1 | 971 | 154.189 s |
| AN6.04 | 1 | 254 | 247.918 s |

### Verified findings

- AN6.01 readiness passed for 22 module-presentations, 6,364 unique course-scoped VLE resource keys, 32,593 unique registration keys, complete activity-key components, and matching course windows.
- AN6.02 reconciled the registered population: 28,500 of 32,593 student-presentations had in-course recorded activity (87.44%); 728 had outside-window-only activity; 3,365 had no recorded activity in any observed window. The denominator includes all eligible registered student-presentations.
- AN6.03 returned 971 complete rows. Temporal buckets and relative seven-day periods each reconciled to 10,655,280 activity rows. In-course reach and denominators matched AN6.02, and all 88 boundary diagnostics were present. IN_COURSE accounted for 9,966,292 rows (93.53%) and PRE_COURSE for 688,988 (6.47%). No POST_COURSE bucket was returned.
- AN6.04 returned 254 complete rows. All 10,655,280 activity rows matched resource metadata; there were zero unmatched resource rows, zero missing `activity_type` rows, and zero unmatched-registration activity rows. Registered in-course activity-type totals reconciled across all 22 module-presentations.
- `week_from` and `week_to` were each missing in 5,243 of 6,364 resource records. Their missingness overlap and distribution were not assessed.

### Accepted interpretation boundaries

The 87.44% AN6 in-course coverage is not interchangeable with AN5's 89.68% overall any-window activity coverage. All AN6 measures describe recorded VLE rows, not learning, attention, effort, comprehension, or achievement. PRE_COURSE is relative to presentation start, not personal registration. Activity-type reach is non-additive. Activity-row and click volumes remain sensitive to unresolved repeated source rows. The absence of a POST_COURSE bucket is an observed dataset result, not an established extraction-boundary explanation.

### Notebook and repository closeout

Notebook 08 retains 12 executed code cells, all six result sets, Python-only reconciliation outputs, and the visual summaries. The duplicated Section 13 Markdown cell (duplicate cell ID) and final empty code cell were removed. The stale Figure 1 note requesting a rerun was corrected: the retained output already reports 22 distinct module-presentations, 795 complete presentation-period observations, and 22 excluded partial/post-course period rows. No SQL or analysis code cell was rerun during closeout.

**Decision:** AN6 is closed for its approved descriptive scope. No production KPI, composite score, causal claim, intervention threshold, predictive feature, or AN7 execution is approved. RAW, QUALITY, and STAGING remain unchanged; no persistent database objects or indexes were created.

### Handoff to AN7

AN7 may be scoped only after the following are frozen and documented: final-result versus unregistration definitions; the meaning and valid treatment of `is_banked`; assessment-weight and score coverage; CMA due-date semantics; and leakage-safe observation cutoffs and feature windows. AN7 must not use retrospective final outcomes as predictors of earlier activity.

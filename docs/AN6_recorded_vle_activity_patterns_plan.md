# AN6 — Recorded VLE Activity Patterns

**Status:** Prepared for controlled local execution; no AN6 SQL has been executed.  
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
| Q02 | Are VLE resource metadata and keys usable? | id_site uniqueness; missing activity_type/week_from/week_to; registration-key, registration-to-course match, and activity-key integrity. |
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

AN6.01 blocks downstream analysis if course windows, VLE id_site, registration keys, or activity key components are invalid. Missing activity_type/week metadata is reported, not filtered. Do not modify RAW/STAGING, create persistent objects/indexes, deduplicate source rows, load all student_vle into Pandas, or run concurrent large scans.

## Interpretation and downstream boundaries

These measures describe records in the VLE source, not attention, learning, effort, comprehension, or achievement. Negative course-relative days do not establish timing relative to personal registration. Resource breadth is not time spent. No composite score, threshold, causal effect, outcome association, predictive feature, or intervention is approved.

AN7 may examine outcome associations only after resolving CMA due-date semantics, is_banked, assessment weights, withdrawal definitions, and leakage-safe temporal boundaries. AN8 must define prediction cutoff and feature window. AN9 validates metrics/marts; AN10 Power BI follows metric approval; AN11 is the final evidence-based report. A separate data-science phase begins only after the analytical phase is complete.


## 2026-11-08 implementation correction

The first local AN6.01 attempt exposed an aggregate-scope defect in the registration-key summary: `key_rows` was referenced in the outer aggregate without being carried out of the grouped registration CTE. The corrected query carries `key_rows` through `registration_course_match` and performs duplicate/excess-row calculations in a dedicated one-row `registration_profile` aggregate. This is a SQL-definition correction, not a Python or database-connection failure.

VLE resource identity is validated and joined using the course-scoped key `(code_module, code_presentation, id_site)`, rather than assuming `id_site` is globally unique across all presentations. AN6.04 applies this complete key in both its activity-type and metadata-reconciliation joins. The readiness gate checks duplicate/null resource-key components, duplicate registration keys, registration-to-course matches, student_vle key completeness, and activity-to-course-window matches.

The notebook's AN6.01 cell displays all three bounded result sets before evaluating the readiness gate. The AN0.01 cell displays the returned database identity and read-only session settings, plus explicit PASS/FAIL checks and elapsed time. Downstream analytical cells retain the direct shared `run_query` pattern and their existing sequence.

**Validation boundary:** static file review only. The corrected SQL has not been executed against the local PostgreSQL database, and no successful AN6 preflight or readiness result is claimed.

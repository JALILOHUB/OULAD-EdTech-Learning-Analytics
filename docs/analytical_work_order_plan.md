# Analytical Work Order Plan — WO-1B

**Project:** OULAD — EdTech Learning Analytics  
**Status:** Saved query execution evidence reviewed; targeted semantic reconciliation remains open  
**Work branch:** `work/wo-1-analytical-readiness`  
**Scope:** Targeted, read-only diagnostics supporting analytical readiness.

## 1. Rationale

The initial readiness checks established that the student-presentation composite key is complete and unique in `student_info` and `student_registration`, that the two key sets reconcile, and that joining student-assessment rows to student profiles by `id_student` alone causes row multiplication.

Those checks do not establish all relevant course and assessment metadata cardinalities, activity coverage among matching registrations, registrations without recorded VLE activity, activity-to-resource metadata coverage, or the selected profile distributions and missingness. These questions affect relationship validation, denominators, and subsequent metric definitions.

WO-1B extends the existing readiness work. It does not restart RAW/STAGING engineering or repeat the completed engineering quality suite.

## 2. Diagnostics and saved execution status

| Query ID | Purpose | Validation focus |
|---|---|---|
| `AN1.04` | Course-presentation relationships | Distinguish physical course rows from distinct keys and measure join cardinality. |
| `AN1.05` | Assessment metadata relationships | Separate source, matched, unmatched, and joined rows; supplement rather than repeat AN1.03. |
| `AN1.06` | Registration/person grain | Distinguish student-presentation records from distinct people and profile presentation counts per person. |
| `AN1.07` | Activity coverage by presentation | Match on module, presentation, and student; state the registration denominator and report unmatched activity separately. |
| `AN1.08` | Registrations without recorded activity | Identify registrations without a matching `student_vle` row without interpreting absence as withdrawal or lack of learning. |
| `AN1.09` | VLE resource-match coverage | Distinguish physical metadata rows from distinct site keys and report matches/gaps without join fan-out. |
| `AN2.03` | Presentation-size profile | Report presentation populations and course-length context. |
| `AN2.04` | Gender, age, and disability distributions | Preserve presentation denominators and explicit missing categories. |
| `AN2.05` | Region and education distributions | Describe composition without causal interpretation. |
| `AN2.06` | Numeric student profile | Summarize previous attempts and studied credits with range and median as well as mean. |
| `AN2.07`–`AN2.09` | IMD missingness profiles | Compare missingness by presentation, region, and recorded final-result category with explicit denominators. |

The canonical SQL files and saved notebook outputs establish that the diagnostics were executed in the recorded local session. This review does not re-execute PostgreSQL queries. The saved outputs show successful execution for AN1.04–AN1.09 and AN2.03–AN2.09; AN2.02 also has 88 returned rows. Wide Pandas representations abbreviate middle rows, so a focused compact reconciliation—not a full rerun—is still required for AN2.02, AN2.04, and AN2.05.

## 3. Safety and execution controls

- The diagnostics are intended to be read-only SELECT statements.
- No tables, views, indexes, constraints, or data are created or modified.
- RAW and STAGING remain unchanged. No `student_vle` rows are deleted, deduplicated, or aggregated by these checks.
- Preserve `default_transaction_read_only=on` and `lock_timeout=5000`.
- Preserve the default `statement_timeout=120000` ms. The optional 600,000 ms timeout is reserved for `AN1.07`, `AN1.08`, and `AN1.09`, run individually after the local runner change has been reviewed and tested.
- Keep aggregation in PostgreSQL; do not load the full `student_vle` table into Pandas.
- Do not backfill historical quality-registry execution timestamps.
- Record query ID, elapsed time, displayed rows, truncation status, errors, and interpretation for every executed query.

## 4. Result-review criteria

For each result, review:

1. **Cardinality:** source rows, distinct keys, joined rows, and unmatched keys.
2. **Grain:** whether each output row represents the declared unit.
3. **Denominators:** whether activity coverage is measured against matching registered student-presentations.
4. **Missingness:** keep NULL, zero, and absence of a recorded event distinct.
5. **Runtime and completeness:** confirm successful execution and whether display truncation affects interpretation.
6. **Interpretation:** separate observed results from explanations that still require investigation.
7. **Evidence state:** record execution only when supported by returned output; accept a finding only after semantic review.

## 5. Interpretation constraints

A registration without a matching `student_vle` row means that no activity row was found under the tested join. It does not prove that the student did not learn, withdrew, or used no other learning channel.

A resource-metadata mismatch requires investigation but is not automatically evidence of corrupt data. Distinct keys must not be confused with physical row counts, and student IDs must not be confused with student-presentation records.

The `student_vle` sensitivity scenarios R0 (all recorded rows), R1 (exact six-column duplicates removed for metric calculation only), and R2 (maximum `sum_click` per five-column candidate-key group) remain alternative metric definitions. They do not establish the true event grain and do not authorize changes to RAW or STAGING.

AN2.02 returned 88 rows, but its saved Pandas representation abbreviates middle rows. Verify category totals and missing-outcome handling with a compact aggregate before publishing detailed result distributions.

## 6. Exit criteria and current disposition

The execution portion of WO-1B is evidenced by the saved notebook outputs. The documentation and broad interpretation are now aligned to that evidence. Full work-order closure remains conditional on a compact reconciliation for AN2.02, AN2.04, and AN2.05; this is a targeted validation task, not a reason to rerun all queries.

No unvalidated result is promoted to a KPI, dashboard, or public claim.

**Current status:** Saved execution evidence reviewed. Focused category-total and NULL/unclassified reconciliation remains open for AN2.02, AN2.04, and AN2.05.

# AN8 — Initial Results and Analytical Scope Extension

**Historical status:** Initial read-only extraction and scope-extension rationale, prepared before AN8.30–AN8.36 execution. For completed Part 2 evidence and interpretation, see reports/AN8_part2_analytical_findings_report.md.  
**Analytical grain:** One registered student-presentation: (code_module, code_presentation, id_student).  
**Source layer:** PostgreSQL STAGING.  
**Decision boundary:** No production KPI, curated mart, Power BI dataset, predictive feature, or machine-learning model is approved by this report.

## 1. Executive assessment

The first AN8 execution batch successfully established important structural and denominator controls and produced a reconciled, zero-unmatched R0 activity extract. It did not yet deliver the breadth of descriptive analysis required for a professional reporting layer. In particular, it did not quantify full metric distributions, evaluate how repeated source rows change candidate metrics, compare activity profiles by outcome at presentation level, or provide a complete assessment-participation profile.

The correct disposition is therefore **AN8 remains open**. The initial execution is valid evidence for the questions it addressed; it is not evidence that the broader analytical stage is complete.

## 2. Initial execution evidence

The following values are from owner-executed notebook outputs retained in Notebook 10. They are historical local execution evidence, not a fresh database execution during preparation of this report.

### 2.1 Read-only preflight and source inventory

- Database: `oulad_analytics`; PostgreSQL 18.6.
- `transaction_read_only=on` and `default_transaction_read_only=on`.
- Statement timeout: two minutes; lock timeout: five seconds.
- All seven expected STAGING relations were present.
- AN8.01 used PostgreSQL planner/catalog estimates rather than exact full-table counts. The zero estimate for courses is not evidence that the table is empty. Analyze timestamps were NULL in the returned catalog profile.

### 2.2 Cohort grain and key integrity

AN8.02 passed all six checks:

- `student_info`: 32,593 rows and 32,593 distinct student-presentation keys.
- `student_registration`: 32,593 rows and 32,593 distinct student-presentation keys.
- Zero duplicate composite-key groups and zero NULL-key rows in either table.
- Zero differences in either direction between the two composite-key sets.

The accepted cohort grain for AN8 is therefore one student within one module-presentation, not one unique person across the entire dataset.

### 2.3 Retrospective outcome distribution

AN8.03 returned 32,593 student-presentation records, all matched to registration:

| Final result | Student-presentations | Share |
|---|---:|---:|
| Pass | 12,361 | 37.93% |
| Withdrawn | 10,156 | 31.16% |
| Fail | 7,052 | 21.64% |
| Distinction | 3,024 | 9.28% |
| **Total** | **32,593** | **100.00% (rounded)** |

The category-specific distinct-student counts are not additive because people may appear in more than one presentation. `final_result` is retrospective outcome context only; it is not a contemporaneous predictor.

### 2.4 Course and assessment context

AN8.04 returned two result sets covering 22 module-presentations and their assessment context. Across the dataset, 206 assessments were profiled and 11 had missing due dates. Due dates and weights do not establish when scores or feedback became available to students.

### 2.5 Registration timing

AN8.10 classified the 32,593 registrations as follows:

| Registration timing | Count |
|---|---:|
| Before course start | 32,312 |
| After course start | 234 |
| On course start | 2 |
| Missing registration date | 45 |
| **Total** | **32,593** |

Missing dates remain unknown; they must not be imputed as day zero without a separately justified sensitivity analysis.

### 2.6 Unregistration-date reconciliation

AN8.11 returned this outcome/date cross-tab:

| Final result | Has unregistration date | No unregistration date |
|---|---:|---:|
| Distinction | 0 | 3,024 |
| Pass | 0 | 12,361 |
| Fail | 9 | 7,043 |
| Withdrawn | 10,063 | 93 |

The 93 Withdrawn records without a date and nine Fail records with a date are anomalies in the relationship between the outcome label and date field. They are not automatically invalid rows and must remain visible in sensitivity work.

### 2.7 Assessment score missingness

AN8.12 classified 173,912 student-assessment records:

| Score state | Rows |
|---|---:|
| Nonzero observed score | 173,410 |
| Observed zero score | 329 |
| NULL score | 173 |
| **Total** | **173,912** |

A genuine zero is not missing. A NULL score is not a zero and does not, by itself, prove no submission.

### 2.8 Consolidated R0 activity extraction

AN8.20 completed in 85.582 seconds and returned 32,593 student-presentation rows and 37 columns.

| Reconciliation item | Rows / clicks |
|---|---:|
| Source `student_vle` activity rows | 10,655,280 |
| Source recorded clicks | 39,605,099 |
| Activity rows matched to registered cohort | 10,655,280 |
| Unmatched activity rows | 0 |
| In-course activity rows | 9,966,292 |
| Pre-course activity rows | 688,988 |
| Post-course activity rows | 0 |
| No-course-window activity rows | 0 |

The activity partitions reconcile to the full source-row count. The zero unmatched count is evidence for the tested registration join, not proof that every activity record represents a unique interaction or valid learning event. R0 preserves every source row; no deduplication was performed.

The Python reconciliation cell validated the exported extract and cohort denominator. It did not replace SQL aggregation with a second independent analysis. The retained notebook display showed only a preview of the extract; complete distributions were not established by that preview.

## 3. What the first execution did not answer

The initial batch did not yet provide:

1. R0/R1/R2 metric-impact comparisons using the current source state.
2. Zero-inclusive distributions for activity rows, clicks, active days, and resource breadth.
3. Registration-adjusted exposure distributions and explicit zero/unknown exposure states.
4. Presentation-specific activity distributions by retrospective outcome.
5. Assessment opportunity coverage that separates no submission, recorded NULL, observed zero, and nonzero score.
6. Multi-dimensional student-profile segmentation with visible missing categories and small-cell review.
7. A complete decision on which candidate metrics are stable enough for a reporting contract.

The initial charts were also insufficient for the requested analytical depth: a category-count chart and a module-level median active-day chart cannot substitute for distributional analysis, presentation comparisons, exposure sensitivity, or outcome segmentation.

## 4. Scope extension: AN8.30–AN8.36 (subsequently executed)

Seven read-only SQL investigations have been prepared and linked to Notebook 10:

| Query | Purpose | Execution cost |
|---|---|---|
| AN8.30 | R0/R1/R2 scenario totals and source/reference/temporal quality profile | High |
| AN8.31 | Zero-inclusive distributions of source rows, clicks, active days, and resource breadth | High |
| AN8.32 | Registration timing and available course exposure | Low |
| AN8.33 | Candidate metric definitions, grains, denominators, limitations, and approval state | Very low |
| AN8.34 | Activity distributions by outcome within each module-presentation | High |
| AN8.35 | Assessment participation and score-state coverage | Moderate |
| AN8.36 | Outcome segmentation across student-profile dimensions | Low |

At the time this initial scope document was prepared, these were planned artifacts only. They were subsequently executed by the owner and their 17 result sets were exported and reviewed. The completed findings are recorded in reports/AN8_part2_analytical_findings_report.md. High-cost queries were run individually after the cohort gates passed.

## 5. Data-cleaning decision and analytical architecture

The project owner has decided to preserve a full copy of the current local `data` directory (reported size approximately 487 MB) outside the project before any local file cleanup. This is a sensible additional recovery safeguard, but it does not replace the database RAW layer or a reproducible transformation history.

The next analytical design should distinguish four data states:

1. **Immutable source evidence:** original OULAD archive/files retained outside the active project and the PostgreSQL RAW layer retained unchanged.
2. **Typed source representation:** existing QUALITY and STAGING layers, whose current semantics and validation evidence remain reproducible.
3. **Derived analytical data:** new, versioned and reproducible transformations for each justified analytical case. These may filter, normalize, reshape, aggregate, resolve duplicates under an explicit scenario, or exclude records only where a documented rule and sensitivity evidence justify it.
4. **Curated reporting outputs:** validated student-presentation facts and supporting dimensions for Power BI, created only after the metric contract and persistence design are reviewed and approved.

The decision is not to preserve every problematic record in every analytical output. It is to preserve the evidence and make every transformation explicit, reversible, measurable, and comparable. A record may be excluded from a specific metric's denominator when its fields make that metric undefined, but the exclusion must be counted, reasoned, and tested against an alternative. It must not silently disappear from the dataset.

### Required transformation register

Every proposed cleaning operation must record:

- source table/file and source grain;
- target analytical grain;
- exact rule and SQL/Python implementation;
- rows and keys affected;
- reason (invalid domain, impossible relationship, duplicate scenario, out-of-window observation, missing required denominator, or analytical scope);
- whether the rule is correction, exclusion, normalization, deduplication scenario, or derived feature;
- before/after row counts and metric impact;
- sensitivity alternative and its result;
- approval state and version.

No blanket deletion, automatic outlier removal, mean imputation, or deduplication is approved. Statistical outliers must first be profiled by context; unusual values are not automatically errors.

## 6. Why deeper cleaning is necessary — and what it does not mean

A Power BI dashboard built directly on unresolved source semantics can produce misleading totals, inconsistent denominators, and measures that change when report filters alter join paths. A predictive workflow can inherit the same defects and amplify them through leakage, target contamination, or train/validation distribution differences.

However, cleaning is not an end in itself. The project should not force all seven source tables into one universally “clean” dataset. Different questions require different analytical populations and time windows. For example:

- engagement metrics require explicit exposure and zero-activity handling;
- click-volume metrics require repeated-row sensitivity;
- outcome comparisons require retrospective labels and presentation-specific denominators;
- assessment participation requires assessment-opportunity denominators and score-state semantics;
- predictive features require strict availability-at-cutoff rules, not merely non-NULL values.

Thus, the defensible target is a family of purpose-specific derived datasets and a shared, validated metric contract—not destructive rewriting of the source.

## 7. Role of Notebook 05 — Python Advanced Analytics

Notebook 05 is currently a three-section placeholder, not an executed analysis. It should become the Python advanced-analysis workbench after SQL has produced the relevant analytical extracts.

Python adds value for:
- statistical inference and effect-size estimation;
- bootstrap confidence intervals and repeated-person sensitivity;
- multivariate diagnostics and carefully scoped segmentation;
- outlier diagnostics after domain validation;
- visualization and uncertainty communication;
- later, temporal validation and model evaluation if AN10 authorizes a predictive study.

Python should not re-read the entire 10.6-million-row `student_vle` table into Pandas for ordinary aggregations. PostgreSQL should produce grain-controlled extracts first. Notebook 05 should consume bounded, versioned SQL outputs and document why each specialized Python method is necessary. Machine-learning training remains outside AN8 and is conditional on the later AN10 readiness decision.

## 8. Current phase decision

- AN8 is **OPEN — INITIAL EXTRACTION EXECUTED; EXTENDED ANALYSIS PREPARED, NOT EXECUTED**.
- The existing RAW, QUALITY, and STAGING layers remain unchanged.
- No permanent tables, views, materialized views, indexes, or schemas were created by the extension.
- No candidate KPI or Power BI model is approved.
- AN9 Power BI remains blocked until AN8 metrics, denominators, cleaning rules, and reporting outputs are validated.
- AN10 remains a predictive-readiness gate after AN9; model training is not authorized by this report.
- AN11 remains the consolidated final analytical report.

## 9. Next work order

1. The owner preserves the local `data` directory outside the project and verifies the backup by file count, sizes, and preferably checksums.
2. Review and execute AN8.30–AN8.36 individually through the read-only runner; capture complete outputs and runtimes.
3. Review the results and decide which cleaning/sensitivity cases are necessary.
4. Create purpose-specific derived datasets in a separate analytical workspace; preserve transformation SQL, row-level exclusion reasons, and reconciliation outputs.
5. Complete the metric contract and reporting grain.
6. Only then prepare and approve persistent curated reporting objects for Power BI.

No local files were deleted or changed as part of this report preparation. No database SQL was executed during report preparation.


## 10. Historical disposition

This document preserves the initial rationale and pre-execution scope decision. Its former statements that AN8.30–AN8.36 were unexecuted are historical and were superseded by owner-executed outputs saved in Notebook 10. The integrated diagnostic cells added after CSV review remain pending local execution. Consult the Part 2 findings report and current progress ledger for the latest state.

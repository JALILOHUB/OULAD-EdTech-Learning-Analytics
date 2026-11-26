# Part 3 — Deep Data Cleaning and Analytical Validation Plan

**Status:** The isolated source import is complete. P3.00 and P3.07 passed structural gates. P3.01–P3.06 have retained read-only executions and interpretation. P3.02/P3.05 outputs are under current-SQL manifest reconciliation; the saved P3.05 export contains four result sets while the revised SQL defines five. No transformation or production metric is approved.
**Dependency:** AN8 Part 2 evidence is retained in Notebook 10 and its CSV exports; Part 3 uses a separate Notebook 11 for Python analysis.  
**Source preservation:** Original OULAD files and PostgreSQL RAW, QUALITY, and STAGING remain immutable.

## 1. Purpose

Part 3 converts the AN8 findings into defensible, purpose-specific derived datasets. It is not a blanket attempt to make every source table conform to one universal cleaned version.

The business risk is concrete: repeated activity records can change click totals by 3.19%–13.14% under plausible but unverified assumptions; pre-course activity can inflate course-engagement totals; missing registration dates make exposure unknown; zero recorded activity can be hidden by positive-only denominators; and assessment/profile states can be misclassified if NULL, zero, no submission, and small groups are collapsed.

The target is a reproducible set of purpose-specific derived datasets with transparent transformation lineage and sensitivity results, suitable for validated reporting contracts and the subsequent Power BI stage.

## 1.1 Analytical lineage and completed-stage reference

The current work builds on the following completed analytical stages; their saved evidence remains the reference baseline and must not be rerun merely to refresh this plan.

| Stage | Scope and retained evidence | Status |
|---|---|---|
| RAW / QUALITY / STAGING | Seven source relations; typed STAGING; historical S1–S4 checks; 29 quality tests (25 PASS, 4 REVIEW, 0 FAIL). | Complete within documented scope |
| WO-1 / AN0–AN2 | Database readiness, student-presentation grain, composite-key reconciliation, join fan-out analysis, profiles, and IMD missingness. | Complete |
| WO-2 / AN3–AN4 | Withdrawal/registration timing, outcome conflicts, assessment structure, missing due dates, score states, banked records, and assessment participation. | Complete |
| AN5 | R0/R1/R2 repeated-activity sensitivity; 10,655,280 source rows and 39,605,099 recorded clicks retained as R0. | Closed; no deduplication rule approved |
| AN6 | Course-window engagement; 9,966,292 in-course activity rows and 87.44% student-presentation coverage under the established 0..L convention. | Closed within documented scope |
| AN7 | Outcome associations across 22 presentations; binary and ordinal analyses with sensitivity outputs. | Analytically closed; observational, not causal or predictive |
| AN8 Part 1 | Validated cohort and source reconciliation: 32,593 student-presentations, 10,655,280 VLE rows, 39,605,099 clicks, and in-/pre-course activity partitions. | Complete |
| AN8 Part 2 | 15 query records, 17 CSV result sets, 37,584 exported rows, six passing gates, zero export errors; Notebook 10 Sections 19–21 retain the integrated review. | Complete and merged into main |
| AN8 Part 3 | Source-semantic diagnostics, controlled transformations, row/key impact, and metric/reporting contracts. | Diagnostics executed; semantic gates under review |

The validated analytical grain for student context is the student-presentation key: `(code_module, code_presentation, id_student)`. Assessment analysis uses the student-assessment opportunity grain. A student may appear in multiple presentations; counts must not be described as unique people unless deduplicated at that separate grain.

Key unresolved evidence carried into Part 3:
- The 3,365 student-presentations with no recorded VLE row and the 4,093 with no in-course VLE row differ by 728. P3.04 reconciled this difference as 728 pre-course-only presentations; keep this state separate from no-row and in-course activity.
- The 45 missing registration dates remain unknown; no day-zero imputation is permitted.
- The 173 NULL scores, 329 observed zero scores, and 150,013 assessment opportunities without a submission record remain separate states.
- The meaning of `student_assessment.date_submitted = -1` remains unresolved.
- R0 remains the source-faithful activity baseline. R1 and R2 are sensitivity scenarios, not approved source corrections.

**Downstream sequence:** complete and validate AN8 Part 3 and its metric/reporting contracts; then build AN9 Power BI from approved reporting outputs; then complete the final evidence-based analytical report. Prediction and machine learning belong to a separate Data Science phase after Power BI and are outside the current AN8 scope.


## 2. Entry gate

The evidence and workspace checks already completed are retained as historical/current inputs; do not repeat them without a concrete discrepancy.

1. Notebook 10 Sections 19–21 and the 17 CSV exports are the completed AN8 Part 2 evidence. Preserve Notebook 10; do not rerun its SQL or CSV-review sections to restart Part 3.
2. The owner verified all eight source/backup/working file hashes and backup-manifest comparisons on 2026-11-22. The seven working CSVs then passed the importer SHA-256 and column-set dry-run on 2026-11-24. Do not repeat either check unless source files, manifest, or importer change.
3. The owner verified 67.51 GB free on G:, PostgreSQL 18.6, the active role postgres with CREATEDB=true, existing database oulad_analytics (1269 MB), and absence of oulad_an8_work on 2026-11-24.
4. The owner created `oulad_an8_work`, verified the four approved schemas and seven empty `source_ref` tables, and imported all seven source CSVs in one transaction on 2026-11-26. The importer reported the exact expected row counts and committed successfully. Do not repeat setup or import when the notebook's state checks confirm the expected objects and counts. Do not alter `oulad_analytics`, RAW, QUALITY, or STAGING.
5. Notebook 11 is the primary auditable interface for setup, import verification, P3 execution, and Python review. Its guarded setup cell creates the database/schema/tables only when absent, skips complete existing state, and stops on partial/unexpected state. Its import cell runs the existing controlled importer only when all seven source tables are empty; it skips a complete expected import and stops on partial counts.
6. P3.00 was executed read-only on 2026-11-26 and passed: seven relations, 43 TEXT columns, and exact row counts.
7. P3.07 was executed read-only on 2026-11-26 and passed within its tested join paths: six candidate keys were unique, the registered cohort retained 32,593 rows, and all 10,655,280 student_vle rows matched one reference per tested domain.
8. Execute remaining P3 diagnostics from Notebook 11 in evidence-led order, one high-cost scan at a time. The notebook invokes the guarded runner, retains outputs and manifests, and reviews exports. Do not overwrite Notebook 10 or duplicate canonical SQL inside Notebook 11.
9. Freeze transformation rules only after source documentation, linked records, row/key impact, metric sensitivity, and alternative explanations have been reviewed.

No source CSV upload, recopy, or additional full snapshot is required. The 2026-11-26 database creation, source import, P3.00, and P3.07 are completed and evidenced. P3.01–P3.06 have retained read-only outputs; the current-SQL manifest status of P3.02/P3.05 remains a specific review gate.

## 3. Transformation register

Every operation receives a stable rule ID and records:
- source relation/file and source grain;
- target dataset and target grain;
- exact rule, SQL, and version;
- rows, keys, and categories affected;
- reason and evidence;
- before/after row counts and key counts;
- denominator and metric changes;
- alternative scenario and sensitivity result;
- approval status and rollback/rebuild procedure.

Allowed transformation classes are: classification, normalization, derived feature, scoped exclusion, aggregation, and sensitivity scenario. A rule must not be described as a correction unless source evidence supports that claim.

## 4. Work packages

### P3.01 — Repeated activity source-row semantics

**Problem:** Historical AN8.30 already quantified 1,614,505 repeated five-key groups and the R0/R1/R2 impact: R1 reduced rows by 7.39% and clicks by 3.19%; R2 reduced rows by 20.61% and clicks by 13.14%.

**Questions:** What original source values occur inside representative repeated five-key groups with conflicting click values? Do selected groups contain NULL, blank, or unexpected click tokens?

**Design:** Reuse the saved AN8.30 scenario totals and sensitivity outputs; do not recompute R0/R1/R2. P3.01 adds only a bounded sample of original rows from the largest conflicting groups, with group-level value counts and numeric ranges.

**Acceptance:** Selected source-row samples preserve original values; historical R0/R1/R2 evidence is referenced rather than rerun; no scenario is selected without source-semantic evidence.

### P3.02 — Temporal semantics and pre-course activity

**Problem:** 688,988 activity rows (6.47%) and 2,147,947 clicks (5.42%) are pre-course; course-window measures must not mix them.

**Questions:**
- Are negative relative dates valid pre-course access, source timing conventions, or anomalies?
- Do they concentrate in particular module-presentations/resources/students?
- Does resource breadth or active-day presence change under course-relative versus registration-relative windows?
- Are there post-registration observations beyond a recorded unregistration date, and what is their meaning?

**Design:** retain original relative day; classify PRE_COURSE, IN_COURSE, POST_COURSE, and UNKNOWN_COURSE_WINDOW; build separate course-relative and registration-relative features. Do not delete negative dates or truncate activity at unregistration.

**Acceptance:** preserve source offsets; report pre-start, day-zero, in-presentation, day-L boundary, and after-boundary states separately; do not infer calendar dates without a verified presentation start-date anchor. P3.02 retained output reports 688,988 negative VLE rows, 76,643 day-zero rows, 9,889,649 positive rows, and a maximum VLE offset equal to presentation length in all 22 presentations.

### P3.03 — Registration missingness and exposure

**Problem:** 45 student-presentations lack date_registration, making registration-relative exposure unknown.

**Questions:** where are the 45 records concentrated by presentation, outcome, and profile? Do they have recorded activity? How sensitive are exposure-adjusted rates to explicitly bounded alternatives?

**Design:** preserve NULL; classify UNKNOWN_EXPOSURE; compare a complete-case rate with clearly labelled sensitivity bounds only if a defensible bound exists. Do not impute day zero or average registration date.

**Acceptance:** 32,593 cohort keys reconcile; 45 unknown records remain visible; rate denominator includes known positive exposure only and reports excluded counts.

### P3.04 — Zero-recorded-activity cohort

**Problem:** 3,365 student-presentations have no recorded VLE activity row, while 4,093 have no recorded in-course VLE activity. Their difference of 728 is not yet a confirmed learner segment.

**Questions:** Which of the 728 records have pre-course-only activity, and which have post-course, mixed, or unclassified temporal activity? Do no-row and outside-window states vary by presentation, outcome, or registration-date missingness?

**Design:** Aggregate student_vle once to the registered student-presentation grain and return the complete 32,593-key cohort with mutually exclusive activity state and row counts. Derive presentation/outcome summaries in Notebook 11 from this single result set.

**Acceptance:** The complete registered key set remains intact; no-row, in-course, and outside-window states reconcile exactly; no VLE state is interpreted as absence of learning.

### P3.05 — Assessment opportunity and score semantics

**Problem:** 173 NULL scores, 329 observed zeros, banked records, no-submission opportunities, and mixed states can be confused.

**Questions:** are (id_assessment, id_student) keys unique in the submitted table? How do banked rows and date_submitted=-1 affect participation? Which assessment opportunities have missing due dates but observed submissions? Can score availability be established from the dataset?

**Design:** construct an assessment-opportunity dataset at (code_module, code_presentation, id_assessment, id_student), with separate submission, score-state, banked, due-date, and timing fields. Keep NULL, zero, no submission, and mixed states distinct. Do not infer score/feedback availability from due dates.

**Acceptance:** opportunity keys and join cardinality validated; opportunity denominators reconciled; no score imputation; missing score, observed zero, no submission, banked state, and -1 submission day remain distinct. P3.05 retained four result sets show 1,927 row-level -1 records and 1,927 grouped -1 records (agreement), zero duplicate assessment-student keys, and 11 missing-due-date assessments. The revised fifth source-grain reconciliation must also be retained and reviewed before any sentinel decision.

### P3.06 — Profile completeness, domains, and small-cell safeguards

**Problem:** profile percentages are within segment and presentation; missing categories and small cells may distort interpretation or disclose sensitive subgroup information.

**Questions:** which dimensions have missing values, inconsistent categories, or sparse cells? Are category labels stable across presentations? How much do repeated people contribute across module-presentations?

**Design:** audit missingness/domain by dimension and presentation; retain explicit missing category; quantify cell sizes; define suppression rules before publication; use presentation-aware comparisons and account for repeated people in inferential analysis.

**Acceptance:** documented category dictionary, missingness register, minimum-cell policy, and no causal/fairness claim from descriptive segments.

### P3.07 — Cross-domain analytical dataset and metric contracts

**Purpose:** assemble purpose-specific, grain-controlled datasets only after P3.01–P3.06. Reuse AN8.30 for the known non-unique student_vle five-key result; P3.07 does not repeat that full grouping.

**Candidate outputs:**
- student-presentation engagement fact;
- temporal activity scenario fact;
- assessment-opportunity fact;
- student-presentation outcome/context dimension;
- module-presentation dimension.

Each metric contract must define question, grain, population, numerator, denominator, time basis, zero/NULL treatment, scenario, known exclusions, sensitivity, refresh lineage, and permitted interpretation.

**Acceptance:** one-to-one or many-to-one join contracts are demonstrated; no unexplained row multiplication; independent SQL reconciliation passes; all transformations are reproducible.

### P3.08 — Source-faithful educational indicator baseline

**Purpose:** Provide a consistent source-faithful baseline for later comparison with validated derived representations and reporting contracts.

**Reuse gate:** First review retained AN8.35/AN8.36 outputs. Execute P3.08 only if those saved outputs do not contain the required measures at the required grain, denominator, and time basis. Do not repeat an existing extract merely to create another copy.

**Design:** If required, aggregate source activity and assessment states to student-presentation grain, then report by module-presentation and retrospective outcome. Keep all-source and in-course measures, assessment submission records, NULL/zero/nonzero scores, and unresolved -1 submission days distinct.

**Acceptance:** No join fan-out; complete registered denominator; exact lineage and metric definitions; retrospective outcomes remain descriptive group labels, never early predictors.

## 5. Order and stop/go controls

| Order | Package | Dependency | Stop condition |
|---|---|---|---|
| 1 | P3.00 source/import reconciliation | Successful seven-table import | Any missing/extra relation, column mismatch, or row-count mismatch |
| 2 | P3.07 grain and join gate | P3.00 passed | Duplicate or unmatched keys create unexplained fan-out |
| 3 | P3.01 repeated activity source-row samples | P3.00/P3.07 reviewed; AN8.30 sensitivity evidence reused | Source rows cannot support a defensible interpretation of conflicting groups |
| 4 | P3.02 temporal semantics | Key gate passed | Temporal partitions or source boundaries do not reconcile |
| 5 | P3.03 registration missingness/exposure | P3.07 and temporal definitions | Unknown registration is imputed or cohort grain changes |
| 6 | P3.04 zero-activity cohort | P3.02 and P3.07 | The full registered cohort does not reconcile; 728 difference remains unexplained |
| 7 | P3.05 assessment semantics | P3.07 and AN8.12/AN8.35 evidence | Assessment key fan-out or -1 semantics remain misrepresented |
| 8 | P3.06 source domains | P3.00 and P3.07 | Observed categories/tokens are silently normalized |
| 9 | P3.08 source-faithful indicator baseline (conditional) | Review AN8.35/AN8.36 first; run only if required measures are missing | Baseline changes grain, cohort, time basis, or score/activity states |

The order intentionally places P3.07 before cross-domain diagnostics. Its activity-reference reconciliation is a high-volume scan and must run alone. P3.01, P3.02, P3.03, P3.04, P3.06, and P3.08 also include high-cost activity scans; never run them concurrently.

## 6. Deliverables

- Evidence-reviewed P3.00–P3.08 query outputs with execution IDs, runtimes, row counts, and interpretations.
- A versioned semantic/transform decision register with source lineage and explicit approval state.
- A new Python notebook, notebooks/11_an8_part3_semantic_analysis.ipynb, preserving Notebook 10 as the Part 2 record.
- Purpose-specific derived datasets and export manifests, with no raw data committed.
- Before/after reconciliation of rows, keys, missingness, denominators, and metric impact for every accepted transformation.
- Updated data dictionary, analysis log, progress ledger, and Part 3 findings report.
- Approved metric contracts and reporting-source specification for AN9 Power BI.
- Power BI readiness gate based on validated reporting outputs.

## 7. Explicit non-goals

- No edits/deletes in original files or RAW/STAGING.
- No blanket deduplication, imputation, or outlier deletion.
- No assumption that R1/R2 is the correct source representation.
- No index, persistent view/table, or mart DDL without a separate approved change.
- No Power BI dashboard on unapproved metrics.
- No prediction, model training, or ML feature-selection phase during AN8 Part 3.
- No causal, demographic-fairness, or intervention claim based only on descriptive group differences.
- No calendar-date conversion without an exact authoritative presentation start-date anchor.

## 8. Exit criteria

Part 3 closes when:
1. Source import and P3.00 reconciliation pass.
2. Key/grain/join checks are reviewed and unexplained fan-out is resolved or explicitly bounded.
3. Every accepted semantic rule has source evidence, a stable rule ID, preserved raw value, affected rows/keys, before/after impact, sensitivity alternatives, and reproducible implementation.
4. Purpose-specific datasets reconcile to their declared grains and populations.
5. Metric contracts define question, grain, cohort, numerator, denominator, time basis, missing/zero handling, scenario, lineage, and limitations.
6. The source-faithful and validated representations can be compared without changing cohort or definitions unintentionally.
7. Reporting outputs are approved as the source for AN9 Power BI.

Only after these conditions can AN8 close and Power BI proceed. The separate Data Science / Machine Learning phase begins after Power BI; it is not part of this Part 3 workstream.

## 9. Source semantics and representation-first cleaning

### 9.1 Governing rule

The objective is to understand and represent each source field correctly, not to force values into familiar shapes. Source files in `data/raw/` and the PostgreSQL RAW/STAGING layers remain unchanged. All changes occur in a separately versioned working copy and, after approval, in derived relations in the isolated `oulad_an8_work` database.

For every candidate field, the workflow is:

1. Read the official OULAD data descriptor and record the exact source definition.
2. Inspect actual values, frequencies, NULL/sentinel tokens, boundaries, and representative rows, including linked records.
3. Compare source documentation with observed data and identify unresolved contradictions.
4. Propose a semantic representation and typed derived columns without overwriting the source value.
5. Reconcile row counts, keys, value distributions, and downstream metric effects.
6. Record the decision and alternatives in the transformation register; approve before applying it to the working dataset.

A value is not an error merely because it is negative, zero, unusually large, or non-calendar-shaped.

### 9.2 Relative-day semantics — confirmed source definition

The OULAD data descriptor (Kuzilek, Hlosta & Zdrahal, 2017; Scientific Data 4, 170171, DOI: 10.1038/sdata.2017.171) defines course-related date fields as day offsets from the start of a module-presentation. Day 0 is the presentation start. The descriptor identifies presentation labels such as 2013J as October 2013, but a year/month label alone is not an exact calendar-day anchor.

Relevant source fields include:

- `student_vle.date`: day of VLE interaction relative to presentation start.
- `student_registration.date_registration`: registration day relative to presentation start; negative values mean registration before day 0.
- `student_registration.date_unregistration`: unregistration day relative to presentation start; NULL indicates no recorded unregistration in the source.
- `assessments.date`: assessment due/submission-deadline day relative to presentation start.
- `student_assessment.date_submitted`: submission day relative to presentation start.

Official source: https://doi.org/10.1038/sdata.2017.171  
Dataset landing page: https://research.stem.open.ac.uk/ouanalyse/dataset/

Negative values in these documented relative-day fields are valid temporal offsets unless row-level evidence establishes a separate anomaly. They must not be sign-flipped, deleted, clipped to zero, or converted to absolute values.

### 9.3 Temporal representation and calendar-date conversion

For each module-presentation, retain the integer source offset and derive:

- `relative_day`: exact source day offset.
- `temporal_phase`: PRE_COURSE (day < 0), COURSE_START (day = 0), IN_COURSE (day > 0 and within the validated course boundary), POST_COURSE (after the validated course boundary), or UNKNOWN_BOUNDARY.
- `calendar_date`: presentation start calendar date plus the relative-day offset, only when an exact, authoritative presentation start date is obtained.
- `days_from_registration`: event relative day minus registration relative day, only when registration date is known.
- `days_to_unregistration`: unregistration relative day minus event relative day, only when an unregistration date exists.
- `days_to_course_end`: validated course end relative day minus event relative day, only when the course-end convention is established.

Do not infer an exact start day from the presentation code alone. The calendar-date field remains NULL with an explicit reason/state until an authoritative date anchor is established. Course length in `courses.module_presentation_length` must be checked against the source definition before deciding whether the final included day is L or L-1; the existing AN5 operational window 0 through L inclusive must be treated as an established analysis convention, not silently re-described as the official calendar convention.

### 9.4 Sentinel and missing-value investigation

`student_assessment.date_submitted=-1` is an unresolved candidate sentinel. The general relative-day definition does not prove whether -1 is a real pre-course submission day or a special state. Inspect all -1 rows alongside `is_banked`, `score`, assessment type, due date, student, presentation, and other submission rows. Compare the result with the source paper and source CSV documentation. Until resolved, preserve the integer and add a separate semantic status such as `SUBMISSION_DAY_MINUS_ONE_UNRESOLVED`; do not rewrite it as NULL or day 1.

Apply the same source-led process to every field, not only dates. Audit source tokens such as `?`, empty strings, whitespace, categorical variants, booleans encoded as Y/N or 0/1, numeric text, percentages, week boundaries, and identifiers. Preserve original values and introduce typed/canonical fields only when their domains and semantics are verified.

### 9.5 Candidate field inventory

The initial profiling scope covers all seven source files:

| Source file | Candidate fields / questions |
|---|---|
| `courses.csv` | module/presentation codes; `module_presentation_length` integer semantics and course-end boundary |
| `assessments.csv` | `date` relative-day semantics and missing values; `weight` numeric percentage and assessment-type rules |
| `studentInfo.csv` | category domains and labels; age/education/region/disability/IMD missingness; attempts and studied credits numeric ranges; retrospective outcome semantics |
| `studentRegistration.csv` | both relative-day fields; empty unregistration state; negative/positive ranges; registration/unregistration ordering |
| `studentAssessment.csv` | `date_submitted=-1`; `is_banked` domain and transfer meaning; score NULL/zero/range; repeated assessment-student key checks |
| `vle.csv` | activity-type domain; `week_from`/`week_to` missingness, range, overlap, and relationship to course length |
| `studentVle.csv` | negative/zero/positive relative days; repeated five-key groups; `sum_click` distribution and extreme values; site/presentation consistency |

This is an investigation inventory, not a declaration that all listed fields require modification. Some source columns may already be correctly typed in STAGING; Part 3 determines which additional semantic fields are valuable for reporting or machine-learning feature construction.

## 10. Data workspace, snapshots, and isolated database

### 10.1 File layout

- `data/raw/`: immutable acquired source files; never edit in place.
- `data/Backup/raw/`: verified recovery copy of the original source files.
- `data/working/raw/`: active mutable working copy used for controlled cleaning experiments.
- `data/Backup/working/<snapshot_id>/raw/`: frozen snapshots of the working copy at named checkpoints.

**Owner-approved operating decision (2026-11-22):** PowerShell SHA-256 verification confirmed that all eight files in `data/raw/`, `data/Backup/raw/`, and `data/working/raw/` are identical. All eight backup-manifest checks passed, including the manifest-to-source hash comparison. `data/working/raw/` is the sole operational file input for Part 3. The original and backup folders remain read-only. `oulad_dataset.zip` is intentionally retained in all three folders; the Part 3 source import uses the seven CSV files only. No copy is to be deleted and no additional full snapshot is to be created at this stage.

The working copy is not a replacement for RAW and must never be treated as the source-of-record. No raw CSV is committed to Git.

### 10.2 Snapshot protocol

A snapshot ID is a human-chosen immutable label, not a PowerShell feature. PowerShell is simply one way to create the folder, copy files, and generate/verify a manifest. A snapshot may duplicate the full working CSV set and therefore consume substantial disk space.

Before creating the first snapshot, inspect the existing backup and working folders, measure their sizes, and decide whether a full copy is justified. Do not copy only selected CSVs into a folder named as though it were a complete snapshot. If storage cost is unacceptable, retain the verified original backup and use versioned transformation outputs plus manifests until a full checkpoint is approved.

At each approved full-snapshot checkpoint:

1. Stop transformations and close applications writing to the working files.
2. Choose a descriptive immutable snapshot ID, for example `2026-11-22_p3-baseline-v1` or `2026-11-22_p3-after-temporal-rules-v1`.
3. Copy the entire `data/working/raw/` directory to `data/Backup/working/<snapshot_id>/raw/`.
4. Generate a manifest containing relative path, file size in bytes, SHA-256, row count, and column count for each CSV. Record the tool/version and timestamp.
5. Verify source and snapshot file counts, sizes, and SHA-256 hashes match exactly.
6. Never modify an existing snapshot. Create a new ID for every subsequent full checkpoint.

Do not use a mutable folder named only `latest` as the sole backup.

### 10.3 Isolated PostgreSQL work database

The proposed database name is `oulad_an8_work`, separate from `oulad_analytics`. It has not been created. Its proposed schemas are:

- `source_ref`: source-faithful imported working-copy tables.
- `working`: typed/normalized representations with original source fields retained.
- `audit`: transformation register, row/key impact, and validation results.
- `derived`: purpose-specific analytical outputs and feature-ready tables.

The owner has separately approved proceeding with creation of this isolated work database and a source-faithful import from `data/working/raw/`. This approval does not authorize any modification to `oulad_analytics`, RAW, QUALITY, or STAGING, nor any index, cleaning transformation, or derived persistent object. The source database remains read-only.

## 11. Educational reporting and AN9 design proposal

AN9 should compare three clearly labelled analytical perspectives, not imply that a cleaned copy is automatically more truthful:

- **AN9-A — Source-faithful baseline:** measures computed from the original, unmodified source representation, with documented source semantics and known limitations.
- **AN9-B — Validated working representation:** the same questions and metric definitions computed from approved, versioned derived fields in the working dataset.
- **AN9-C — Educational impact comparison:** shows which learner-facing conclusions change, remain stable, or become more interpretable after each justified transformation.

For every comparison, hold cohort, grain, denominator, presentation scope, time window, and metric definition constant. If any of these changes, disclose it as a separate comparison rather than attributing the difference to cleaning.

The dashboards should prioritize educational questions: platform access and recorded participation, course persistence and withdrawal, assessment participation and score states, outcome distribution, pre-course access, resource use, and variation between module-presentations. Technical row/key reconciliation belongs in a methodology appendix, not as the main stakeholder narrative.

The dashboard must not equate VLE activity with learning, interpret missing activity as non-study, present retrospective outcomes as early-warning predictions, or claim that cleaning caused better student outcomes. No dashboard implementation begins until Part 3 metric contracts and the reporting-source design are approved.

## 12. Part 3 query and execution plan

The P3.00–P3.08 files are prepared SELECT-only diagnostics on feat/an8-part3-semantic-cleaning. They have not been executed. The target is oulad_an8_work.source_ref, containing the seven source CSVs with original column names and TEXT values.

| Query | File | Investigation / output |
|---|---|---|
| P3.00 | sql/05_part3/P3.00_source_inventory_and_profile.sql | Column inventory, exact row counts, and source_ref relation inventory |
| P3.01 | sql/05_part3/P3.01_student_vle_repeated_event_semantics.sql | Bounded representative raw rows from the largest conflicting five-key groups; reuse AN8.30 for R0/R1/R2 sensitivity |
| P3.02 | sql/05_part3/P3.02_relative_day_semantics.sql | Relative-day sign/range distributions, source boundaries, and representative rows |
| P3.03 | sql/05_part3/P3.03_registration_missingness_and_exposure.sql | Unknown-registration records linked to outcome/profile and activity context |
| P3.04 | sql/05_part3/P3.04_zero_activity_cohort_semantics.sql | One row per registered student-presentation with activity counts and mutually exclusive temporal state; derive grouped reconciliation in Notebook 11 |
| P3.05 | sql/05_part3/P3.05_assessment_sentinel_and_score_semantics.sql | -1 submission context, banked/score states, candidate-key duplicates, missing due-date links |
| P3.06 | sql/05_part3/P3.06_categorical_and_numeric_domain_audit.sql | Observed categorical tokens and numeric ranges, including VLE date and click fields |
| P3.07 | sql/05_part3/P3.07_cross_domain_grain_and_join_validation.sql | Candidate-key duplicates, registration/profile key-set reconciliation, activity reference-match cardinality |
| P3.08 | sql/05_part3/P3.08_educational_indicator_baseline.sql | Source-faithful educational baseline by presentation and retrospective outcome |

All query files must carry Question, Expectation, Grain, Source, Safety, Runtime, and Read as headers. P3.00 is the import gate; P3.07 is the grain/join gate. Neither a prepared SQL file nor a dry-run is evidence of database query execution.

The importer dry-run was executed successfully by the owner on 2026-11-24 using the project virtual environment. All seven working CSVs passed SHA-256 and column-set validation. It made no PostgreSQL connection and changed no database.

The 2026-11-24 database preflight also verified:
- G: drive free space: 67.51 GB.
- PostgreSQL 18.6; current role postgres; CREATEDB=true.
- oulad_analytics exists (1269 MB).
- oulad_an8_work does not exist.

**Next local execution sequence:** create oulad_an8_work from a maintenance connection; create the four approved schemas and seven empty source_ref tables; run the guarded importer; execute P3.00 once; review its complete result sets; execute P3.07 as the key/join gate. Do not rerun the successful importer dry-run unless its inputs or code change.

## 13. AN8/Part 3 closure and branch integration gates

Part 2 has been merged into `main` through PR #27 (merge commit `0697d0694d44cc543a1fa725414bd5e2dc1ab7b9`). The dedicated Part 3 branch `feat/an8-part3-semantic-cleaning` was created from that merge commit. The P3.00–P3.08 SQL diagnostic files are prepared on this branch but remain unexecuted.


## 12. Latest Part 3 execution review — 2026-11-26

P3.00 and P3.07 passed their read-only structural gates. P3.01–P3.06 were executed in the isolated work database; their outputs are retained in Notebook 11. P3.02 reports 688,988 pre-start VLE rows (6.466%), 76,643 day-zero rows (0.719%), and 9,889,649 positive rows (92.815%). All 22 module-presentations have a maximum VLE relative day equal to the recorded presentation length. This is a boundary observation, not evidence that the last day is an error.

P3.05's retained export contains four result sets. The direct row-level and grouped outputs both count 1,927 `date_submitted = -1` records; therefore, the earlier wording that described a numerical discrepancy was incorrect and is superseded. The revised SQL adds a fifth source-grain reconciliation result set, which is not present in the retained four-set export. The semantic meaning of -1 remains unresolved. No recoding is approved.

A notebook review found and corrected a duplicate loader definition that bypassed SQL-hash validation. P3.02/P3.05 outputs and dependent review-cell outputs were cleared after this correction. Their exports must be reloaded only through the hash-aware function; a stale manifest must remain explicitly historical. No source data, original database layers, or persistent derived objects were modified.

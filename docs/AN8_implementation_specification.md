# AN8 — Validated Metrics and Curated Reporting Tables

**Status: initial extraction executed locally; AN8.30–AN8.36 prepared but not executed.** Owner-saved Notebook 10 outputs document AN0.01, AN8.01–AN8.04, AN8.10–AN8.12, and AN8.20. No production metric or KPI is approved.

## 0. Current evidence and approved scope extension

The initial owner-executed batch validated the student-presentation key and denominator (32,593 rows), returned the retrospective outcome distribution, profiled 22 presentations and 206 assessments, identified 45 missing registration dates and 11 missing assessment due dates, and reconciled the 10,655,280-row R0 activity source to 39,605,099 recorded clicks. All 10,655,280 activity rows matched the registered cohort; 9,966,292 were in-course and 688,988 pre-course. These are extraction and descriptive-context results, not approval of production KPIs.

The initial scope did not deliver full metric distributions, current R0/R1/R2 impact, exposure distributions, outcome-stratified activity profiles, or assessment opportunity coverage. The owner approved the AN8.30–AN8.36 extension. Those SQL files and Notebook 10 cells are prepared but unexecuted. See `reports/AN8_initial_results_and_scope_extension.md` for the detailed evidence and rationale.

**Cleaning decision:** preserve the original files and RAW evidence; build purpose-specific, versioned derived datasets for justified analytical cleaning. Every exclusion, normalization, deduplication scenario, or outlier treatment must have a documented rule, reason, affected rows/keys, before/after counts, metric impact, sensitivity alternative, and approval state. Do not apply blanket deletion or assume that R1/R2 is ground truth. The owner's external copy of the local `data` directory is planned but not yet verified.

## 1. Purpose and analytical grain

AN8 defines and validates descriptive, business-facing measures before Power BI. The primary analytical grain is one registered student-presentation: `(code_module, code_presentation, id_student)`. Typed STAGING remains the source of truth. `student_vle` is preserved as R0 source activity; repeated source rows are not blindly deduplicated.

The work must validate source presence, key completeness/uniqueness, join cardinality, denominators, missingness, temporal windows, and row-level reconciliation before any measure is approved.

## 2. Execution-to-reporting architecture

The project owner has adopted a deliberate separation between expensive source extraction and visualization:

1. Execute each canonical source query once, under read-only controls and explicit gates.
2. Retain every complete result set as a local CSV plus a non-sensitive execution manifest under `outputs/an8/extracts/`.
3. Reconcile the retained extracts against AN5/AN6/AN7 evidence and the AN8 cohort contract.
4. After review and explicit owner approval, load the retained extracts into curated PostgreSQL reporting tables.
5. Build subsequent Python visuals, report tables, and Power BI datasets from the curated reporting tables or retained exports — not by rerunning expensive source queries for each visualization.

This architecture is intentional: visualization code must be independent of SQL execution. A chart refresh must not trigger a new full scan of `staging.student_vle`.

The curated reporting tables are a planned deliverable, not an existing database state. Their DDL, load method, refresh policy, and permissions require a separate reviewed work order and explicit approval. The current read-only runner does not create tables, views, materialized views, indexes, or schemas.

### 2.1 Controlled programmatic write path — design decision

Database deployment will be performed programmatically through Python/Psycopg; pgAdmin is an optional administration interface, not a project runtime dependency. The existing `src.analytics.db.connect_read_only()` and `run_query()` remain strictly read-only and are not extended with a write flag or general-purpose writable connection.

After the retained extracts have passed review and the owner has approved a versioned mart contract, a separate deployment component will provide a narrowly scoped write path. Its design requirements are:

- use a dedicated deployment connection factory and a separately configured least-privilege database role; do not reuse the extraction connection or credentials by silently changing transaction mode;
- allow only an explicit deployment manifest and approved DDL/load operations against the approved reporting schema and object allowlist; reject arbitrary SQL and all RAW, QUALITY, and STAGING targets;
- validate the extract manifest, query-file SHA-256, expected columns, data types, row counts, key uniqueness, and non-NULL business keys before opening the deployment transaction;
- load only retained CSV extracts; never rescan `staging.student_vle` to populate reporting tables;
- use explicit transactions, fail closed on validation or constraint errors, roll back the complete deployment unit on failure, and record a deployment manifest without credentials;
- verify post-load row counts, keys, constraints, and extract-to-table reconciliation before marking deployment successful;
- define replacement/refresh behavior, backup/rollback expectations, ownership, grants, and schema isolation in the approved mart contract before implementation.

This is an architectural design decision only. No writable connection, deployment module, DDL, table creation, grant, or data load is implemented or authorized in the current extraction work.

## 3. Canonical query inventory and execution policy

| Query | Purpose | Execution status |
|---|---|---|
| AN8.01 | Catalog-only STAGING relation inventory | Prepared; not executed |
| AN8.02 | Composite-key uniqueness, NULL-key, and bidirectional key-set gate | Prepared; not executed |
| AN8.03 | Retrospective outcome denominator profile | Prepared; gated by AN8.02 |
| AN8.04 | Course and assessment context; two result sets | Prepared; not executed |
| AN8.10–AN8.12 | Registration timing, withdrawal-date reconciliation, score missingness | Prepared; not executed |
| AN8.20 | Consolidated one-pass student-presentation activity extract | Prepared; one high-cost scan |
| AN8.21–AN8.23 | Earlier separate temporal/activity/rate/breadth scans | Retired; measures consolidated into AN8.20 |
| AN8.30–AN8.32 | Additional reporting extracts | Deferred pending the curated-table contract |
| AN8.33 | Candidate measure register | Prepared; not executed |
| AN8.40–AN8.41 | Mart readiness and validation-contract SELECTs | Prepared; no DDL |

AN8.01 uses PostgreSQL catalog statistics and does not run an exact `COUNT(*)` across `student_vle`. Estimated rows are not exact counts.

AN8.02 is a hard execution gate. It blocks downstream work if either source has duplicate composite-key groups, NULL key components, source rows that do not equal distinct key counts, or non-zero key-set differences.

AN8.04 returns two result sets. The runner checks truncation for each result set independently and enforces a course-context gate: course keys must be non-NULL and unique, course lengths must be present, and the assessment-context key set must match the course key set. AN8.20 is blocked until this gate passes.

AN8.20 consolidates the previous activity metrics into one scan. It returns one row per registered student-presentation and repeated source-level reconciliation totals that expose unmatched activity. The result includes:
- all observed R0 activity rows and recorded clicks;
- pre-course, in-course, and post-course activity-row/click partitions;
- in-course active days and resource breadth;
- post-registration active days, resource breadth, exposure days, and active-day rate;
- an explicit recorded-activity indicator.

Post-registration exposure begins at `GREATEST(date_registration, 0)` and ends at the course end. The numerator counts distinct activity dates within that same interval. Missing registration dates yield NULL post-registration metrics. No activity is truncated at unregistration. Course-relative and registration-relative measures remain distinct.

AN8.21–AN8.23 are retained as retired audit markers and must not be executed; their intended measures are columns in AN8.20. AN8.20 is the only high-cost activity scan in the current design.

## 4. Measure interpretation and approval

Candidate descriptive measures include recorded activity rows, recorded clicks, in-course active days, post-registration active-day rate, and resource breadth. Clicks and activity rows describe platform events, not learning quality. Resource breadth is not exposure-normalized and remains secondary. No weighted composite, KPI threshold, student ranking, intervention rule, or predictive feature is approved.

Historical AN5 any-window coverage and AN6 in-course coverage remain different definitions and must not be combined. AN7 associations remain observational and do not establish causal or predictive effects.

## 5. Runner and safety contract

`scripts/run_an8.py`:
- requires AN0.01 database identity and read-only preflight;
- requires AN8.02 to pass before AN8.03 and downstream activity extracts;
- checks all returned result sets for expected count and truncation;
- validates the AN8.02 key grain and stores the observed registration denominator;
- validates AN8.20 row count, non-NULL composite key, and key uniqueness against that denominator;
- runs at most one high-cost query per invocation;
- reports PostgreSQL diagnostics and never retries automatically;
- exports reviewed DataFrames to CSV and a non-sensitive manifest without reconnecting to PostgreSQL.

The first local execution sequence, after synchronization and file confirmation, is AN0.01 → AN8.01 → AN8.02 → AN8.03. AN8.20 must be a later standalone execution after reviewing all lightweight results.

## 6. Curated reporting tables — separate approval gate

The intended persistent reporting layer will contain only the validated, documented outputs needed for reporting. A proposed logical design is:
- a student-presentation activity fact loaded from the retained AN8.20 extract;
- a student-presentation outcome/context fact or dimension sourced from validated registration/profile extracts;
- a module-presentation dimension;
- an assessment-context dimension.

Exact table names, schema, key constraints, data types, load strategy, replacement/refresh policy, lineage fields, and access rules are not yet approved. A separate DDL/load specification must be reviewed before any persistent database change. The load must use the already retained extracts and must not repeat the expensive source scan merely to populate chart inputs. The future deployment path is a separate, least-privilege Python/Psycopg component as specified in Section 2.1; the read-only extraction path remains unchanged.

## 7. Open decisions and limitations

No decision is made on table replacement strategy, schema naming, index creation, withdrawal-derived cohort rules, small-cell suppression threshold, K6 denominator, Power BI dimensions, or weighted score. The programmatic deployment approach is decided; its concrete role, object allowlist, DDL, transaction, rollback, and refresh implementation remain deferred until the mart contract is approved. No index on `staging.student_vle` is proposed.

The project must not infer score/feedback availability from assessment due dates. NULL, zero, unknown exposure, no recorded activity, and non-estimable rates remain distinct.

## 8. Exit criteria

AN8 can close only after:
1. local branch synchronization and exact-file confirmation;
2. successful read-only preflight and key-grain gates;
3. complete SQL result sets and reviewed extracts;
4. independent denominator, time-window, join, and row-count reconciliation;
5. explicit metric definitions and limitations;
6. owner-approved curated-table design and deployment;
7. validation of loaded tables against retained CSV manifests;
8. documented visualization source contract proving that plots use curated tables/retained extracts rather than rerunning source scans.

Until then AN8 remains preparation only; AN9 Power BI cannot use unapproved candidate measures.

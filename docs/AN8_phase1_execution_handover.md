# AN8 Phase 1 — Corrected Preparation and Execution Handover

**Status: PREPARATION ONLY. AN8 has not started.** No AN8 SQL has been executed against the owner's PostgreSQL database, no AN8 metrics have been validated, and no curated reporting tables have been created. The owner has not yet synchronized this branch locally or confirmed the local files to be used.

## Repository state

- Repository: `JALILOHUB/OULAD-EdTech-Learning-Analytics`
- Working branch: `feat/an8-preparation-review`
- Intended base: `main` at `44af2a2117e524b469e3cf8df9ee77e9f863f250`
- The branch remains isolated; do not merge it or open a PR unless requested.
- Do not assume the owner's Windows working tree contains these revisions. Local synchronization and file confirmation are pending.

## Why the architecture was revised

The owner explicitly requires expensive source queries to be executed once, with complete outputs retained and reused. Visualization code must be independent of source SQL. The intended flow is:

1. Execute read-only source queries once, with stop/go gates.
2. Save complete result sets as CSVs and a non-sensitive manifest under `outputs/an8/extracts/`.
3. Review and reconcile the retained outputs.
4. After separate design review and explicit approval, load the retained extracts into curated PostgreSQL reporting tables.
5. Build Python visuals, report tables, and Power BI datasets from the curated tables or retained exports. Never rerun a large source scan merely to regenerate a visualization.

The curated reporting tables are a planned deliverable, not an existing database state. No DDL or data load is included in this preparation branch. A separate deployment work order and explicit owner approval are required.

The adopted deployment architecture is direct programmatic Python/Psycopg execution, independent of pgAdmin. The read-only extraction connection in `src/analytics/db.py` must remain read-only. A future, separate least-privilege deployment connection/component will accept only an approved manifest, allowlisted reporting objects, and validated retained CSV extracts. It must use explicit transactions, rollback on failure, post-load reconciliation, and a non-sensitive deployment manifest. This is a design decision for AN8; implementation and all persistent database changes remain deferred until the mart contract is reviewed and approved.

## Static corrections included in this branch

- AN8.01 uses PostgreSQL catalogs and does not perform a full `COUNT(*)` scan of `student_vle`; the runner requires all seven expected STAGING relations to exist.
- AN8.02 checks duplicate composite keys, NULL key components, source row/distinct-key agreement, and bidirectional key-set differences. The Python runner enforces these checks as a hard gate.
- AN8.03 is blocked unless AN8.02 passes; category denominators and registration matches must reconcile to the validated cohort.
- AN8.04 expects two result sets and the runner checks truncation independently for every result set.
- AN8.20 consolidates all required activity-row/click partitions, active-day counts, resource breadth, registration exposure, and post-registration active-day rate into one high-cost source scan.
- AN8.21–AN8.23 are retired audit markers; do not execute them. Their measures are included in AN8.20.
- AN8.20 is blocked until AN8.03, AN8.04, and AN8.10–AN8.12 have completed their required gates. A local ignored sentinel prevents accidental repeat attempts of the high-cost scan; a failed attempt requires a separate review decision before clearing it.
- The runner validates the AN8.20 row count and composite-key uniqueness against the observed AN8.02 registration denominator. Export is blocked until the complete required query set and all execution gates pass. The non-sensitive manifest records query-file SHA-256 hashes, result-set filenames, row counts, and truncation state.
- Notebook 10 separates SQL execution, result review, local extract export, Python-only reconciliation, and visualization. Plotting cells must not reconnect to PostgreSQL or invoke SQL.
- `outputs/an8/` is ignored by Git.
- Notebook README now reconciles AN7's 24 saved visualizations (15 original plus nine sensitivity figures).

## First execution sequence — only after local synchronization and confirmation

1. AN0.01 — database identity and read-only preflight.
2. AN8.01 — catalog-only source relation inventory.
3. AN8.02 — mandatory student-presentation key and cohort gate.
4. AN8.03 — outcome denominator profile, only if AN8.02 passes.
5. Review AN8.04 and AN8.10–AN8.12.
6. Run AN8.20 once, alone, only after the preceding outputs are reviewed and the cohort gate remains valid.
7. Export complete outputs to `outputs/an8/extracts/`; reconcile the saved extracts.
8. Design curated tables from the retained extracts and request approval before DDL/load.

Do not run Notebook 10 with Run All. Do not start AN8.20 in the first batch. Do not execute AN8.21–AN8.23 or deferred AN8.30–AN8.32.

## Safety and decision boundaries

- PostgreSQL remains read-only during this preparation/extraction work.
- No changes to RAW, QUALITY, or STAGING.
- No deduplication or deletion of `student_vle` rows.
- No indexes, views, materialized views, tables, schemas, DDL, or persistent data loads without explicit approval.
- No production KPI, threshold, weighted score, ranking, predictive feature, causal claim, or intervention rule is approved.
- Keep NULL, zero, unknown exposure, no recorded activity, and non-estimable states distinct.
- Preserve the distinction between AN5 any-window coverage and AN6 in-course coverage.
- Do not infer score/feedback availability from assessment due dates.

## Open design decisions

Persisted table design, schema naming, DDL/load mechanism, refresh/replacement policy, access/retention controls, withdrawal-derived cohort rules, small-cell suppression threshold, K6 denominator, Power BI dimensions, and any weighted score remain open. No index on `staging.student_vle` is proposed.

## Execution evidence

No AN8 SQL execution, live database connection, parser validation, notebook execution, local Windows synchronization, metric revalidation, or curated-table deployment is claimed by this handover. These are pending work, not completed outcomes.

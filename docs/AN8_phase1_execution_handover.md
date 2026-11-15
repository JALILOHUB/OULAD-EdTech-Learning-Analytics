# AN8 Phase 1 — Preparation Handover

- Branch: feat/an8-preparation-review
- Base: main at 44af2a2117e524b469e3cf8df9ee77e9f863f250
- Prepared: canonical read-only SQL, runner, staged Notebook 10, implementation specification, review plan, and this handover.

First execution: run notebook preflight, then AN0.01 → AN8.01 → AN8.02 → AN8.03. Inspect full outputs, duplicate keys, key-set differences, row counts, and truncation. Do not run AN8.20 in the first batch.

High-cost IDs AN8.20–23 must run one per invocation. AN8.30–32 are deferred. AN8.40–41 are status/contract SELECTs, not DDL.

Not executed: SQL, database connection, refreshed counts, metric validation, SQL parser validation, notebook execution, plot generation, mart creation.

Safety: no DDL/DML, indexes, persistent objects, RAW/QUALITY/STAGING changes, source deduplication, credential changes, outputs/an8 ignore change, or requirements encoding change.
# AN8 Independent Review and Execution Plan

Prepared against main commit 44af2a2117e524b469e3cf8df9ee77e9f863f250, the operating handbook, AN5–AN7 handovers, and the independent review supplied during coordination.

The review identified a Notebook 09 / progress-ledger discrepancy: the ledger says nine sensitivity outputs were cleared and pending, while the notebook was reported to retain nine saved figures. Only two were visually checked. This branch does not alter Notebook 09 and does not claim all nine figures were regenerated or validated. Reconcile that discrepancy separately.

First batch: AN0.01 → AN8.01 → AN8.02 → AN8.03. Stop on failed database/read-only checks, unexpected duplicate-key groups, key-set differences, or unexplained count changes. A count difference is diagnostic, not proof of corruption. Do not run AN8.20 in this batch.

Then review AN8.04–05 and AN8.10–12. Run only one high-cost scan among AN8.20–23 per invocation. AN8.30–32 are deferred pending validated extract contracts.

No decision is made on persisted fact table versus views/materialized views, DDL mechanism, staging indexes, withdrawal-derived cohort, suppression threshold 10/20/30, K6 denominator, Power BI dimensions, or weighted score. No index on staging.student_vle is proposed.

Prepared artifacts only: no SQL execution, live database inspection, metric revalidation, or mart creation.
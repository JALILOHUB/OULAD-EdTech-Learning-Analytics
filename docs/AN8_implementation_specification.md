# AN8 Implementation Specification

AN8 establishes validated descriptive metrics before curated marts or Power BI. It creates no database objects.

The student-presentation grain is (code_module, code_presentation, id_student). Typed staging tables remain authoritative. student_vle is preserved as R0 source activity; repeated combinations are not blindly deduplicated.

Candidate measures are recorded clicks, activity-row count, active days, exposure-adjusted active-day rate, and distinct in-course resource breadth. Clicks/rows describe platform events, not learning quality. Resource breadth is not exposure-normalized. All remain NOT_APPROVED; no weighted composite or threshold is defined.

AN8.01–03 establish source/grain/denominator readiness; AN8.04–05 and AN8.10–12 describe dimensions, timing, and missingness; AN8.20–23 are high-cost scans; AN8.30–32 are deferred until a validated extract contract exists; AN8.33 is a proposal register; AN8.40–41 are readiness/validation SELECTs only.

The runner requires AN0.01, verifies database identity and read-only flags, applies bounded timeouts and row caps, blocks deferred IDs, and runs at most one high-cost query per invocation. No SQL was executed during preparation.

No view, materialized view, table, index, or DDL deployment workflow is included. A separate design and explicit approval are required after grain, join cardinality, denominators, missingness, time basis, refresh, and access are validated. src/analytics/db.py remains a read-only SELECT runner.

No live metric, production KPI, predictive feature, causal claim, or Power BI semantic model is approved.
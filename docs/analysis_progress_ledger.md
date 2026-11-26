# OULAD Analysis — Progress Ledger

## Current authoritative snapshot — 2026-11-26 (Part 3 diagnostic interpretation)

- **Roadmap:** AN8 Part 2 complete. Part 3 diagnostics executed; semantic review is active. Revised P3.02/P3.05 require individual re-execution. AN9 Power BI remains blocked pending approved semantic rules, metric contracts and curated outputs. ML remains a later separate phase.
- **Repository:** baseline `6b87ac20ff6dd98c2e978752c77c99342c290376` on `feat/an8-part3-semantic-cleaning`; interpretation work on `feat/an8-part3-diagnostic-interpretation`. No main merge.
- **Database:** `oulad_an8_work` source import is complete. P3.00 reconciled 43 TEXT columns and exact row counts. Do not recreate database, re-import, or modify `oulad_analytics`, RAW, QUALITY, STAGING or original files.
- **Executed read-only queries:** P3.00 19:07:19 UTC (2.884s); P3.07 19:10:19 (59.346s); P3.01 20:12:53 (251.628s; 430 rows/50 groups); P3.02 20:30:12 (130.256s; 5 field profiles, 200 rows, 22 presentation summaries; historical after SQL revision); P3.05 20:33:18 (2.782s; old result sets disagree: 1,927 vs 1,927); P3.03 20:59:53 (2.928s; 45 rows); P3.04 21:02:01 (69.492s; 32,593 cohort rows); P3.06 21:03:41 (256.949s; 65 category-token rows, 13 numeric profiles).
- **Reviewed findings:** P3.04: 28,500 in-course, 3,365 no VLE row, 728 pre-course-only; 4,093 combined no in-course. P3.02: 688,988 pre-start VLE rows (6.47%), 76,643 day 0 (0.72%), 9,889,649 positive (92.81%); maximum VLE offset equals length in all 22 presentations. Negative VLE offsets are pre-start, not errors.
- **Decisions:** R0 source-faithful; R1/R2 sensitivity only; no deduplication. Keep day 0 and day L separate. No calendar conversion. 45 registration exposures remain unknown. Keep no-row and pre-course-only separate. Do not recode `date_submitted=-1`; its semantic meaning remains unresolved even though retained counts reconcile. No imputation, blanket normalization, outlier deletion, persistent derived object or production KPI approved.
- **Candidate indicators only:** 87.44% in-course activity coverage; 10.32% no VLE row; 2.23% pre-course-only; 12.56% combined no in-course; 6.47% pre-start activity-row share. These describe platform records, not learning.
- **Prepared changes:** Notebook 11, P3.02/P3.05 SQL, analysis log and plan.
- **Next:** sync branch, restart kernel, run top-to-bottom with all authorization switches False, then execute revised P3.02 and P3.05 individually and reconcile all result sets.


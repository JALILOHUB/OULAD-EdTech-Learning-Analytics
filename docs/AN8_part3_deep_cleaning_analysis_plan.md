# Part 3 — Deep Data Cleaning and Analytical Validation Plan

**Status:** Source import complete. P3.00/P3.07 passed structural gates. P3.01, P3.03, P3.04 and P3.06 have retained read-only executions and reviewed interpretations. P3.02/P3.05 were executed, but canonical SQL has since been revised; old manifests are historical and require individual re-execution.

## Reviewed evidence

- P3.01: 430 original rows from 50 conflicting five-key groups. R0 remains source-faithful; R1/R2 sensitivity only. No deduplication rule.
- P3.02: 688,988 pre-start VLE rows (6.47%), 76,643 day-zero (0.72%), 9,889,649 positive (92.81%). Maximum VLE offset equals recorded presentation length in all 22 presentations. Negative offsets are not automatic errors. Revised query stratifies boundary examples.
- P3.03: 45 unknown registration dates; exposure unknown, not zero.
- P3.04: 32,593 registered student-presentations: 28,500 in-course, 3,365 no VLE row, 728 pre-course-only. The 728 difference is resolved.
- P3.05: old result sets disagree on -1 count (1,927 vs 1,356). Revised SQL adds source-grain reconciliation; no recoding approved.
- P3.06: 65 category-token combinations and 13 numeric profiles; inventory only.

## Candidate indicators (not production KPIs)

| Indicator | Numerator / denominator | Value |
|---|---|---:|
| In-course recorded activity coverage | 28,500 / 32,593 | 87.44% |
| No recorded VLE row | 3,365 / 32,593 | 10.32% |
| Pre-course-only | 728 / 32,593 | 2.23% |
| Combined no in-course | 4,093 / 32,593 | 12.56% |
| Pre-start activity-row share | 688,988 / 10,655,280 | 6.47% |

These describe platform records, not learning.

## Decisions and next gates

1. Preserve source VLE rows; no R1/R2 correction is approved.
2. Preserve negative relative days; flag day 0 and day L; no calendar conversion without verified start date.
3. Keep unknown registration exposure separate.
4. Keep missing score, zero score, no submission, banked state and -1 submission day distinct.
5. Re-execute revised P3.02 and P3.05 individually; verify SQL hashes and P3.05 count reconciliation.
6. Build only reversible purpose-specific derived outputs after semantic gates pass.
7. Validate metric contracts before AN9 Power BI. P3.08 remains conditional on AN8.35/AN8.36 reuse.

No production KPI, composite score, persistent derived object, Power BI, prediction or ML is approved.

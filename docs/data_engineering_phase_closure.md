# OULAD Data Engineering Phase Closure

**Project:** OULAD — EdTech Learning Analytics  
**Project Owner & Lead Analyst:** Abdeljalil El Khyati  
**Closure prepared:** 2026-10-15  
**Status:** Core implementation and validation completed; four review findings remain documented.

## 1. Purpose and scope

This phase established the source-to-database foundation for later learning analytics. Work covered source acquisition and profiling, RAW design and loading, data-quality checks and result recording, typed STAGING creation, and validation of the selected conversions. It did not include analytical model implementation, KPI calculation, dashboard findings, or predictive modelling.

## 2. Source tables and row counts

| Table | RAW rows | STAGING rows | Reconciled |
|---|---:|---:|---|
| `courses` | 22 | 22 | Yes |
| `assessments` | 206 | 206 | Yes |
| `student_info` | 32,593 | 32,593 | Yes |
| `student_registration` | 32,593 | 32,593 | Yes |
| `student_assessment` | 173,912 | 173,912 | Yes |
| `vle` | 6,364 | 6,364 | Yes |
| `student_vle` | 10,655,280 | 10,655,280 | Yes |

The row-count reconciliation confirms that the reported load and STAGING creation retained the expected number of rows. It is not a byte-for-byte comparison against each source file.

## 3. RAW implementation

Seven tables were created in schema `raw` and loaded from the source CSV files using PostgreSQL `COPY`. The selected RAW types reflect profiling results. Source `?` tokens remain as source values in the relevant nullable text columns. RAW has no business cleaning, deduplication, aggregation, or analytical transformation. Candidate keys for six tables passed the reported checks; `raw.student_vle` intentionally has no primary key.

## 4. Data quality registry

The latest registry summary is **29 records, 29 distinct test codes: 25 PASS and 4 REVIEW**, with no duplicate codes in the latest full-registry check. All 29 records have `executed_at IS NULL` because exact historical execution timestamps were not captured. Those timestamps must not be backfilled with invented times.

### The four REVIEW findings

| Test code | Evidence | Interpretation and decision |
|---|---|---|
| `B2.2_STUDENT_VLE_KEY` | 10,655,280 rows; 8,459,320 distinct five-column keys; 2,195,960 excess rows | Key uniqueness is not established. Do not delete or aggregate records based solely on this result. |
| `B5.2_CATEGORICAL_VALUES_REVIEW` | Categorical distributions were recorded. The follow-up domain query returned no out-of-domain rows for its listed values. | Retain REVIEW until the accepted-value reference is documented and the registry status is deliberately reconciled. No invalid categories were returned by that particular query. |
| `B5.3_STUDENT_VLE_RELATIVE_DAY` | 688,988 negative relative days; zero days beyond presentation length; observed range -25 to 269 | Preserve negative day values. Their meaning must be interpreted against source semantics; they are not automatically invalid. |
| `B5.3_SUBMISSION_VS_ASSESSMENT_DATE` | 49,318 after; 29,469 on; 92,260 before; 2,865 with unavailable assessment day | Diagnostic comparison only. Submission after a listed assessment day may reflect late submission or other source semantics and is not an automatic rejection condition. |

## 5. `student_vle` repeated-key investigation

For the candidate key `(code_module, code_presentation, id_student, id_site, date)`:

- Total rows: 10,655,280.
- Distinct candidate-key combinations: 8,459,320.
- Excess rows relative to one row per candidate key: 2,195,960.
- Repeated-key groups: 1,614,505; rows in those groups: 3,810,465.
- Groups with one distinct `sum_click`: 435,431.
- Groups with more than one distinct `sum_click`: 1,179,074.
- Fully identical groups across all six columns: 642,613; excess identical rows in those groups: 787,170.
- Maximum repeated-key group size: 10.
- `sum_click`: no NULL, negative, or zero values in the test; minimum 1, maximum 6,977, total 39,605,099.

Some candidate-key groups have different click counts, and some contain identical rows. Neither pattern proves whether the rows represent separate interactions, repeated aggregation, or a logging issue. The source is preserved. No deduplication and no `SUM(sum_click)` transformation have been applied.

## 6. Missing-value and numeric validation

In RAW, the audited source fields contained zero SQL NULLs and zero blank strings in the original audit; missingness was represented by literal `?` tokens. C2 and S1 confirmed that the selected tokens were converted to NULL only in STAGING, with exact counts matching RAW:

| Field | RAW `?` tokens | STAGING NULLs |
|---|---:|---:|
| `assessments.date` | 11 | 11 |
| `student_registration.date_registration` | 45 | 45 |
| `student_registration.date_unregistration` | 22,521 | 22,521 |
| `student_assessment.score` | 173 | 173 |
| `student_info.imd_band` | 1,111 | 1,111 |
| `vle.week_from` | 5,243 | 5,243 |
| `vle.week_to` | 5,243 | 5,243 |

S2 found zero residual `?` values in the checked STAGING columns. S3 found 173 NULL scores, no negative scores, no scores greater than 100, and observed score limits of 0 and 100. The C2 checks found no other nonnumeric tokens in the selected conversion fields.

For `assessments.weight`, 206 rows had a range from 0 to 100 and a table-wide sum of 4,300.0. The sum is descriptive only; no global sum-to-100 rule is assumed without grouping by the correct scope and source validation.

## 7. Temporal diagnostics

- Registration/unregistration comparison: zero rows with unregistration earlier than registration; 19 same-day cases. Registration values ranged from -322 to 167 and unregistration values from -365 to 444 when parseable. Relative-day values are not automatically invalid solely because they are negative.
- Assessment submission versus assessment day: 49,318 after, 29,469 on, 92,260 before, and 2,865 with an unavailable assessment day.
- Student VLE relative days: 688,988 negative; zero beyond module-presentation length; range -25 to 269.
- VLE week boundaries: 5,243 missing/non-numeric values in each boundary; zero reversed numeric ranges; observed numeric boundaries from 0 to 29.

## 8. Categorical domain review

Observed values were captured for `gender`, `age_band`, `disability`, `final_result`, `highest_education`, `region`, and `code_module`. The separate query comparing observed values to the listed accepted-value sets returned zero rows. The registry item remains `REVIEW` so that the source/documentation reference and registry decision are reconciled deliberately rather than silently changing the recorded status.

## 9. STAGING types and integrity

The following fields were converted in STAGING:

- `assessments.date` → INTEGER
- `student_registration.date_registration`, `date_unregistration` → INTEGER
- `student_assessment.score` → NUMERIC
- `student_info.imd_band` → TEXT with documented `?` mapped to NULL
- `vle.week_from`, `week_to` → INTEGER

The other fields were copied from their RAW counterparts. Row counts matched for all seven tables. The tested token-to-NULL counts reconciled exactly. Numeric scores were within 0–100; numeric VLE week boundaries were within 0–29 and no reversed numeric ranges were found.

STAGING was created with `CREATE TABLE AS SELECT`. PostgreSQL does not automatically copy all source table constraints and indexes through this form, so key constraints and indexes in STAGING must not be assumed to exist unless separately created and checked.

## 10. Phase outcome and next step

The core data-engineering phase is ready to close. The four REVIEW items remain as explicit interpretation caveats; they do not require repeating completed checks or altering RAW. The next phase should begin with table-grain definitions, valid join paths, candidate analytical outputs, and KPI specifications, then verify those definitions with SQL. No analytical results or recommendations have been created in this phase.

## 11. Reproducibility note

Results in this report are based on SQL execution outputs supplied during the project workflow. The documentation update pack updates local files when copied into the repository; it does not itself update a remote GitHub repository. Commit and push status should be reported only after confirming the local Git operations.

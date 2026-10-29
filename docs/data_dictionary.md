# OULAD Data Dictionary

**Project Owner & Lead Analyst:** Abdeljalil El Khyati

**Project:** OULAD — EdTech Learning Analytics  
**Source:** Open University Learning Analytics Dataset (OULAD), acquired reproducibly through UCI Machine Learning Repository Dataset 349  
**Status:** RAW loaded and STAGING created and validated; analytical layer not yet implemented  
**Last Updated:** 2026-10-16

## Dictionary Rules

- Definitions describe the source-level meaning before analytical transformation.
- RAW preserves source column names and source values.
- PostgreSQL types below reflect the validated RAW design, not necessarily the final STAGING types.
- Candidate keys for six RAW tables passed the reported uniqueness/completeness checks and primary-key constraints were applied to those tables.
- `student_vle` has no RAW primary key because its tested five-column candidate key is not unique.
- STAGING uses typed representations; documented `?` tokens become SQL `NULL` only in the selected STAGING columns. RAW retains its source representation.
- STAGING was created with `CREATE TABLE AS SELECT`; do not assume RAW constraints or indexes were copied.

## 1. `courses`

**Grain:** One module presentation.  
**Candidate / Primary Key:** `(code_module, code_presentation)`  
**Rows:** 22

| Column | PostgreSQL type | Nullable | Meaning |
| --- | --- | --- | --- |
| `code_module` | TEXT | No | Module code |
| `code_presentation` | TEXT | No | Presentation code / period |
| `module_presentation_length` | INTEGER | No | Length of the presentation in days |

## 2. `assessments`

**Grain:** One assessment record within a module presentation.  
**Candidate / Primary Key:** `id_assessment`  
**Rows:** 206

| Column | PostgreSQL type | Nullable | Meaning |
| --- | --- | --- | --- |
| `code_module` | TEXT | No | Module code |
| `code_presentation` | TEXT | No | Presentation code / period |
| `id_assessment` | INTEGER | No | Assessment identifier |
| `assessment_type` | TEXT | No | Assessment type |
| `date` | TEXT | Yes | Assessment date / source day value |
| `weight` | NUMERIC | No | Assessment weight as a percentage |

`weight` was validated to contain real decimal values, including 7.5, 12.5 and 17.5; therefore RAW uses `NUMERIC`.

## 3. `student_info`

**Grain:** One student in one module presentation.  
**Candidate / Primary Key:** `(code_module, code_presentation, id_student)`  
**Rows:** 32,593

| Column | PostgreSQL type | Nullable | Meaning |
| --- | --- | --- | --- |
| `code_module` | TEXT | No | Module code |
| `code_presentation` | TEXT | No | Presentation code / period |
| `id_student` | INTEGER | No | Student identifier |
| `gender` | TEXT | No | Gender category in source |
| `region` | TEXT | No | Student region |
| `highest_education` | TEXT | No | Highest education level |
| `imd_band` | TEXT | Yes | IMD band |
| `age_band` | TEXT | No | Age band |
| `num_of_prev_attempts` | INTEGER | No | Number of previous attempts |
| `studied_credits` | INTEGER | No | Credits studied |
| `disability` | TEXT | No | Disability indicator |
| `final_result` | TEXT | No | Final result |

## 4. `student_registration`

**Grain:** One registration record for one student in one module presentation.  
**Candidate / Primary Key:** `(code_module, code_presentation, id_student)`  
**Rows:** 32,593

| Column | PostgreSQL type | Nullable | Meaning |
| --- | --- | --- | --- |
| `code_module` | TEXT | No | Module code |
| `code_presentation` | TEXT | No | Presentation code / period |
| `id_student` | INTEGER | No | Student identifier |
| `date_registration` | TEXT | Yes | Registration day value |
| `date_unregistration` | TEXT | Yes | Unregistration day value |

The registration date fields remain nullable `TEXT` in RAW because source missing values/placeholders were observed.

## 5. `student_assessment`

**Grain:** One student's submission for one assessment.  
**Candidate / Primary Key:** `(id_assessment, id_student)`  
**Rows:** 173,912

| Column | PostgreSQL type | Nullable | Meaning |
| --- | --- | --- | --- |
| `id_assessment` | INTEGER | No | Assessment identifier |
| `id_student` | INTEGER | No | Student identifier |
| `date_submitted` | INTEGER | No | Submission day value |
| `is_banked` | INTEGER | No | Banked submission indicator |
| `score` | TEXT | Yes | Assessment score |

`score` contains 173 source `?` placeholders. Although valid numeric values are integer-valued, RAW uses nullable `TEXT` to preserve the source representation.

## 6. `vle`

**Grain:** One VLE resource/site within a module presentation.  
**Candidate / Primary Key:** `id_site`  
**Rows:** 6,364

| Column | PostgreSQL type | Nullable | Meaning |
| --- | --- | --- | --- |
| `id_site` | INTEGER | No | VLE site identifier |
| `code_module` | TEXT | No | Module code |
| `code_presentation` | TEXT | No | Presentation code / period |
| `activity_type` | TEXT | No | Activity/resource type |
| `week_from` | TEXT | Yes | Starting week value |
| `week_to` | TEXT | Yes | Ending week value |

## 7. `student_vle`

**Grain:** One recorded student interaction with one VLE site on one day.  
**Candidate Key Tested:** `(code_module, code_presentation, id_student, id_site, date)`  
**Rows:** 10,655,280  
**Unique candidate-key combinations:** 8,459,320  
**Duplicate rows under this candidate key:** 2,195,960  
**RAW Primary Key:** None by design

| Column | PostgreSQL type | Nullable | Meaning |
| --- | --- | --- | --- |
| `code_module` | TEXT | No | Module code |
| `code_presentation` | TEXT | No | Presentation code / period |
| `id_student` | INTEGER | No | Student identifier |
| `id_site` | INTEGER | No | VLE site identifier |
| `date` | INTEGER | No | Interaction day value |
| `sum_click` | INTEGER | No | Recorded click count |

The duplicate structure has been characterized but not fully interpreted. Different `sum_click` values and fully identical rows both occur inside repeated-key groups. No aggregation rule such as `SUM(sum_click)` is assumed, and no source rows have been deleted. This remains an analytical grain/metric decision rather than an unresolved table-creation task.


## 8. STAGING type mapping and validated missingness

STAGING table row counts match their RAW counterparts: `courses` 22; `assessments` 206; `student_info` 32,593; `student_registration` 32,593; `student_assessment` 173,912; `vle` 6,364; and `student_vle` 10,655,280.

| Table / field | RAW type | STAGING type | RAW missing token count | STAGING NULL count |
|---|---|---|---:|---:|
| `assessments.date` | TEXT | INTEGER | 11 | 11 |
| `student_registration.date_registration` | TEXT | INTEGER | 45 | 45 |
| `student_registration.date_unregistration` | TEXT | INTEGER | 22,521 | 22,521 |
| `student_assessment.score` | TEXT | NUMERIC | 173 | 173 |
| `student_info.imd_band` | TEXT | TEXT | 1,111 | 1,111 |
| `vle.week_from` | TEXT | INTEGER | 5,243 | 5,243 |
| `vle.week_to` | TEXT | INTEGER | 5,243 | 5,243 |

The C2 conversion pre-checks reported no unexpected nonnumeric values in the fields tested. S1 reconciled each source `?` count to its STAGING NULL count; the S2 check found no residual `?` values in those STAGING fields. S3 found 173 NULL scores, no negative values, no values above 100, and observed score limits of 0–100. S4 found no reversed numeric VLE week ranges; observed numeric boundaries were 0–29.

`student_vle` remained row-preserving in STAGING: 10,655,280 rows, 8,459,320 distinct five-column key combinations, and 2,195,960 excess rows relative to distinct keys. No deduplication or aggregation was applied.

## 9. Additional documented source observations

- `student_vle.sum_click`: 10,655,280 rows; no NULL, negative, or zero values; minimum 1, maximum 6,977; total 39,605,099. These checks do not explain the repeated-key patterns.
- `assessments.weight`: 206 rows; observed range 0–100 and table-wide sum 4,300.0. The total is descriptive and is not treated as a global sum-to-100 rule.
- `student_registration`: 45 missing registration-day tokens and 22,521 missing unregistration-day tokens. No unregistration-before-registration rows were observed; 19 same-day cases were recorded. Parsed registration values ranged from -322 to 167 and unregistration values from -365 to 444.
- `student_assessment` submission timing versus listed assessment day: 49,318 after, 29,469 on, 92,260 before, and 2,865 with unavailable assessment day. This is diagnostic, not an automatic validity rule.
- `student_vle.date`: 688,988 negative relative days; none exceeded the corresponding presentation length; observed range -25 to 269. Negative values are retained pending semantic interpretation.
- Categorical domain validation returned zero rows outside the explicit accepted-value lists used in the query. The associated quality-registry test remains `REVIEW` until its domain reference and status are deliberately reconciled.

## 10. Registry status at engineering closure

The quality registry contains 29 records with 29 distinct test codes: 25 `PASS` and 4 `REVIEW`. The four review findings are `B2.2_STUDENT_VLE_KEY`, `B5.2_CATEGORICAL_VALUES_REVIEW`, `B5.3_STUDENT_VLE_RELATIVE_DAY`, and `B5.3_SUBMISSION_VS_ASSESSMENT_DATE`. All historical `executed_at` fields remain NULL because exact execution times were not captured.

## 11. Observed categorical values in `raw.student_info`

These are the observed values from the completed category-distribution query, not a substitute for the official source dictionary:

| Field | Observed values |
|---|---|
| `gender` | `F`, `M` |
| `age_band` | `0-35`, `35-55`, `55<=` |
| `disability` | `N`, `Y` |
| `final_result` | `Distinction`, `Fail`, `Pass`, `Withdrawn` |
| `highest_education` | `A Level or Equivalent`, `HE Qualification`, `Lower Than A Level`, `No Formal quals`, `Post Graduate Qualification` |
| `region` | `East Anglian Region`, `East Midlands Region`, `Ireland`, `London Region`, `North Region`, `North Western Region`, `Scotland`, `South East Region`, `South Region`, `South West Region`, `Wales`, `West Midlands Region`, `Yorkshire Region` |
| `code_module` | `AAA`, `BBB`, `CCC`, `DDD`, `EEE`, `FFF`, `GGG` |

The validation query comparing observed values against the explicit lists above returned zero rows outside those lists. The registry test remains `REVIEW` until the source/domain reference and the decision to change its status are documented.

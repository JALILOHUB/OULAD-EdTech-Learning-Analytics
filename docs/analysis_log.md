# Analysis Log — OULAD EdTech Learning Analytics

**Project Owner & Lead Analyst:** Abdeljalil El Khyati

| Date | Stage | Question / Decision | Evidence | Result | Decision | Next action |
|------|-------|---------------------|----------|--------|----------|-------------|
| 2026-09-29 | Project setup | Separate SQL and Python? | Project architecture | Yes | PostgreSQL is the analytical backbone | Install PostgreSQL and Jupyter |
| 2026-10-03 | Data ingestion | Fix relative path vulnerability and ensure safe re-execution? | Initial extraction could target `notebooks/data/raw/`; repeated runs could re-download the archive | Path-resolution and idempotency issues identified | Use robust `pathlib` path resolution and skip existing downloads/extractions | Validate ingestion and source structure |
| 2026-10-04 | Phase 1.5 | Is `(code_module, code_presentation, id_student, id_site, date)` a unique key for `studentVle`? | Candidate-key validation | 10,655,280 rows vs 8,459,320 unique combinations | Do not enforce a RAW primary key on `student_vle` | Characterize duplicates after RAW loading |
| 2026-10-04 | Phase 2A | What PostgreSQL types and nullability are justified by the source? | Value, missing-value, and header validation | Decimal `weight`; `?` in `score`; source missing values in several fields; all seven headers matched | Use validated RAW types and nullable columns where source missingness exists | Create RAW tables |
| 2026-10-04 | Phase 2B | Can the seven RAW tables be created without prematurely transforming the source? | Validated Phase 2A findings | Seven tables created in `raw` | Keep RAW faithful; no FKs or business transformations | Load source files |
| 2026-10-06 | Phase 2C | Can the seven CSV sources be loaded into PostgreSQL RAW efficiently? | PostgreSQL `COPY` execution and row-count reconciliation query | Load completed successfully; reconciliation query returned seven table results | RAW load accepted | Characterize `student_vle` duplicates |

## Engineering Decision: Source Path Resolution and Idempotency

The initial ingestion workflow used a relative `data/raw` path. In Jupyter, the current working directory can vary, which caused a risk of creating the raw-data directory under `notebooks/` rather than at project root.

The implementation was changed to resolve the project root with `pathlib` and to avoid re-downloading or re-extracting files that already exist. The goal was reproducibility and safe re-execution rather than a manual folder move.

## Engineering Decision: RAW Type and Nullability Validation

The source was inspected before `CREATE TABLE` decisions were finalized.

Key findings:

- `assessments.weight` contains real decimal values, so RAW uses `NUMERIC`.
- `assessments.date` contains source missing values, so RAW keeps it nullable as `TEXT`.
- `studentAssessment.score` contains 173 `?` placeholders, so RAW keeps it nullable as `TEXT`.
- `studentRegistration.date_registration` contains source missing values, so RAW keeps it nullable as `TEXT`.
- `studentRegistration.date_unregistration` contains `?` values, so RAW keeps it nullable as `TEXT`.
- `studentInfo.imd_band` contains missing values, so RAW keeps it nullable as `TEXT`.
- `vle.week_from` and `vle.week_to` contain source missing values, so RAW keeps them nullable as `TEXT`.
- All seven CSV headers matched the expected source column names and order.

## Engineering Decision: `student_vle` Duplicate Handling

The tested candidate key is not unique. This does not justify deleting rows or aggregating `sum_click` automatically.

The current decision is to preserve all source rows in RAW and characterize the duplicate groups before selecting a STAGING rule.

### Current Gate

**Phase 2D — Duplicate characterization** is the next action.

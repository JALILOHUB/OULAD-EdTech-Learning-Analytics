# OULAD — EdTech Learning Analytics

**Project Owner \& Lead Analyst:** Abdeljalil El Khyati

## Project purpose

This project uses the Open University Learning Analytics Dataset (OULAD) to build a reproducible, client-style learning analytics workflow. The central business question is:

> \\\*\\\*How can an online learning platform identify engagement patterns, academic risk, and factors associated with student success?\\\*\\\*

The project separates data ingestion, data quality, transformations, analytical modelling, reporting, and optional advanced analytics. PostgreSQL is the relational and analytical backbone.

## Architecture

Official OULAD source → Python source acquisition and profiling → PostgreSQL `raw` → `quality` checks and registry → PostgreSQL `staging` → future `analytics` views / `mart` tables → Power BI. Python advanced analytics will be used when justified by a defined question.

## Analytical principles

* Preserve source evidence in RAW; do not apply business cleaning or aggregation there.
* Convert documented source missing tokens only in the typed STAGING layer, keeping RAW unchanged.
* Define each analytical table's grain before designing joins or measures.
* Do not delete or aggregate repeated `student\\\_vle` rows solely because a candidate key is non-unique.
* Distinguish observation, association, prediction, and causation. Do not claim causal effects from association alone.
* Document the reason, implementation, validation, interpretation, and decision for important transformations.

## Repository map

* `docs/` — architecture, data dictionary, analysis log, quality findings, and phase handover.
* `sql/00\\\_database/` — database-schema setup scripts.
* `sql/01\\\_raw/` — RAW table definitions and source loading.
* `sql/02\\\_quality/` — data-quality checks, duplicate characterization, and registry scripts.
* `sql/03\\\_staging/` — typed STAGING creation and integrity validation.
* `sql/04\\\_analytics/`, `sql/05\\\_marts/`, `sql/06\\\_kpis/` — planned analytical outputs, marts, and metric definitions.
* `src/` — Python ingestion, profiling, quality support, and justified advanced analytics.
* `notebooks/` — documented project workflow and exploratory work.
* `powerbi/` — reporting documentation and deliverables.
* `reports/` — final reports grounded in verified findings.
* `tests/` — reusable automated checks.
* `config/` — non-secret configuration templates.

## Data and security policy

The local PostgreSQL database is the working data store. Raw OULAD CSV files, passwords, `.env` files, private connection settings, and secrets must not be committed to Git. The `.env.example` file may contain placeholders only.

## Source

Open University Learning Analytics Dataset (OULAD): https://research.stem.open.ac.uk/ouanalyse/dataset/

The UCI Machine Learning Repository Dataset 349 was used as a reproducible source for acquiring the dataset archive. The dataset's licensing and attribution requirements remain applicable to the data; the repository's code licence does not replace them.

## Current project status — 15 October 2026

**Core data engineering implementation and validation are complete. Analytical modelling has not started.**

* Seven RAW tables are loaded and reconcile to the established row-count baseline.
* Seven typed STAGING tables have been created. STAGING row counts match RAW for all seven tables.
* Checks C2 and S1–S4 confirmed the selected type conversions, missing-token-to-NULL reconciliation, zero remaining `?` tokens in the checked STAGING columns, the tested score bounds, and valid numeric VLE week ranges.
* The data-quality registry contains 29 records and 29 distinct test codes: 25 `PASS` and 4 `REVIEW`. Historical `executed\\\_at` values remain NULL because exact execution timestamps were not captured.
* Four review items remain documented: the `student\\\_vle` candidate key, categorical-domain reference documentation, negative relative VLE days, and submission timing relative to assessment days.
* No rows were deleted from `student\\\_vle`, and `sum\\\_click` was not aggregated.

The next phase starts with analytical grain, relationships, metric definitions, and measurable business questions. No analytical result or recommendation has been invented or reported yet.


# OULAD — EdTech Learning Analytics

**Project Owner & Lead Analyst:** Abdeljalil El Khyati

## Project Purpose

This project analyzes the Open University Learning Analytics Dataset (OULAD) as a realistic client-style analytics engagement.

The main business question is:

> **How can an online learning platform identify engagement patterns, academic risk, and factors associated with student success?**

The project deliberately separates the responsibilities of SQL, Python, and Power BI while keeping PostgreSQL as the analytical backbone.

## Architecture

Official OULAD source
→ Python ingestion / profiling
→ PostgreSQL RAW layer
→ Data Quality
→ PostgreSQL STAGING layer
→ PostgreSQL Analytical Layer / Data Mart
→ Power BI
→ Python advanced analytics when justified

## Analytical Principles

- SQL is the backbone for relational data work and analytical transformations.
- Python is used where it adds value: ingestion, profiling, statistical analysis, advanced transformations, and machine learning when justified.
- Power BI is used as the communication and reporting layer rather than as the primary data-processing environment.
- RAW preserves source column names and source values while using validated PostgreSQL data types.
- No cleaning, aggregation, duplicate removal, or business transformation is performed in RAW.
- Relationships are described as **associated with** unless the research design supports causal claims.
- Unexpected data behavior is investigated before transformation or removal.

## Repository Map

`docs/` — project documentation and decisions  
`sql/` — database, RAW, quality, staging, analytics and KPI SQL  
`src/` — Python ingestion and supporting analysis scripts  
`notebooks/` — documented analytical workflow  
`powerbi/` — Power BI documentation and exported deliverables  
`reports/` — final findings and recommendations  
`tests/` — reproducible data-quality checks  
`config/` — non-secret configuration templates

## Data Policy

Raw OULAD files are not committed to Git. PostgreSQL is the working data store. Credentials, `.env` files, local database settings, and other secrets must never be committed.

## Current Project Status

### Completed

- Source acquisition and source verification
- Pre-ingestion structural profiling
- Grain and candidate-key validation
- Phase 2A RAW type, missing-value, and source-header validation
- Phase 2B PostgreSQL RAW schema creation for all seven OULAD tables
- Phase 2C CSV → PostgreSQL RAW loading using PostgreSQL `COPY`
- RAW row-count reconciliation query execution

### Current Step

**Phase 2D — `student_vle` duplicate characterization**

The candidate key `(code_module, code_presentation, id_student, id_site, date)` is not unique in the source. The duplicates must be characterized before deciding whether STAGING should aggregate `sum_click` or apply another transformation.

## Source

Open University Learning Analytics Dataset (OULAD):
https://research.stem.open.ac.uk/ouanalyse/dataset/

UCI Machine Learning Repository Dataset 349 was used for reproducible local acquisition of the source archive.

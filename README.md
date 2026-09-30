# OULAD — EdTech Learning Analytics

## Project purpose

This project analyzes the **Open University Learning Analytics Dataset (OULAD)** as a realistic client-style analytics engagement.

The main business question is:

> **How can an online learning platform identify engagement patterns, academic risk, and factors associated with student success?**

This project deliberately separates the responsibilities of SQL, Python, and Power BI.

### Architecture

Official OULAD source
→ Python ingestion / profiling
→ PostgreSQL RAW layer
→ Data Quality
→ PostgreSQL STAGING layer
→ PostgreSQL Analytical Layer / Data Mart
→ Power BI
→ Python advanced analytics when justified

### Important analytical rule

We describe relationships as **associated with** unless the research design supports causal claims.

### Repository map

- `docs/` — project documentation and decisions
- `sql/` — database, raw, quality, staging, analytics and KPI SQL
- `src/` — Python ingestion and supporting analysis scripts
- `notebooks/` — documented analytical workflow
- `powerbi/` — Power BI documentation and exported deliverables
- `reports/` — final findings and recommendations
- `tests/` — reproducible data-quality checks
- `config/` — non-secret configuration templates

### Data policy

Raw OULAD files are **not committed to Git**. The PostgreSQL database is the working data store. Credentials and local database settings must never be committed.

### Source

Open University Learning Analytics Dataset (OULAD):
https://research.stem.open.ac.uk/ouanalyse/dataset/

## Current status

Project scaffold created. No analytical result has been invented yet. Results, decisions, exceptions and recommendations will be updated as the analysis progresses.

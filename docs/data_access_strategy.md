# Data Access Strategy

**Project Owner & Lead Analyst:** Abdeljalil El Khyati  
**Updated:** 2026-10-15

## Decision

Do not commit the OULAD source CSV files to Git. Keep reproducible acquisition code, SQL scripts, notebooks, documentation, and non-secret configuration under version control; use PostgreSQL as the persistent working data store.

## Implemented workflow

1. Acquire the OULAD archive from a reproducible source and verify the extracted source files.
2. Resolve the raw-data path from the project location rather than relying on the notebook's current working directory.
3. Profile row counts, headers, key candidates, missing tokens, value ranges, and observed types before finalizing the RAW schema.
4. Load the seven CSV files into PostgreSQL RAW using server-side `COPY`.
5. Run SQL data-quality checks and record their results in `quality.test_results`.
6. Create typed STAGING tables from RAW and validate the selected conversions and row-count reconciliation.

## Important clarification

The goal is not to avoid all local storage. PostgreSQL stores the working data locally for this implementation. The goal is to avoid committing the large raw files to Git and to avoid unnecessarily loading the largest table (over 10 million rows) entirely into Pandas memory.

## Alternatives considered

### Python-only processing

Not selected because SQL and relational modelling are explicit goals of this project.

### CSV → Pandas → all transformations

Not selected as the main path because it weakens the demonstration of SQL joins, relational constraints, aggregation, and database-native validation, particularly for `student_vle`.

### Remote-only database

Deferred until the model and analytical requirements justify the additional infrastructure.

### Local PostgreSQL

Selected for the current phase because it provides persistent relational storage, SQL validation, and a future connection path for Power BI without introducing cloud complexity prematurely.

## Data protection and reproducibility

Never commit passwords, API keys, `.env` files, private connection strings, or local-only database settings. Keep `.env.example` limited to placeholders. Source acquisition and database loading should have clearly documented re-run precautions: `COPY` will append or fail against already populated tables depending on the target's constraints, so the RAW load script must not be blindly re-run against existing data.

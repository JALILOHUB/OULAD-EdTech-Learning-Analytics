# Data Access Strategy

**Project Owner & Lead Analyst:** Abdeljalil El Khyati

## Decision

Do not commit OULAD CSV files to Git.

The working workflow is:

1. Acquire and verify the reproducible OULAD source files.
2. Profile the source before database design.
3. Load the source tables into PostgreSQL RAW tables.
4. Use PostgreSQL as the persistent analytical store.
5. Keep SQL scripts, Python code, notebooks, documentation, and reproducible configuration in Git.

## Important Clarification

A SQL database necessarily stores the working data somewhere. The objective is therefore not to avoid all local storage, but to avoid maintaining large CSV copies in the project repository and to avoid loading the largest source tables entirely into Pandas memory when that is unnecessary.

For ingestion and profiling, memory-efficient and database-native techniques are preferred where appropriate.

## Current Source and Acquisition

The project uses the OULAD source published by The Open University. UCI Machine Learning Repository Dataset 349 was used for reproducible local acquisition of the downloadable archive.

The source CSV structure was validated before PostgreSQL table creation, including exact column names, column order, missing-value behavior, and candidate-key behavior.

## Alternatives Considered

### Python only

Rejected for this project because SQL is an explicit project objective and the relational structure is central to OULAD.

### CSV → Pandas → everything

Rejected because it weakens the SQL and relational-data engineering demonstration, especially with the 10M+ row `studentVle` table.

### Remote-only database

Possible in a production environment, but unnecessary for the first portfolio implementation and adds infrastructure complexity before the analytical model is validated.

### PostgreSQL local

Selected for the current project because it provides a real SQL environment, persistent storage, relational constraints, validation capabilities, and a clean connection path for later Power BI use.

## Data Protection

Raw data remains outside Git. Database credentials and local connection settings must remain outside the repository.

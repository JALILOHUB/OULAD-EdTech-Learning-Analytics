# Data Access Strategy

## Decision

Do not commit OULAD CSV files to Git.

The preferred workflow is:

1. Download/read the official source using Python.
2. Load the source tables into PostgreSQL RAW tables.
3. Use PostgreSQL as the persistent analytical store.
4. Keep only scripts, SQL, notebooks, documentation and reproducible configuration in Git.

## Important clarification

A SQL database necessarily stores the working data somewhere. The goal is therefore **not** to avoid all local storage, but to avoid maintaining large CSV copies in the project repository and avoid loading the whole dataset into Pandas memory.

For ingestion, we will use streaming/batched techniques where appropriate.

## Alternatives considered

### Python only
Rejected for this project because SQL is an explicit project objective and the relational structure is central to OULAD.

### CSV → Pandas → everything
Rejected because it weakens the SQL/data-modeling demonstration.

### Remote-only database
Possible in a production environment, but unnecessary for the first portfolio implementation and adds infrastructure complexity.

### PostgreSQL local
Selected for the project because it gives a real SQL environment, persistent storage, indexing and a clean connection path for Power BI.

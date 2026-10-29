# Python Ingestion

Python supports reproducible source acquisition, archive extraction, source-file checks, and loading preparation. The current database ingestion was performed through PostgreSQL `COPY` using the canonical script in `sql/01_raw/02_load_raw.sql`.

The ingestion workflow should:

- resolve project and data paths robustly rather than depending on the current working directory;
- avoid needless archive downloads or file overwrites;
- validate expected source files and headers before loading;
- preserve source values and record source metadata;
- avoid loading the full 10M+ row activity file into Pandas unless a justified task requires it;
- never hard-code passwords or private settings.

Treat the SQL `COPY` script as non-idempotent against already populated tables. The existing RAW load is complete; do not re-run it casually.

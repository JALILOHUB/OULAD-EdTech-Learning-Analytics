# Ingestion

Python is responsible for controlled access to the official source and loading into PostgreSQL.

The ingestion process must:
- avoid loading the entire dataset into Pandas unnecessarily;
- preserve source values;
- record source metadata;
- make loading reproducible;
- never hard-code passwords.

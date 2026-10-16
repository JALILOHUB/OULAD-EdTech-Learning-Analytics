# Python Data Quality Support

PostgreSQL SQL scripts are the canonical record for the RAW and STAGING data-quality checks completed so far. Python quality checks may be added when they provide a specific benefit, such as validation of downloaded source files, schema comparison before loading, or statistical checks that are clearer outside SQL.

Do not duplicate existing SQL checks without documenting the reason and the source of truth. Do not remove records automatically because they contain a missing value, repeated key, negative relative day, or unusual value. Record expected and actual results and link the finding to the analysis log.

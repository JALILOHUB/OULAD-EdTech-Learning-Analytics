# Python Profiling

Python profiling complements the canonical SQL checks; it should not duplicate them without a clear reason. The completed pre-ingestion profiling covered row counts, source headers and column order, observed types, missing tokens, candidate keys, and selected value distributions.

Useful profiling outputs may include:

- row counts and file sizes;
- schema and source-header comparison;
- missingness representation;
- distinct values and distributions;
- min/max and numeric summaries;
- candidate-key and grain diagnostics.

Each notebook cell should explain why a profile is needed, state what its output can and cannot prove, and keep raw data unmodified.

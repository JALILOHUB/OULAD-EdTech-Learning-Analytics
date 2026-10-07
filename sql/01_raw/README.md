# RAW SQL Layer

**Project Owner & Lead Analyst:** Abdeljalil El Khyati

## Purpose

The RAW layer is the database representation of the seven OULAD source tables after source validation and before analytical transformation.

## Design Principles

- Preserve source column names and source values.
- Use PostgreSQL data types based on validated source observations.
- Preserve source missing-value representations where required for source fidelity.
- Do not apply business logic, cleaning, aggregation, duplicate removal, or analytical transformations in RAW.
- Apply primary keys only where candidate-key uniqueness was validated.
- Do not impose a primary key on `student_vle` because its tested candidate key is not unique.
- Characterize unexpected duplicate behavior before choosing a STAGING transformation.

## Current Status

The seven RAW tables have been created and loaded successfully. The loading script uses PostgreSQL `COPY`, followed by row-count reconciliation.

### Files

- `01_create_raw_tables.sql` — RAW schema definition
- `02_load_raw.sql` — CSV loading and row-count reconciliation

## Next Step

Execute the duplicate-characterization queries for `raw.student_vle` and document the observed pattern before designing the STAGING layer.

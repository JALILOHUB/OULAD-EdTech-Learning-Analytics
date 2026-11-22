-- Purpose: Create the isolated Part 3 working database.
-- Run from an existing maintenance connection (for example, database "postgres").
-- Safety: Creates only oulad_an8_work. Does not connect to or modify oulad_analytics.
-- Execution: Run once. If the database already exists, stop and inspect it; do not drop it.

CREATE DATABASE oulad_an8_work;

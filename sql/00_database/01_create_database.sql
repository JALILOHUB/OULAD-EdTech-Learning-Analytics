-- Purpose:
-- Create the project database. Run this from an existing PostgreSQL connection
-- (for example the default postgres database), not from inside the target database.
--
-- Why:
-- We want SQL to remain independent from Python.
--
-- NOTE:
-- Database creation may require administrative privileges.

CREATE DATABASE oulad_analytics;

-- Question: Is the notebook connected to the intended PostgreSQL database and a read-only session?
-- Expectation: The database is oulad_analytics and transaction_read_only is on.
-- Grain: One row per active database session.
-- Source: PostgreSQL session settings and system functions.
-- Safety: READ-ONLY
-- Runtime: Very low; metadata only.
-- Read as: Stop if the database is unexpected or transaction_read_only is not on.

-- 1. Confirm the active database, user, server version, schema, and session safety settings.
SELECT current_database() AS database_name,
       current_user AS database_user,
       current_schema() AS current_schema,
       current_setting('server_version') AS server_version,
       current_setting('transaction_read_only') AS transaction_read_only,
       current_setting('default_transaction_read_only') AS default_transaction_read_only,
       current_setting('statement_timeout') AS statement_timeout,
       current_setting('lock_timeout') AS lock_timeout;

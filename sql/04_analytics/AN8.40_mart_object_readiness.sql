-- Question: Are curated mart objects ready to be created?
-- Expectation: NOT_READY until metrics, grain, refresh policy, and approval are settled.
-- Grain: One readiness status row.
-- Source: Project decisions.
-- Safety: READ-ONLY SELECT; no DDL.
-- Runtime: LOW.
-- Read as: This query does not create an object.
SELECT 'AN8_MART_DDL'::TEXT workstream,'NOT_READY'::TEXT approval_status,
 'Await validated metrics, explicit object design, refresh policy, and owner approval'::TEXT reason;
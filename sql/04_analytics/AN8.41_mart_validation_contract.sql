-- [AN8.41] Curated reporting-table validation contract
-- Question: What validations are required before future mart publication?
-- Expectation: List planned gates; do not claim they have passed.
-- Grain: One row per validation gate.
-- Source: Project operating contract.
-- Safety: READ-ONLY SELECT; no DDL/DML.
-- Runtime: LOW.
-- Read as: Planned controls, not executed test results.
SELECT * FROM (VALUES
('grain','One row per declared business key','REQUIRED'),
('join_cardinality','No unintended fan-out','REQUIRED'),
('denominator','Numerator and denominator independently reconciled','REQUIRED'),
('missingness','NULL, zero, and non-estimable states distinct','REQUIRED'),
('time_basis','Course-relative and registration-relative windows explicit','REQUIRED'),
('leakage','Retrospective outcomes excluded from predictors','REQUIRED'),
('approval','Metric definitions and mart DDL explicitly approved','REQUIRED')
) AS gates(validation_area,acceptance_criterion,status);
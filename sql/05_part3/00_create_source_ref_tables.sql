-- Purpose: Create the source-faithful TEXT landing tables for Part 3.
-- Target database: oulad_an8_work
-- Safety: Creates schemas and seven empty tables only. No source data is loaded here.
-- Design: Preserve source CSV values as TEXT; retain empty strings and '?' separately.
-- Execution: Run once after creating oulad_an8_work. Do not rerun if objects already exist.

BEGIN;

CREATE SCHEMA source_ref;
CREATE SCHEMA working;
CREATE SCHEMA audit;
CREATE SCHEMA derived;

CREATE TABLE source_ref.courses (
    code_module TEXT,
    code_presentation TEXT,
    module_presentation_length TEXT
);

CREATE TABLE source_ref.assessments (
    code_module TEXT,
    code_presentation TEXT,
    id_assessment TEXT,
    assessment_type TEXT,
    date TEXT,
    weight TEXT
);

CREATE TABLE source_ref.student_info (
    id_student TEXT,
    code_module TEXT,
    code_presentation TEXT,
    gender TEXT,
    region TEXT,
    highest_education TEXT,
    imd_band TEXT,
    age_band TEXT,
    num_of_prev_attempts TEXT,
    studied_credits TEXT,
    disability TEXT,
    final_result TEXT
);

CREATE TABLE source_ref.student_registration (
    id_student TEXT,
    code_module TEXT,
    code_presentation TEXT,
    date_registration TEXT,
    date_unregistration TEXT
);

CREATE TABLE source_ref.student_assessment (
    id_assessment TEXT,
    id_student TEXT,
    date_submitted TEXT,
    is_banked TEXT,
    score TEXT
);

CREATE TABLE source_ref.vle (
    id_site TEXT,
    code_module TEXT,
    code_presentation TEXT,
    activity_type TEXT,
    week_from TEXT,
    week_to TEXT
);

CREATE TABLE source_ref.student_vle (
    code_module TEXT,
    code_presentation TEXT,
    id_student TEXT,
    id_site TEXT,
    date TEXT,
    sum_click TEXT
);

COMMIT;

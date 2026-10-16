-- ============================================================================
-- File: 01_create_raw_tables.sql
-- Purpose: Create RAW layer tables for the OULAD dataset
-- Schema: raw
-- Principle: Preserve source column names and source values using validated
--            PostgreSQL data types; no business transformation in RAW.
-- Project Owner & Lead Analyst: Abdeljalil El Khyati
-- Date: 2026-10-06
-- ============================================================================

-- Tables are intentionally created without DROP statements during the initial
-- project build. Recreate only after an explicit schema-change decision.

-- 1. courses
-- Grain: One module presentation
CREATE TABLE raw.courses (
    code_module                TEXT        NOT NULL,
    code_presentation          TEXT        NOT NULL,
    module_presentation_length INTEGER     NOT NULL,
    CONSTRAINT pk_courses PRIMARY KEY (code_module, code_presentation)
);

-- 2. assessments
-- Grain: One assessment record within a module presentation
-- date remains TEXT because source missing/placeholder values were observed.
-- weight uses NUMERIC because real decimal values were observed.
CREATE TABLE raw.assessments (
    code_module       TEXT    NOT NULL,
    code_presentation TEXT    NOT NULL,
    id_assessment     INTEGER NOT NULL,
    assessment_type   TEXT    NOT NULL,
    date              TEXT,
    weight            NUMERIC NOT NULL,
    CONSTRAINT pk_assessments PRIMARY KEY (id_assessment)
);

-- 3. student_info
-- Grain: One student in one module presentation
CREATE TABLE raw.student_info (
    code_module           TEXT    NOT NULL,
    code_presentation     TEXT    NOT NULL,
    id_student            INTEGER NOT NULL,
    gender                TEXT    NOT NULL,
    region                TEXT    NOT NULL,
    highest_education     TEXT    NOT NULL,
    imd_band              TEXT,
    age_band              TEXT    NOT NULL,
    num_of_prev_attempts  INTEGER NOT NULL,
    studied_credits       INTEGER NOT NULL,
    disability            TEXT    NOT NULL,
    final_result          TEXT    NOT NULL,
    CONSTRAINT pk_student_info PRIMARY KEY
        (code_module, code_presentation, id_student)
);

-- 4. student_registration
-- Grain: One registration record for one student in one presentation
CREATE TABLE raw.student_registration (
    code_module       TEXT    NOT NULL,
    code_presentation TEXT    NOT NULL,
    id_student        INTEGER NOT NULL,
    date_registration TEXT,
    date_unregistration TEXT,
    CONSTRAINT pk_student_registration PRIMARY KEY
        (code_module, code_presentation, id_student)
);

-- 5. student_assessment
-- Grain: One student's submission for one assessment
-- score remains TEXT because the source contains '?' placeholders.
CREATE TABLE raw.student_assessment (
    id_assessment  INTEGER NOT NULL,
    id_student     INTEGER NOT NULL,
    date_submitted INTEGER NOT NULL,
    is_banked      INTEGER NOT NULL,
    score          TEXT,
    CONSTRAINT pk_student_assessment PRIMARY KEY (id_assessment, id_student)
);

-- 6. vle
-- Grain: One VLE resource/site within a module presentation
CREATE TABLE raw.vle (
    id_site           INTEGER NOT NULL,
    code_module       TEXT    NOT NULL,
    code_presentation TEXT    NOT NULL,
    activity_type     TEXT    NOT NULL,
    week_from         TEXT,
    week_to           TEXT,
    CONSTRAINT pk_vle PRIMARY KEY (id_site)
);

-- 7. student_vle
-- Grain: One recorded student interaction with one VLE site on one day.
-- No primary key: the validated candidate key is not unique in the source.
CREATE TABLE raw.student_vle (
    code_module       TEXT    NOT NULL,
    code_presentation TEXT    NOT NULL,
    id_student        INTEGER NOT NULL,
    id_site           INTEGER NOT NULL,
    date              INTEGER NOT NULL,
    sum_click         INTEGER NOT NULL
);

-- Verification
SELECT schemaname, tablename, tableowner
FROM pg_tables
WHERE schemaname = 'raw'
ORDER BY tablename;

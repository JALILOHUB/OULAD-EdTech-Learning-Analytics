-- Purpose: Create RAW tables using source-oriented columns and validated PostgreSQL types.
-- RAW preserves source values and placeholders; no business transformation is applied.
-- Project Owner & Lead Analyst: Abdeljalil El Khyati
-- Date: 2026-10-06
-- Do not DROP or recreate these tables without an explicit schema-change decision.

CREATE TABLE raw.courses (
    code_module TEXT NOT NULL,
    code_presentation TEXT NOT NULL,
    module_presentation_length INTEGER NOT NULL,
    CONSTRAINT pk_courses PRIMARY KEY (code_module, code_presentation)
);

CREATE TABLE raw.assessments (
    code_module TEXT NOT NULL,
    code_presentation TEXT NOT NULL,
    id_assessment INTEGER NOT NULL,
    assessment_type TEXT NOT NULL,
    date TEXT,
    weight NUMERIC NOT NULL,
    CONSTRAINT pk_assessments PRIMARY KEY (id_assessment)
);

CREATE TABLE raw.student_info (
    code_module TEXT NOT NULL,
    code_presentation TEXT NOT NULL,
    id_student INTEGER NOT NULL,
    gender TEXT NOT NULL,
    region TEXT NOT NULL,
    highest_education TEXT NOT NULL,
    imd_band TEXT,
    age_band TEXT NOT NULL,
    num_of_prev_attempts INTEGER NOT NULL,
    studied_credits INTEGER NOT NULL,
    disability TEXT NOT NULL,
    final_result TEXT NOT NULL,
    CONSTRAINT pk_student_info PRIMARY KEY
        (code_module, code_presentation, id_student)
);

CREATE TABLE raw.student_registration (
    code_module TEXT NOT NULL,
    code_presentation TEXT NOT NULL,
    id_student INTEGER NOT NULL,
    date_registration TEXT,
    date_unregistration TEXT,
    CONSTRAINT pk_student_registration PRIMARY KEY
        (code_module, code_presentation, id_student)
);

CREATE TABLE raw.student_assessment (
    id_assessment INTEGER NOT NULL,
    id_student INTEGER NOT NULL,
    date_submitted INTEGER NOT NULL,
    is_banked INTEGER NOT NULL,
    score TEXT,
    CONSTRAINT pk_student_assessment PRIMARY KEY (id_assessment, id_student)
);

CREATE TABLE raw.vle (
    id_site INTEGER NOT NULL,
    code_module TEXT NOT NULL,
    code_presentation TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    week_from TEXT,
    week_to TEXT,
    CONSTRAINT pk_vle PRIMARY KEY (id_site)
);

CREATE TABLE raw.student_vle (
    code_module TEXT NOT NULL,
    code_presentation TEXT NOT NULL,
    id_student INTEGER NOT NULL,
    id_site INTEGER NOT NULL,
    date INTEGER NOT NULL,
    sum_click INTEGER NOT NULL
);

-- student_vle intentionally has no primary key because the tested five-column
-- candidate key is not unique in the source data.

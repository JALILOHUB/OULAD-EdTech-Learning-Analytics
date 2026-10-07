# OULAD Data Dictionary

**Project Owner & Lead Analyst:** Abdeljalil El Khyati

**Project:** OULAD — EdTech Learning Analytics  
**Source:** Open University Learning Analytics Dataset (OULAD), acquired reproducibly through UCI Machine Learning Repository Dataset 349  
**Status:** Phase 2C — RAW schema created and source data loaded  
**Last Updated:** 2026-10-06

## Dictionary Rules

- Definitions describe the source-level meaning before analytical transformation.
- RAW preserves source column names and source values.
- PostgreSQL types below reflect the validated RAW design, not necessarily the final STAGING types.
- Candidate keys were validated before primary-key constraints were applied.
- `student_vle` has no RAW primary key because its validated candidate key is not unique.

## 1. `courses`

**Grain:** One module presentation.  
**Candidate / Primary Key:** `(code_module, code_presentation)`  
**Rows:** 22

| Column | PostgreSQL type | Nullable | English | العربية | Français |
|---|---|---|---|---|---|
| `code_module` | TEXT | No | Module code | رمز الوحدة | Code du module |
| `code_presentation` | TEXT | No | Presentation code / period | رمز الدورة / الفترة | Code de la présentation / période |
| `module_presentation_length` | INTEGER | No | Length of the presentation in days | مدة الدورة بالأيام | Durée de la présentation en jours |

## 2. `assessments`

**Grain:** One assessment record within a module presentation.  
**Candidate / Primary Key:** `id_assessment`  
**Rows:** 206

| Column | PostgreSQL type | Nullable | English | العربية | Français |
|---|---|---|---|---|---|
| `code_module` | TEXT | No | Module code | رمز الوحدة | Code du module |
| `code_presentation` | TEXT | No | Presentation code / period | رمز الدورة / الفترة | Code de la présentation / période |
| `id_assessment` | INTEGER | No | Assessment identifier | معرّف التقييم | Identifiant de l'évaluation |
| `assessment_type` | TEXT | No | Assessment type | نوع التقييم | Type d'évaluation |
| `date` | TEXT | Yes | Assessment date / source day value | تاريخ التقييم / قيمة اليوم في المصدر | Date de l'évaluation / valeur du jour dans la source |
| `weight` | NUMERIC | No | Assessment weight as a percentage | وزن التقييم كنسبة مئوية | Pondération de l'évaluation en pourcentage |

`weight` was validated to contain real decimal values, including 7.5, 12.5 and 17.5; therefore RAW uses `NUMERIC`.

## 3. `student_info`

**Grain:** One student in one module presentation.  
**Candidate / Primary Key:** `(code_module, code_presentation, id_student)`  
**Rows:** 32,593

| Column | PostgreSQL type | Nullable | English | العربية | Français |
|---|---|---|---|---|---|
| `code_module` | TEXT | No | Module code | رمز الوحدة | Code du module |
| `code_presentation` | TEXT | No | Presentation code / period | رمز الدورة / الفترة | Code de la présentation / période |
| `id_student` | INTEGER | No | Student identifier | معرّف الطالب | Identifiant de l'étudiant |
| `gender` | TEXT | No | Gender category in source | فئة الجنس في المصدر | Catégorie de sexe dans la source |
| `region` | TEXT | No | Student region | منطقة الطالب | Région de l'étudiant |
| `highest_education` | TEXT | No | Highest education level | أعلى مستوى تعليمي | Niveau d'études le plus élevé |
| `imd_band` | TEXT | Yes | IMD band | فئة مؤشر الحرمان | Tranche IMD |
| `age_band` | TEXT | No | Age band | الفئة العمرية | Tranche d'âge |
| `num_of_prev_attempts` | INTEGER | No | Number of previous attempts | عدد المحاولات السابقة | Nombre de tentatives précédentes |
| `studied_credits` | INTEGER | No | Credits studied | عدد الاعتمادات الدراسية | Nombre de crédits étudiés |
| `disability` | TEXT | No | Disability indicator | مؤشر الإعاقة | Indicateur de handicap |
| `final_result` | TEXT | No | Final result | النتيجة النهائية | Résultat final |

## 4. `student_registration`

**Grain:** One registration record for one student in one module presentation.  
**Candidate / Primary Key:** `(code_module, code_presentation, id_student)`  
**Rows:** 32,593

| Column | PostgreSQL type | Nullable | English | العربية | Français |
|---|---|---|---|---|---|
| `code_module` | TEXT | No | Module code | رمز الوحدة | Code du module |
| `code_presentation` | TEXT | No | Presentation code / period | رمز الدورة / الفترة | Code de la présentation / période |
| `id_student` | INTEGER | No | Student identifier | معرّف الطالب | Identifiant de l'étudiant |
| `date_registration` | TEXT | Yes | Registration day value | قيمة يوم التسجيل | Valeur du jour d'inscription |
| `date_unregistration` | TEXT | Yes | Unregistration day value | قيمة يوم إلغاء التسجيل | Valeur du jour de désinscription |

The registration date fields remain nullable `TEXT` in RAW because source missing values/placeholders were observed.

## 5. `student_assessment`

**Grain:** One student's submission for one assessment.  
**Candidate / Primary Key:** `(id_assessment, id_student)`  
**Rows:** 173,912

| Column | PostgreSQL type | Nullable | English | العربية | Français |
|---|---|---|---|---|---|
| `id_assessment` | INTEGER | No | Assessment identifier | معرّف التقييم | Identifiant de l'évaluation |
| `id_student` | INTEGER | No | Student identifier | معرّف الطالب | Identifiant de l'étudiant |
| `date_submitted` | INTEGER | No | Submission day value | قيمة يوم التسليم | Valeur du jour de soumission |
| `is_banked` | INTEGER | No | Banked submission indicator | مؤشر التقييم المحفوظ | Indicateur de soumission conservée |
| `score` | TEXT | Yes | Assessment score | درجة التقييم | Score de l'évaluation |

`score` contains 173 source `?` placeholders. Although valid numeric values are integer-valued, RAW uses nullable `TEXT` to preserve the source representation.

## 6. `vle`

**Grain:** One VLE resource/site within a module presentation.  
**Candidate / Primary Key:** `id_site`  
**Rows:** 6,364

| Column | PostgreSQL type | Nullable | English | العربية | Français |
|---|---|---|---|---|---|
| `id_site` | INTEGER | No | VLE site identifier | معرّف موقع VLE | Identifiant du site VLE |
| `code_module` | TEXT | No | Module code | رمز الوحدة | Code du module |
| `code_presentation` | TEXT | No | Presentation code / period | رمز الدورة / الفترة | Code de la présentation / période |
| `activity_type` | TEXT | No | Activity/resource type | نوع النشاط / المورد | Type d'activité / ressource |
| `week_from` | TEXT | Yes | Starting week value | قيمة أسبوع البداية | Valeur de la semaine de début |
| `week_to` | TEXT | Yes | Ending week value | قيمة أسبوع النهاية | Valeur de la semaine de fin |

## 7. `student_vle`

**Grain:** One recorded student interaction with one VLE site on one day.  
**Candidate Key Tested:** `(code_module, code_presentation, id_student, id_site, date)`  
**Rows:** 10,655,280  
**Unique candidate-key combinations:** 8,459,320  
**Duplicate rows under this candidate key:** 2,195,960  
**RAW Primary Key:** None by design

| Column | PostgreSQL type | Nullable | English | العربية | Français |
|---|---|---|---|---|---|
| `code_module` | TEXT | No | Module code | رمز الوحدة | Code du module |
| `code_presentation` | TEXT | No | Presentation code / period | رمز الدورة / الفترة | Code de la présentation / période |
| `id_student` | INTEGER | No | Student identifier | معرّف الطالب | Identifiant de l'étudiant |
| `id_site` | INTEGER | No | VLE site identifier | معرّف موقع VLE | Identifiant du site VLE |
| `date` | INTEGER | No | Interaction day value | قيمة يوم التفاعل | Valeur du jour de l'interaction |
| `sum_click` | INTEGER | No | Recorded click count | عدد النقرات المسجلة | Nombre de clics enregistrés |

The duplicate structure has been detected but not yet interpreted. No aggregation rule such as `SUM(sum_click)` is assumed at this stage. Duplicate characterization is the next RAW/STAGING decision gate.

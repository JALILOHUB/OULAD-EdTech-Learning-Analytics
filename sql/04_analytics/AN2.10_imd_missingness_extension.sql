-- Question: Is missing imd_band concentrated by module or region-by-presentation, and can it be recovered from the same person in another presentation?
-- Expectation: Missingness is concentrated in some regions and modules (historical North Region 40.10%, Ireland 22.47%); some missing rows may have alternative values elsewhere. These are hypotheses until the output is read.
-- Grain: Statement 1 = module; statement 2 = every region/module/presentation group with at least one missing IMD value; statement 3 = recovery class (rows and distinct students). The missing-row total should be reconciled to the historical 1,111-row baseline, while treating it as a historical reference rather than a forced result.
-- Source: staging.student_info.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: No imputation is approved here. A value in another presentation does not prove the IMD of this presentation; a conflicting class must never be resolved by picking one value. Descriptive concentration does not establish a missingness mechanism.

-- 1. IMD missingness by module.
SELECT code_module,
       COUNT(*)::BIGINT AS student_presentation_rows,
       COUNT(*) FILTER (WHERE imd_band IS NULL)::BIGINT AS imd_missing_rows,
       ROUND(100.0 * COUNT(*) FILTER (WHERE imd_band IS NULL) / COUNT(*), 2) AS pct_imd_missing
FROM staging.student_info
GROUP BY code_module
ORDER BY pct_imd_missing DESC, code_module;

-- 2. IMD missingness by every region and presentation with at least one missing value; retain the full group denominator.
SELECT region,
       code_module,
       code_presentation,
       COUNT(*)::BIGINT AS rows_total,
       COUNT(*) FILTER (WHERE imd_band IS NULL)::BIGINT AS imd_missing_rows,
       ROUND(100.0 * COUNT(*) FILTER (WHERE imd_band IS NULL) / COUNT(*), 2) AS pct_imd_missing
FROM staging.student_info
GROUP BY region, code_module, code_presentation
HAVING COUNT(*) FILTER (WHERE imd_band IS NULL) > 0
ORDER BY region NULLS LAST, pct_imd_missing DESC, code_module, code_presentation;

-- 3. Classify missing rows by availability of an IMD value for the same student in another module-presentation.
-- A different presentation label alone is insufficient: compare the full module-presentation pair.
WITH missing_rows AS (
    SELECT code_module, code_presentation, id_student
    FROM staging.student_info
    WHERE imd_band IS NULL
),
alternatives AS (
    SELECT m.id_student,
           m.code_module,
           m.code_presentation,
           COUNT(DISTINCT si.imd_band)::BIGINT AS distinct_alternative_values
    FROM missing_rows AS m
    JOIN staging.student_info AS si
      ON si.id_student = m.id_student
     AND (si.code_module, si.code_presentation)
         <> (m.code_module, m.code_presentation)
     AND si.imd_band IS NOT NULL
    GROUP BY m.id_student, m.code_module, m.code_presentation
),
classified AS (
    SELECT m.id_student,
           CASE
               WHEN a.id_student IS NULL THEN 'NO_ALTERNATIVE_VALUE'
               WHEN a.distinct_alternative_values = 1 THEN 'CONSISTENT_ALTERNATIVE'
               ELSE 'CONFLICTING_ALTERNATIVES'
           END AS recovery_class
    FROM missing_rows AS m
    LEFT JOIN alternatives AS a
      ON a.id_student = m.id_student
     AND a.code_module = m.code_module
     AND a.code_presentation = m.code_presentation
)
SELECT recovery_class,
       COUNT(*)::BIGINT AS missing_rows,
       COUNT(DISTINCT id_student)::BIGINT AS distinct_students,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_missing_rows,
       SUM(COUNT(*)) OVER ()::BIGINT AS total_missing_rows
FROM classified
GROUP BY recovery_class
ORDER BY recovery_class;

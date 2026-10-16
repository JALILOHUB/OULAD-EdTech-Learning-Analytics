-- Purpose: Characterize repeated student_vle candidate keys without modifying data.
-- Some statements scan the 10.6M-row table and may take several minutes.
-- Execute each SELECT separately. Do not delete or aggregate rows based only on these results.

-- 1. Summarize repeated candidate-key groups and whether sum_click varies within each group.
WITH key_groups AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           COUNT(*) AS row_count,
           COUNT(DISTINCT sum_click) AS distinct_sum_click_values
    FROM raw.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
    HAVING COUNT(*) > 1
)
SELECT COUNT(*) AS duplicate_key_groups,
       SUM(row_count) AS rows_in_duplicate_groups,
       SUM(row_count - 1) AS excess_rows,
       COUNT(*) FILTER (WHERE distinct_sum_click_values = 1) AS groups_with_same_sum_click,
       COUNT(*) FILTER (WHERE distinct_sum_click_values > 1) AS groups_with_different_sum_click,
       MAX(row_count) AS largest_group_size
FROM key_groups;

-- 2. Count fully identical six-column row groups.
WITH full_row_groups AS (
    SELECT code_module, code_presentation, id_student, id_site, date, sum_click,
           COUNT(*) AS row_count
    FROM raw.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date, sum_click
    HAVING COUNT(*) > 1
)
SELECT COUNT(*) AS repeated_full_row_groups,
       SUM(row_count) AS rows_in_repeated_full_row_groups,
       SUM(row_count - 1) AS excess_identical_rows
FROM full_row_groups;

-- 3. Distribution of repeated-key group sizes.
WITH key_groups AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           COUNT(*) AS group_size
    FROM raw.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
    HAVING COUNT(*) > 1
)
SELECT group_size,
       COUNT(*) AS number_of_groups,
       SUM(group_size) AS rows_in_groups,
       SUM(group_size - 1) AS excess_rows
FROM key_groups
GROUP BY group_size
ORDER BY group_size;

-- 4. Example key groups with more than one distinct sum_click value.
-- These samples demonstrate variation, not the cause or intended business grain.
WITH click_value_groups AS (
    SELECT code_module, code_presentation, id_student, id_site, date,
           sum_click, COUNT(*) AS occurrences
    FROM raw.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date, sum_click
), varying_keys AS (
    SELECT code_module, code_presentation, id_student, id_site, date
    FROM click_value_groups
    GROUP BY code_module, code_presentation, id_student, id_site, date
    HAVING COUNT(*) > 1
)
SELECT g.code_module, g.code_presentation, g.id_student, g.id_site,
       g.date, g.sum_click, g.occurrences
FROM click_value_groups g
JOIN varying_keys v USING (code_module, code_presentation, id_student, id_site, date)
ORDER BY g.code_module, g.code_presentation, g.id_student, g.id_site, g.date, g.sum_click
LIMIT 100;

-- 5. Sample fully identical rows for context.
WITH repeated_rows AS (
    SELECT code_module, code_presentation, id_student, id_site, date, sum_click,
           COUNT(*) AS occurrences
    FROM raw.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date, sum_click
    HAVING COUNT(*) > 1
)
SELECT code_module, code_presentation, id_student, id_site, date, sum_click, occurrences
FROM repeated_rows
ORDER BY occurrences DESC
LIMIT 30;

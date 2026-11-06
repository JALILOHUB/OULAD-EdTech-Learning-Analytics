-- Question: How stable are student-presentation activity rankings under R0, R1, and R2, and how much do pairwise ranks and top-decile membership change?
-- Expectation: Each scenario ranks the same registered student-presentation population within each module-presentation. Ties receive average ranks; top-decile cutoffs include all ties at the boundary.
-- Grain: One row per module-presentation and scenario pair (R0/R1, R0/R2, R1/R2).
-- Source: staging.student_vle, staging.student_registration.
-- Safety: READ-ONLY. R0/R1/R2 are virtual query transformations. No source rows or database objects are modified.
-- Runtime: HIGH. Three scenario aggregations scan the 10.6M-row activity table. Run alone with statement_timeout_ms=600000.
-- Read as: Rank stability is evaluated within each presentation, not across pooled presentations. Zero-activity registrations remain in the ranking population. Spearman correlation is computed from average ranks. Top-decile membership includes all ties at the cutoff and may therefore exceed exactly 10%.

-- 1. Create scenario-specific recorded-click totals at student-presentation grain.
WITH registered_population AS (
    SELECT code_module, code_presentation, id_student
    FROM staging.student_registration
),
scenario_rows AS (
    SELECT 'R0'::TEXT AS scenario,
           code_module, code_presentation, id_student, id_site, date, sum_click
    FROM staging.student_vle

    UNION ALL

    SELECT 'R1'::TEXT,
           code_module, code_presentation, id_student, id_site, date, sum_click
    FROM (
        SELECT DISTINCT code_module, code_presentation, id_student, id_site, date, sum_click
        FROM staging.student_vle
    ) AS exact_rows

    UNION ALL

    SELECT 'R2'::TEXT,
           code_module, code_presentation, id_student, id_site, date, MAX(sum_click) AS sum_click
    FROM staging.student_vle
    GROUP BY code_module, code_presentation, id_student, id_site, date
),
student_activity AS (
    SELECT scenario, code_module, code_presentation, id_student,
           SUM(sum_click)::NUMERIC AS recorded_sum_click
    FROM scenario_rows
    GROUP BY scenario, code_module, code_presentation, id_student
),
scenario_population AS (
    SELECT s.scenario, r.code_module, r.code_presentation, r.id_student,
           COALESCE(a.recorded_sum_click, 0)::NUMERIC AS recorded_sum_click
    FROM registered_population AS r
    CROSS JOIN (VALUES ('R0'::TEXT), ('R1'::TEXT), ('R2'::TEXT)) AS s(scenario)
    LEFT JOIN student_activity AS a
      ON a.scenario = s.scenario
     AND a.code_module = r.code_module
     AND a.code_presentation = r.code_presentation
     AND a.id_student = r.id_student
),
ranked AS (
    SELECT scenario, code_module, code_presentation, id_student, recorded_sum_click,
           RANK() OVER (
               PARTITION BY scenario, code_module, code_presentation
               ORDER BY recorded_sum_click DESC
           )::NUMERIC AS competition_rank,
           COUNT(*) OVER (
               PARTITION BY scenario, code_module, code_presentation
           )::BIGINT AS population_size,
           COUNT(*) OVER (
               PARTITION BY scenario, code_module, code_presentation, recorded_sum_click
           )::BIGINT AS tie_size
    FROM scenario_population
),
average_ranked AS (
    SELECT scenario, code_module, code_presentation, id_student,
           recorded_sum_click, population_size,
           competition_rank + ((tie_size - 1)::NUMERIC / 2.0) AS average_rank,
           (competition_rank <= CEIL(population_size * 0.10)) AS in_top_decile
    FROM ranked
),
scenario_pairs AS (
    SELECT code_module, code_presentation, id_student,
           MAX(population_size) AS population_size,
           MAX(average_rank) FILTER (WHERE scenario = 'R0') AS rank_r0,
           MAX(average_rank) FILTER (WHERE scenario = 'R1') AS rank_r1,
           MAX(average_rank) FILTER (WHERE scenario = 'R2') AS rank_r2,
           BOOL_OR(in_top_decile) FILTER (WHERE scenario = 'R0') AS top_r0,
           BOOL_OR(in_top_decile) FILTER (WHERE scenario = 'R1') AS top_r1,
           BOOL_OR(in_top_decile) FILTER (WHERE scenario = 'R2') AS top_r2
    FROM average_ranked
    GROUP BY code_module, code_presentation, id_student
),
pairwise AS (
    SELECT code_module, code_presentation, population_size,
           'R0'::TEXT AS scenario_a, 'R1'::TEXT AS scenario_b,
           rank_r0 AS rank_a, rank_r1 AS rank_b,
           top_r0 AS top_a, top_r1 AS top_b
    FROM scenario_pairs
    UNION ALL
    SELECT code_module, code_presentation, population_size,
           'R0', 'R2', rank_r0, rank_r2, top_r0, top_r2
    FROM scenario_pairs
    UNION ALL
    SELECT code_module, code_presentation, population_size,
           'R1', 'R2', rank_r1, rank_r2, top_r1, top_r2
    FROM scenario_pairs
)
-- 2. Quantify rank correlation, rank displacement, and top-decile overlap within each presentation.
SELECT code_module, code_presentation, scenario_a, scenario_b,
       MAX(population_size)::BIGINT AS registered_student_presentations,
       COUNT(*)::BIGINT AS paired_student_presentations,
       ROUND(corr(rank_a::DOUBLE PRECISION, rank_b::DOUBLE PRECISION)::NUMERIC, 6)
           AS spearman_rank_correlation,
       COUNT(*) FILTER (WHERE rank_a <> rank_b)::BIGINT AS student_presentations_with_rank_change,
       ROUND(AVG(ABS(rank_a - rank_b)), 2) AS mean_absolute_rank_change,
       ROUND((percentile_cont(0.50) WITHIN GROUP (ORDER BY ABS(rank_a - rank_b)))::NUMERIC, 2)
           AS median_absolute_rank_change,
       ROUND((percentile_cont(0.90) WITHIN GROUP (ORDER BY ABS(rank_a - rank_b)))::NUMERIC, 2)
           AS p90_absolute_rank_change,
       MAX(ABS(rank_a - rank_b)) AS maximum_absolute_rank_change,
       COUNT(*) FILTER (WHERE top_a)::BIGINT AS top_decile_count_a,
       COUNT(*) FILTER (WHERE top_b)::BIGINT AS top_decile_count_b,
       COUNT(*) FILTER (WHERE top_a AND top_b)::BIGINT AS top_decile_overlap,
       COUNT(*) FILTER (WHERE top_a OR top_b)::BIGINT AS top_decile_union,
       ROUND(
           COUNT(*) FILTER (WHERE top_a AND top_b)::NUMERIC
           / NULLIF(COUNT(*) FILTER (WHERE top_a OR top_b), 0),
           4
       ) AS top_decile_jaccard
FROM pairwise
GROUP BY code_module, code_presentation, scenario_a, scenario_b
ORDER BY code_module, code_presentation, scenario_a, scenario_b;

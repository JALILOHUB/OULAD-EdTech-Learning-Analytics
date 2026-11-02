-- Question: Are there impossible or edge-case date orderings (unregistered before registering, same day, before start)?
-- Expectation: Few or no unregistration-before-registration rows; some same-day rows; many pre-start unregistrations.
-- Grain: One row per ordering category.
-- Source: staging.student_registration.
-- Safety: READ-ONLY
-- Runtime: Low.
-- Read as: BEFORE_REGISTRATION rows are data-quality candidates. SAME_DAY rows are legitimate but must be kept out of "time enrolled" averages (zero duration).
SELECT CASE
           WHEN date_unregistration IS NULL THEN 'NO_UNREGISTRATION'
           WHEN date_registration IS NULL THEN 'REGISTRATION_DATE_MISSING'
           WHEN date_unregistration < date_registration THEN 'BEFORE_REGISTRATION'
           WHEN date_unregistration = date_registration THEN 'SAME_DAY'
           ELSE 'AFTER_REGISTRATION'
       END AS ordering_category,
       COUNT(*)::BIGINT AS rows_in_category,
       MIN(date_unregistration - date_registration) AS min_days_enrolled,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY date_unregistration - date_registration) AS median_days_enrolled,
       MAX(date_unregistration - date_registration) AS max_days_enrolled
FROM staging.student_registration
GROUP BY 1
ORDER BY 1;

# ANALYTICS SQL Layer

**Current status:** Analytical views have not yet been implemented.

This folder will hold validated, business-facing SQL views and transformations built from STAGING. Initial themes may include student engagement, academic performance, retention, and transparent risk indicators.

Before creating a query or view:

1. State the business question.
2. Define the output grain.
3. Identify and justify join paths.
4. Define measures, denominators, exclusions, and time basis.
5. Validate the result against source-level counts or independent SQL checks.
6. Record decisions and limitations in `docs/analysis_log.md`.

Do not begin by aggregating `student_vle` until the repeated-key issue has been accounted for in the proposed metric definition.

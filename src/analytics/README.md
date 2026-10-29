# Analytics Utilities and Advanced Analysis

**Current status:** The read-only SQL query runner has been used by the saved WO-1 notebook to execute diagnostic SQL in a prior local session. No advanced statistical result or predictive model has been produced yet.

## SQL execution support

- `db.py` opens a new PostgreSQL connection for each canonical analytical SQL file.
- The connection sets read-only transaction mode, a 120-second statement timeout, and a 5-second lock timeout.
- Queries are resolved by stable work-order ID, such as `AN0.01`; SQL files remain the source of truth.
- Returned results are limited to a configurable number of rows and include the SQL path and elapsed time.
- Credentials are read from the local `.env` file and are never printed.

## Advanced analysis

This area is reserved for work that benefits from Python after analytical questions, table grain, join logic, and SQL metric definitions are established. Possible future tasks include statistical tests, careful distribution analysis, segmentation, feature engineering, and predictive modelling if justified.

Machine learning is optional, not a goal in itself. Any model must have a clear use case, baseline, leakage-aware evaluation design, interpretable limitations, and a documented link to the business question.

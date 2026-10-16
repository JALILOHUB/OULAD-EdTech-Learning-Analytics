# Configuration

Keep only safe, non-secret templates in this folder.

* `.env.example` may contain variable names and clearly marked placeholders.
* Keep `.env`, passwords, tokens, private connection strings, and local-only database settings out of Git.
* Read local configuration through environment variables; do not hard-code credentials in Python notebooks or SQL files.

PostgreSQL is currently running locally. Configuration should remain portable and should not include machine-specific paths unless a local-only example is clearly labelled.




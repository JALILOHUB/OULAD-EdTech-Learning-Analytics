"""Import the seven OULAD CSVs into oulad_an8_work.source_ref without coercion."""

from __future__ import annotations

import argparse
import csv
import hashlib
import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
WORKING_RAW = ROOT / "data" / "working" / "raw"
BACKUP_RAW = ROOT / "data" / "Backup" / "raw"
MANIFEST_PATH = ROOT / "data" / "Backup" / "backup_manifest.csv"
TARGET_DATABASE = "oulad_an8_work"

FILES = {
    "courses.csv": {
        "table": "courses",
        "rows": 22,
        "columns": [
            "code_module", "code_presentation", "module_presentation_length"
        ],
    },
    "assessments.csv": {
        "table": "assessments",
        "rows": 206,
        "columns": [
            "code_module", "code_presentation", "id_assessment",
            "assessment_type", "date", "weight"
        ],
    },
    "studentInfo.csv": {
        "table": "student_info",
        "rows": 32593,
        "columns": [
            "id_student", "code_module", "code_presentation", "gender",
            "region", "highest_education", "imd_band", "age_band",
            "num_of_prev_attempts", "studied_credits", "disability",
            "final_result"
        ],
    },
    "studentRegistration.csv": {
        "table": "student_registration",
        "rows": 32593,
        "columns": [
            "id_student", "code_module", "code_presentation",
            "date_registration", "date_unregistration"
        ],
    },
    "studentAssessment.csv": {
        "table": "student_assessment",
        "rows": 173912,
        "columns": [
            "id_assessment", "id_student", "date_submitted", "is_banked", "score"
        ],
    },
    "vle.csv": {
        "table": "vle",
        "rows": 6364,
        "columns": [
            "id_site", "code_module", "code_presentation",
            "activity_type", "week_from", "week_to"
        ],
    },
    "studentVle.csv": {
        "table": "student_vle",
        "rows": 10655280,
        "columns": [
            "code_module", "code_presentation", "id_student",
            "id_site", "date", "sum_click"
        ],
    },
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def read_manifest() -> dict[str, dict[str, str]]:
    if not MANIFEST_PATH.is_file():
        raise FileNotFoundError(f"Backup manifest not found: {MANIFEST_PATH}")

    with MANIFEST_PATH.open("r", encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))

    manifest: dict[str, dict[str, str]] = {}
    for row in rows:
        name = Path(row["RelativePath"]).name
        if name in manifest:
            raise ValueError(f"Duplicate manifest entry for {name}")
        manifest[name] = row

    expected_names = set(FILES) | {"oulad_dataset.zip"}
    if set(manifest) != expected_names:
        raise ValueError(
            "Manifest inventory mismatch. "
            f"Expected {sorted(expected_names)}, found {sorted(manifest)}"
        )

    for name, row in manifest.items():
        if row.get("SourceExists", "").strip().lower() not in {"true", "1"}:
            raise ValueError(f"Manifest does not confirm original source for {name}")
        if row.get("SHA256", "").upper() != row.get("SourceSHA256", "").upper():
            raise ValueError(f"Backup/source manifest hashes differ for {name}")

    return manifest


def validate_inputs() -> list[tuple[str, Path, str]]:
    manifest = read_manifest()
    validated = []

    for filename, spec in FILES.items():
        working_file = WORKING_RAW / filename
        backup_file = BACKUP_RAW / filename

        if not working_file.is_file() or not backup_file.is_file():
            raise FileNotFoundError(f"Missing working or backup file: {filename}")

        expected_hash = manifest[filename]["SourceSHA256"].upper()
        working_hash = sha256_file(working_file)
        backup_hash = sha256_file(backup_file)

        if working_hash != expected_hash or backup_hash != expected_hash:
            raise ValueError(
                f"SHA-256 mismatch for {filename}; import stopped before database access."
            )

        with working_file.open("r", encoding="utf-8-sig", newline="") as stream:
            reader = csv.reader(stream)
            header = next(reader, None)

        if header != spec["columns"]:
            raise ValueError(
                f"Header mismatch in {filename}. "
                f"Expected {spec['columns']}; found {header}"
            )

        validated.append((filename, working_file, working_hash))

    return validated


def connect_to_work_database() -> psycopg.Connection:
    load_dotenv(ROOT / ".env", override=False)
    password = os.getenv("DB_PASSWORD")
    if not password or password == "CHANGE_ME":
        raise RuntimeError("DB_PASSWORD is missing or still set to CHANGE_ME.")

    connection = psycopg.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        user=os.getenv("DB_USER", "postgres"),
        password=password,
        dbname=TARGET_DATABASE,
        autocommit=False,
    )
    with connection.cursor() as cursor:
        cursor.execute("SELECT current_database()")
        actual_database = cursor.fetchone()[0]
    if actual_database != TARGET_DATABASE:
        connection.close()
        raise RuntimeError(
            f"Safety stop: connected to {actual_database}, not {TARGET_DATABASE}."
        )
    return connection


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate and import source CSVs into oulad_an8_work.source_ref."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate manifest hashes and CSV headers without connecting to PostgreSQL.",
    )
    args = parser.parse_args()

    validated = validate_inputs()
    print("Input validation passed:")
    for filename, path, digest in validated:
        print(f"  {filename}: SHA256={digest} | {path.stat().st_size:,} bytes")

    if args.dry_run:
        print("DRY RUN: no PostgreSQL connection or database changes were made.")
        return

    connection = connect_to_work_database()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SET LOCAL statement_timeout = 0")
            cursor.execute("SET LOCAL lock_timeout = '5s'")

            expected_tables = {spec["table"] for spec in FILES.values()}
            cursor.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'source_ref'
                  AND table_type = 'BASE TABLE'
                """
            )
            actual_tables = {row[0] for row in cursor.fetchall()}
            if actual_tables != expected_tables:
                raise RuntimeError(
                    "source_ref table inventory mismatch. "
                    f"Expected {sorted(expected_tables)}, found {sorted(actual_tables)}"
                )

            for table in sorted(expected_tables):
                cursor.execute(f"SELECT EXISTS (SELECT 1 FROM source_ref.{table} LIMIT 1)")
                if cursor.fetchone()[0]:
                    raise RuntimeError(
                        f"source_ref.{table} is not empty. No table was overwritten; "
                        "inspect the database before deciding how to proceed."
                    )

            for filename, path, _digest in validated:
                table = FILES[filename]["table"]
                columns = ", ".join(FILES[filename]["columns"])
                copy_sql = (
                    f"COPY source_ref.{table} ({columns}) "
                    "FROM STDIN WITH (FORMAT CSV, HEADER TRUE, NULL '\\N', ENCODING 'UTF8')"
                )
                with path.open("rb") as source_stream:
                    with cursor.copy(copy_sql) as copy:
                        while chunk := source_stream.read(4 * 1024 * 1024):
                            copy.write(chunk)
                        copied_rows = copy.rows

                expected_rows = FILES[filename]["rows"]
                if copied_rows != expected_rows:
                    raise RuntimeError(
                        f"Row-count mismatch for {filename}: "
                        f"expected {expected_rows:,}, copied {copied_rows:,}. "
                        "The transaction will be rolled back."
                    )
                print(f"  Imported {filename}: {copied_rows:,} rows")

        connection.commit()
        print(
            "IMPORT COMMITTED to oulad_an8_work.source_ref. "
            "No source files or other databases were modified."
        )
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


if __name__ == "__main__":
    main()

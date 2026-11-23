#!/usr/bin/env python3
"""End-to-end orchestration for the RetailChurn data warehouse.

The warehouse is built from the versioned SQL scripts under
``DWH/RetailChurn/Source`` and targets Microsoft SQL Server (T-SQL).
Running ``python orchestration.py`` initialises the database and then
loads every layer in order::

    00_dwh -> 01_staging -> 02_bronze -> 03_silver -> 04_gold

Each layer function is split into three independent, sequentially executed
sub-steps (DDL, stored procedure creation, stored procedure execution), and
every sub-step owns its own ``try``/``except`` block so a failure reports the
exact layer and step that broke the pipeline.

Configuration is read from environment variables; see ``.env.example``.
"""

from __future__ import annotations

import logging
import os
import re
import sys
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator, Sequence

try:
    import pyodbc
except ImportError as exc:  # pragma: no cover - dependency guard
    raise SystemExit(
        "pyodbc is required. Install the dependencies first:\n"
        "    pip install -r Python/requirements.txt"
    ) from exc

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover - optional convenience
    def load_dotenv(*_args: object, **_kwargs: object) -> bool:
        """Fallback used when python-dotenv is not installed."""
        return False


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

PYTHON_DIR = Path(__file__).resolve().parent
REPO_ROOT = PYTHON_DIR.parent
SOURCE_DIR = REPO_ROOT / "DWH" / "RetailChurn" / "Source"

DWH_DIR = SOURCE_DIR / "00_dwh" / "ddl"
STAGING_DIR = SOURCE_DIR / "01_staging"
BRONZE_DIR = SOURCE_DIR / "02_bronze"
SILVER_DIR = SOURCE_DIR / "03_silver"
GOLD_DIR = SOURCE_DIR / "04_gold"

load_dotenv(REPO_ROOT / ".env")

# ---------------------------------------------------------------------------
# Configuration (environment variables with sensible local defaults)
# ---------------------------------------------------------------------------

DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 18 for SQL Server")
DB_SERVER = os.getenv("DB_SERVER", "localhost")
DATABASE = os.getenv("DB_NAME", "RetailChurn")
MASTER_DATABASE = os.getenv("DB_MASTER_DATABASE", "master")

DB_TRUSTED_CONNECTION = os.getenv("DB_TRUSTED_CONNECTION", "yes")
DB_USERNAME = os.getenv("DB_USERNAME", "")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_ENCRYPT = os.getenv("DB_ENCRYPT", "yes")
DB_TRUST_SERVER_CERTIFICATE = os.getenv("DB_TRUST_SERVER_CERTIFICATE", "yes")

DB_LOGIN_TIMEOUT = int(os.getenv("DB_LOGIN_TIMEOUT", "30"))
DB_QUERY_TIMEOUT = int(os.getenv("DB_QUERY_TIMEOUT", "0"))

DATA_DIR = Path(os.getenv("DATA_DIR", "Data")).expanduser()
if not DATA_DIR.is_absolute():
    DATA_DIR = (REPO_ROOT / DATA_DIR).resolve()

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()

# Staging procedures are the only ones that accept a parameter. The key is the
# fully qualified procedure name, the value is the CSV consumed by BULK INSERT.
STAGING_CSV_BY_PROCEDURE = {
    "staging.load_customers": "customer.csv",
    "staging.load_products": "product.csv",
    "staging.load_order_items": "order_items.csv",
    "staging.load_orders": "orders.csv",
}

logger = logging.getLogger("retailchurn.orchestration")

# ---------------------------------------------------------------------------
# SQL helpers
# ---------------------------------------------------------------------------

# A GO batch separator must be alone on its line (T-SQL allows an optional
# repeat count). It is *not* a SQL statement, so it is stripped before a
# batch is sent to the server.
_GO_SEPARATOR = re.compile(r"^GO(?:\s+\d+)?\s*;?\s*$", re.IGNORECASE)

_CREATE_PROCEDURE = re.compile(
    r"^\s*CREATE\s+(?:OR\s+ALTER\s+)?PROC(?:EDURE)?\s+"
    r"([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?)",
    re.IGNORECASE | re.MULTILINE,
)

_PROCEDURE_NAME = re.compile(r"^[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)?$")


class LayerStepError(RuntimeError):
    """Raised when a single layer sub-step fails; stops the whole pipeline."""

    def __init__(self, layer: str, substep: str, cause: BaseException) -> None:
        super().__init__(f"{layer} | {substep} | {type(cause).__name__}: {cause}")
        self.layer = layer
        self.substep = substep
        self.cause = cause


def _configure_logging() -> None:
    level = getattr(logging, LOG_LEVEL, logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s | %(levelname)-8s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        stream=sys.stdout,
        force=True,
    )


def _abort(layer: str, substep: str, exc: BaseException) -> None:
    """Log the failing layer/sub-step/exception and stop execution."""
    logger.error("-" * 78)
    logger.error("PIPELINE HALTED")
    logger.error("Layer     : %s", layer)
    logger.error("Sub-step  : %s", substep)
    logger.error("Exception : %s: %s", type(exc).__name__, exc)
    logger.error("-" * 78)
    raise LayerStepError(layer, substep, exc) from exc


def split_sql_batches(script: str) -> list[str]:
    """Split a T-SQL script on ``GO`` separators.

    ``GO`` is only recognised at the start of a line while outside string
    literals and comments, so values such as ``'GO'`` never split a batch.
    Line endings are normalised to ``\\n``.
    """
    batches: list[str] = []
    current: list[str] = []
    buffer: list[str] = []
    state = "code"  # code | string | line_comment | block_comment

    index = 0
    length = len(script)
    while index < length:
        char = script[index]
        following = script[index + 1] if index + 1 < length else ""

        if char == "\r":
            index += 1
            continue

        if state == "code":
            if char == "'":
                state = "string"
                buffer.append(char)
            elif char == "-" and following == "-":
                state = "line_comment"
                buffer.append(char)
                buffer.append(following)
                index += 1
            elif char == "/" and following == "*":
                state = "block_comment"
                buffer.append(char)
                buffer.append(following)
                index += 1
            elif char == "\n":
                line = "".join(buffer)
                if _GO_SEPARATOR.match(line.strip()):
                    batch = "".join(current).strip()
                    if batch:
                        batches.append(batch)
                    current = []
                else:
                    current.append(line)
                    current.append("\n")
                buffer = []
            else:
                buffer.append(char)
        elif state == "string":
            buffer.append(char)
            if char == "'":
                if following == "'":
                    buffer.append(following)
                    index += 1
                else:
                    state = "code"
        elif state == "line_comment":
            if char == "\n":
                state = "code"
                current.append("".join(buffer))
                current.append("\n")
                buffer = []
            else:
                buffer.append(char)
        else:  # block_comment
            buffer.append(char)
            if char == "*" and following == "/":
                buffer.append(following)
                index += 1
                state = "code"

        index += 1

    tail = "".join(buffer)
    if tail:
        # A script may end with a GO separator that has no trailing newline.
        if state == "code" and _GO_SEPARATOR.match(tail.strip()):
            tail = ""
        else:
            current.append(tail)

    batch = "".join(current).strip()
    if batch:
        batches.append(batch)

    return batches


def build_connection_string(database: str) -> str:
    """Build an ODBC connection string for the configured SQL Server."""
    parts = [
        f"DRIVER={{{DB_DRIVER}}}",
        f"SERVER={DB_SERVER}",
        f"DATABASE={database}",
    ]

    if DB_TRUSTED_CONNECTION.strip().lower() in {"1", "yes", "true"}:
        parts.append("Trusted_Connection=yes")
    else:
        parts.append(f"UID={DB_USERNAME}")
        parts.append(f"PWD={DB_PASSWORD}")

    parts.append(f"Encrypt={DB_ENCRYPT}")
    parts.append(f"TrustServerCertificate={DB_TRUST_SERVER_CERTIFICATE}")
    return ";".join(parts)


@contextmanager
def database_connection(database: str) -> Iterator["pyodbc.Connection"]:
    """Open an autocommit connection and always close it afterwards."""
    connection = pyodbc.connect(
        build_connection_string(database),
        autocommit=True,
        timeout=DB_LOGIN_TIMEOUT,
    )
    try:
        connection.timeout = DB_QUERY_TIMEOUT
        yield connection
    finally:
        try:
            connection.close()
        except Exception:  # pragma: no cover - defensive close
            logger.debug("Could not close the connection cleanly.", exc_info=True)


def _run_batch(
    cursor: "pyodbc.Cursor", sql: str, parameters: Sequence[object] = ()
) -> None:
    if parameters:
        cursor.execute(sql, parameters)
    else:
        cursor.execute(sql)

    # Drain every result set so the connection is never left busy.
    while cursor.nextset():
        pass


def _sql_files(directory: Path) -> list[Path]:
    if not directory.is_dir():
        raise FileNotFoundError(f"SQL directory not found: {directory}")
    files = sorted(
        (path for path in directory.iterdir() if path.is_file() and path.suffix.lower() == ".sql"),
        key=lambda path: path.name.lower(),
    )
    if not files:
        raise FileNotFoundError(f"No .sql files found in {directory}")
    return files


def _execute_scripts(connection: "pyodbc.Connection", scripts: Sequence[Path]) -> None:
    for script in scripts:
        batches = split_sql_batches(script.read_text(encoding="utf-8-sig"))
        if not batches:
            logger.warning("Skipping empty script: %s", script.name)
            continue

        logger.info("  executing %s (%d batch(es))", script.name, len(batches))
        with connection.cursor() as cursor:
            for batch in batches:
                _run_batch(cursor, batch)


def _discover_procedure_calls(procedures_dir: Path) -> list[str]:
    """Return procedure names in the order they are defined on disk."""
    calls: list[str] = []
    for script in _sql_files(procedures_dir):
        text = script.read_text(encoding="utf-8-sig")
        for match in _CREATE_PROCEDURE.finditer(text):
            name = match.group(1)
            if not _PROCEDURE_NAME.match(name):
                raise ValueError(f"Unsupported procedure name in {script.name}: {name!r}")
            if name.lower() not in {existing.lower() for existing in calls}:
                calls.append(name)

    if not calls:
        raise RuntimeError(f"No CREATE PROCEDURE statements found in {procedures_dir}")
    return calls


def _staging_argument(procedure: str) -> str:
    """Resolve the CSV path passed to a staging procedure via ``@FilePath``."""
    csv_name = STAGING_CSV_BY_PROCEDURE.get(procedure.lower())
    if csv_name is None:
        raise KeyError(f"No source CSV mapped for staging procedure '{procedure}'.")

    csv_path = DATA_DIR / csv_name
    if not csv_path.is_file():
        raise FileNotFoundError(f"Source CSV not found: {csv_path}")
    return str(csv_path)


def _execute_procedure_calls(
    connection: "pyodbc.Connection",
    procedures: Sequence[str],
    argument_resolver=None,
) -> None:
    with connection.cursor() as cursor:
        for procedure in procedures:
            argument = argument_resolver(procedure) if argument_resolver else None
            if argument is None:
                logger.info("  EXEC %s", procedure)
                _run_batch(cursor, f"EXEC {procedure};")
            else:
                logger.info("  EXEC %s @FilePath = %s", procedure, argument)
                _run_batch(cursor, f"EXEC {procedure} @FilePath = ?;", (argument,))


def _banner(layer: str) -> None:
    logger.info("")
    logger.info("=" * 78)
    logger.info("%s", layer)
    logger.info("=" * 78)


# ---------------------------------------------------------------------------
# Layer 00 - database and schema initialisation
# ---------------------------------------------------------------------------

def run_00_init() -> None:
    """Create the RetailChurn database and the staging/bronze/silver/gold schemas."""
    layer = "Layer 00 - DWH Initialization"
    _banner(layer)

    try:
        with database_connection(MASTER_DATABASE) as connection:
            _execute_scripts(connection, _sql_files(DWH_DIR))
    except Exception as exc:
        _abort(layer, "DDL", exc)

    logger.info("%s completed successfully.", layer)


# ---------------------------------------------------------------------------
# Layer 01 - staging
# ---------------------------------------------------------------------------

def run_01_staging() -> None:
    """Create staging tables, register loaders and bulk-load the raw CSVs."""
    layer = "Layer 01 - Staging"
    _banner(layer)

    try:
        with database_connection(DATABASE) as connection:
            _execute_scripts(connection, _sql_files(STAGING_DIR / "ddl"))
    except Exception as exc:
        _abort(layer, "DDL", exc)

    try:
        with database_connection(DATABASE) as connection:
            _execute_scripts(connection, _sql_files(STAGING_DIR / "procedures"))
    except Exception as exc:
        _abort(layer, "Stored Procedure Creation", exc)

    try:
        procedures = _discover_procedure_calls(STAGING_DIR / "procedures")
        with database_connection(DATABASE) as connection:
            _execute_procedure_calls(connection, procedures, _staging_argument)
    except Exception as exc:
        _abort(layer, "Stored Procedure Execution", exc)

    logger.info("%s completed successfully.", layer)


# ---------------------------------------------------------------------------
# Layer 02 - bronze
# ---------------------------------------------------------------------------

def run_02_bronze() -> None:
    """Create bronze tables, register loaders and populate bronze."""
    layer = "Layer 02 - Bronze"
    _banner(layer)

    try:
        with database_connection(DATABASE) as connection:
            _execute_scripts(connection, _sql_files(BRONZE_DIR / "ddl"))
    except Exception as exc:
        _abort(layer, "DDL", exc)

    try:
        with database_connection(DATABASE) as connection:
            _execute_scripts(connection, _sql_files(BRONZE_DIR / "procedures"))
    except Exception as exc:
        _abort(layer, "Stored Procedure Creation", exc)

    try:
        procedures = _discover_procedure_calls(BRONZE_DIR / "procedures")
        with database_connection(DATABASE) as connection:
            _execute_procedure_calls(connection, procedures)
    except Exception as exc:
        _abort(layer, "Stored Procedure Execution", exc)

    logger.info("%s completed successfully.", layer)


# ---------------------------------------------------------------------------
# Layer 03 - silver
# ---------------------------------------------------------------------------

def run_03_silver() -> None:
    """Create silver tables, register transforms and populate silver."""
    layer = "Layer 03 - Silver"
    _banner(layer)

    try:
        with database_connection(DATABASE) as connection:
            _execute_scripts(connection, _sql_files(SILVER_DIR / "ddl"))
    except Exception as exc:
        _abort(layer, "DDL", exc)

    try:
        with database_connection(DATABASE) as connection:
            _execute_scripts(connection, _sql_files(SILVER_DIR / "procedures"))
    except Exception as exc:
        _abort(layer, "Stored Procedure Creation", exc)

    try:
        procedures = _discover_procedure_calls(SILVER_DIR / "procedures")
        with database_connection(DATABASE) as connection:
            _execute_procedure_calls(connection, procedures)
    except Exception as exc:
        _abort(layer, "Stored Procedure Execution", exc)

    logger.info("%s completed successfully.", layer)


# ---------------------------------------------------------------------------
# Layer 04 - gold
# ---------------------------------------------------------------------------

def run_04_gold() -> None:
    """Create gold dimensions/facts and populate the star schema."""
    layer = "Layer 04 - Gold"
    _banner(layer)

    try:
        with database_connection(DATABASE) as connection:
            _execute_scripts(connection, _sql_files(GOLD_DIR / "ddl"))
    except Exception as exc:
        _abort(layer, "DDL", exc)

    try:
        with database_connection(DATABASE) as connection:
            _execute_scripts(connection, _sql_files(GOLD_DIR / "procedures"))
    except Exception as exc:
        _abort(layer, "Stored Procedure Creation", exc)

    try:
        procedures = _discover_procedure_calls(GOLD_DIR / "procedures")
        with database_connection(DATABASE) as connection:
            _execute_procedure_calls(connection, procedures)
    except Exception as exc:
        _abort(layer, "Stored Procedure Execution", exc)

    logger.info("%s completed successfully.", layer)


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

def main() -> int:
    """Build and populate the entire warehouse in layer order."""
    _configure_logging()
    logger.info("RetailChurn DWH orchestration started.")
    logger.info("SQL Server: %s | database: %s", DB_SERVER, DATABASE)

    try:
        run_00_init()
        run_01_staging()
        run_02_bronze()
        run_03_silver()
        run_04_gold()
    except LayerStepError as exc:
        logger.error(
            "Execution stopped at %s while running '%s'. Fix the issue and re-run.",
            exc.layer,
            exc.substep,
        )
        return 1
    except KeyboardInterrupt:
        logger.error("Execution interrupted by the user.")
        return 130

    logger.info("")
    logger.info("Data warehouse build completed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

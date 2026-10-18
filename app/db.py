
import os

from sqlalchemy import create_engine, event
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from sqlalchemy.pool import StaticPool


class Base(DeclarativeBase):
    pass


raw_database_url = os.getenv("DATABASE_URL", "").strip()

if raw_database_url:
    # Use Psycopg 3 explicitly for PostgreSQL connections.
    if raw_database_url.startswith("postgres://"):
        DATABASE_URL = raw_database_url.replace(
            "postgres://", "postgresql+psycopg://", 1
        )
    elif raw_database_url.startswith("postgresql://"):
        DATABASE_URL = raw_database_url.replace(
            "postgresql://", "postgresql+psycopg://", 1
        )
    else:
        DATABASE_URL = raw_database_url
else:
    # Local development fallback only.
    DATABASE_URL = "sqlite:///./matka.db"

connect_args = (
    {"check_same_thread": False}
    if DATABASE_URL.startswith("sqlite")
    else {}
)

engine_options = (
    {"poolclass": StaticPool}
    if DATABASE_URL in {"sqlite://", "sqlite:///:memory:"}
    else {}
)

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    **engine_options,
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    expire_on_commit=False,
)

if DATABASE_URL.startswith("sqlite"):
    @event.listens_for(engine, "connect")
    def enable_sqlite_foreign_keys(connection, _):
        cursor = connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()


def get_db():
    database = SessionLocal()
    try:
        yield database
    finally:
        database.close()

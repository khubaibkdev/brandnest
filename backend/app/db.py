from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import settings

engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


def get_session() -> Session:
    return SessionLocal()


def db_session() -> Iterator[Session]:
    """FastAPI dependency: a request-scoped session."""
    with SessionLocal() as session:
        yield session

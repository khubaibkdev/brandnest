import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.auth import current_user, get_or_create_user
from app.db import db_session, engine
from app.main import app


@pytest.fixture
def session():
    """A session on a transaction that is always rolled back.

    Tests therefore run against the real (migrated) database without leaving
    anything behind — no separate test database to keep in step.
    """
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection, join_transaction_mode="create_savepoint")
    yield session
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(session):
    app.dependency_overrides[db_session] = lambda: session
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.fixture
def as_signed_in(session):
    """Serve requests as a given UID, without asking Firebase anything."""

    def sign_in(firebase_uid: str = "firebase-uid-guest"):
        app.dependency_overrides[current_user] = lambda: get_or_create_user(
            session, firebase_uid
        )

    yield sign_in
    app.dependency_overrides.pop(current_user, None)

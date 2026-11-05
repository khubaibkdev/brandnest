"""US-9: the `/me` routes and the user row behind a Firebase UID.

`verify_id_token` is the only thing Firebase owns here, so it is overridden and
the rest — provisioning, storage, validation — runs against the real database.
"""

import pytest
from sqlalchemy import select

from app.auth import TokenError, get_or_create_user
from app.models import Bank, User

GUEST = "firebase-uid-guest"


@pytest.fixture
def banks(session):
    rows = [
        Bank(slug="test-meezan", name="Meezan Bank"),
        Bank(slug="test-ubl", name="UBL"),
    ]
    session.add_all(rows)
    session.flush()
    return rows


def test_a_guest_gets_a_user_row_the_first_time_we_see_their_uid(session, client, as_signed_in):
    as_signed_in("brand-new-uid")

    assert client.get("/me/banks").status_code == 200
    assert session.scalar(
        select(User).where(User.firebase_uid == "brand-new-uid")
    ) is not None


def test_the_same_uid_keeps_the_same_row(session, as_signed_in):
    """Linking a Google account keeps the Firebase UID, so nothing is migrated."""
    first = get_or_create_user(session, GUEST)
    again = get_or_create_user(session, GUEST)

    assert first.id == again.id


def test_a_new_user_starts_with_no_saved_cards(session, client, as_signed_in):
    as_signed_in("uid-with-nothing-saved")

    assert client.get("/me/banks").json() == []


def test_saved_cards_come_back_as_the_app_sent_them(session, client, as_signed_in, banks):
    as_signed_in()

    stored = client.put(
        "/me/banks",
        json=[
            {"bank_slug": "test-meezan", "card_type": "islamic"},
            {"bank_slug": "test-ubl", "card_type": "credit"},
        ],
    )

    assert stored.status_code == 200
    assert client.get("/me/banks").json() == [
        {"bank_slug": "test-meezan", "card_type": "islamic"},
        {"bank_slug": "test-ubl", "card_type": "credit"},
    ]


def test_cards_are_stored_against_the_bank_id_not_its_slug(session, client, as_signed_in, banks):
    """The column holds ids, so renaming a bank's slug cannot orphan a shopper's list."""
    as_signed_in()

    client.put("/me/banks", json=[{"bank_slug": "test-meezan", "card_type": "islamic"}])

    user = session.scalar(select(User).where(User.firebase_uid == GUEST))
    assert user.my_banks == [{"bank_id": banks[0].id, "card_type": "islamic"}]


def test_putting_again_replaces_rather_than_appends(session, client, as_signed_in, banks):
    as_signed_in()
    client.put("/me/banks", json=[{"bank_slug": "test-meezan", "card_type": "islamic"}])

    client.put("/me/banks", json=[{"bank_slug": "test-ubl", "card_type": "credit"}])

    assert client.get("/me/banks").json() == [
        {"bank_slug": "test-ubl", "card_type": "credit"}
    ]


def test_unticking_everything_leaves_nothing(session, client, as_signed_in, banks):
    as_signed_in()
    client.put("/me/banks", json=[{"bank_slug": "test-meezan", "card_type": "islamic"}])

    client.put("/me/banks", json=[])

    assert client.get("/me/banks").json() == []


def test_the_same_card_twice_is_stored_once(session, client, as_signed_in, banks):
    as_signed_in()

    client.put(
        "/me/banks",
        json=[
            {"bank_slug": "test-meezan", "card_type": "islamic"},
            {"bank_slug": "test-meezan", "card_type": "islamic"},
        ],
    )

    assert client.get("/me/banks").json() == [
        {"bank_slug": "test-meezan", "card_type": "islamic"}
    ]


def test_a_bank_we_do_not_carry_is_refused(session, client, as_signed_in, banks):
    as_signed_in()

    refused = client.put(
        "/me/banks", json=[{"bank_slug": "not-a-bank", "card_type": "credit"}]
    )

    assert refused.status_code == 400
    assert "not-a-bank" in refused.json()["detail"]


def test_two_shoppers_do_not_share_a_card_list(session, client, as_signed_in, banks):
    as_signed_in("uid-one")
    client.put("/me/banks", json=[{"bank_slug": "test-meezan", "card_type": "islamic"}])

    as_signed_in("uid-two")

    assert client.get("/me/banks").json() == []


class TestWithoutAValidToken:
    """The dependency itself, with Firebase's answer stubbed out."""

    def test_no_authorization_header_is_a_401(self, client):
        assert client.get("/me/banks").status_code == 401

    def test_a_bare_token_without_bearer_is_a_401(self, client):
        assert client.get(
            "/me/banks", headers={"Authorization": "abc123"}
        ).status_code == 401

    def test_a_token_firebase_rejects_is_a_401(self, client, monkeypatch):
        monkeypatch.setattr(
            "app.auth.verify_id_token",
            lambda _: (_ for _ in ()).throw(TokenError("expired")),
        )

        assert client.get(
            "/me/banks", headers={"Authorization": "Bearer expired-token"}
        ).status_code == 401

    def test_a_token_firebase_accepts_provisions_the_user(self, session, client, monkeypatch):
        monkeypatch.setattr("app.auth.verify_id_token", lambda _: "uid-from-token")

        response = client.get(
            "/me/banks", headers={"Authorization": "Bearer good-token"}
        )

        assert response.status_code == 200
        assert session.scalar(
            select(User).where(User.firebase_uid == "uid-from-token")
        ) is not None


def test_the_catalog_stays_open_to_guests(client):
    """Guest-first: browsing must not need a token (US-9's whole point)."""
    assert client.get("/brands").status_code == 200
    assert client.get("/sales").status_code == 200
    assert client.get("/offers").status_code == 200

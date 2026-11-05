"""US-10: the points ledger — append-only, idempotent, balance = SUM(delta)."""

from datetime import date, timedelta

from app.auth import get_or_create_user
from app.models import PointsLedger
from app.services import points


def test_a_new_shopper_starts_at_zero(client, as_signed_in):
    as_signed_in()

    response = client.get("/me/points")

    assert response.json() == {
        "balance": 0,
        "pending": 0,
        "streak_days": 0,
        "checked_in_today": False,
        "rewarded_ads_remaining_today": 5,
    }


def test_checking_in_awards_points_and_starts_a_streak(client, as_signed_in):
    as_signed_in()

    response = client.post("/me/points/checkin")

    assert response.json() == {
        "balance": 10,
        "pending": 0,
        "streak_days": 1,
        "checked_in_today": True,
        "rewarded_ads_remaining_today": 5,
        "awarded": True,
    }


def test_checking_in_twice_the_same_day_awards_once(client, as_signed_in):
    as_signed_in()
    client.post("/me/points/checkin")

    again = client.post("/me/points/checkin")

    assert again.json()["awarded"] is False
    assert again.json()["balance"] == 10


def test_a_streak_counts_consecutive_days_only(session, client, as_signed_in):
    as_signed_in()
    user = get_or_create_user(session, "firebase-uid-guest")
    today = date.today()
    for offset in (3, 2, 1, 0):  # yesterday-yesterday...today, unbroken
        day = today - timedelta(days=offset)
        points.award_points(
            session, user.id, points.CHECKIN_POINTS, "streak",
            idempotency_key=f"streak:{user.id}:{day.isoformat()}", ref_id=day.isoformat(),
        )

    assert client.get("/me/points").json()["streak_days"] == 4


def test_a_gap_breaks_the_streak(session, client, as_signed_in):
    as_signed_in()
    user = get_or_create_user(session, "firebase-uid-guest")
    today = date.today()
    # Checked in today and 5 days ago, nothing in between.
    for offset in (5, 0):
        day = today - timedelta(days=offset)
        points.award_points(
            session, user.id, points.CHECKIN_POINTS, "streak",
            idempotency_key=f"streak:{user.id}:{day.isoformat()}", ref_id=day.isoformat(),
        )

    assert client.get("/me/points").json()["streak_days"] == 1


def test_a_streak_not_yet_broken_still_shows_before_todays_checkin(session, client, as_signed_in):
    """Checked in yesterday, not yet today — the streak is still alive, not reset to 0."""
    as_signed_in()
    user = get_or_create_user(session, "firebase-uid-guest")
    yesterday = date.today() - timedelta(days=1)
    points.award_points(
        session, user.id, points.CHECKIN_POINTS, "streak",
        idempotency_key=f"streak:{user.id}:{yesterday.isoformat()}",
        ref_id=yesterday.isoformat(),
    )

    response = client.get("/me/points")

    assert response.json()["streak_days"] == 1
    assert response.json()["checked_in_today"] is False


def test_a_rewarded_ad_awards_points(client, as_signed_in):
    as_signed_in()

    response = client.post("/me/points/rewarded-ad", json={"client_ref": "watch-1"})

    assert response.json()["awarded"] is True
    assert response.json()["balance"] == 20
    assert response.json()["rewarded_ads_remaining_today"] == 4


def test_the_same_ad_watch_reported_twice_is_not_paid_twice(client, as_signed_in):
    as_signed_in()
    client.post("/me/points/rewarded-ad", json={"client_ref": "watch-1"})

    again = client.post("/me/points/rewarded-ad", json={"client_ref": "watch-1"})

    assert again.json()["awarded"] is False
    assert again.json()["balance"] == 20


def test_the_daily_cap_stops_paying_once_reached(client, as_signed_in):
    as_signed_in()
    for i in range(points.REWARDED_AD_DAILY_CAP):
        client.post("/me/points/rewarded-ad", json={"client_ref": f"watch-{i}"})

    over_cap = client.post("/me/points/rewarded-ad", json={"client_ref": "watch-one-too-many"})

    assert over_cap.json()["awarded"] is False
    assert over_cap.json()["rewarded_ads_remaining_today"] == 0
    assert over_cap.json()["balance"] == points.REWARDED_AD_POINTS * points.REWARDED_AD_DAILY_CAP


def test_two_shoppers_do_not_share_a_balance(client, as_signed_in):
    as_signed_in("uid-one")
    client.post("/me/points/checkin")

    as_signed_in("uid-two")

    assert client.get("/me/points").json()["balance"] == 0


def test_points_routes_require_a_token(client):
    assert client.get("/me/points").status_code == 401
    assert client.post("/me/points/checkin").status_code == 401
    assert client.post("/me/points/rewarded-ad", json={"client_ref": "x"}).status_code == 401


def test_award_points_is_a_no_op_on_a_repeated_key(session):
    user = get_or_create_user(session, "some-uid")

    first = points.award_points(session, user.id, 5, "streak", "same-key")
    second = points.award_points(session, user.id, 5, "streak", "same-key")

    assert first is True
    assert second is False
    assert points.balance(session, user.id) == 5
    assert session.query(PointsLedger).filter_by(idempotency_key="same-key").count() == 1

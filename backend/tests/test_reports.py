"""US-14: community deal reports, the desk decision, and the points it pays."""

import pytest

from app.auth import get_or_create_user
from app.models import DealReport, DeviceToken, PointsLedger
from app.services import points, reports, uploads

GUEST = "firebase-uid-guest"

PNG = b"\x89PNG\r\n\x1a\n" + b"0" * 64
JPEG = b"\xff\xd8\xff" + b"0" * 64


@pytest.fixture
def reporter(session):
    user = get_or_create_user(session, GUEST)
    session.add(DeviceToken(user_id=user.id, fcm_token="fake-fcm-token"))
    session.commit()
    return user


@pytest.fixture
def sent(session, reporter):
    return reports.create_report(session, reporter.id, "Meezan 20% at J.", "/uploads/a.png")


# --- storage ----------------------------------------------------------------


def test_an_images_type_comes_from_its_bytes_not_its_name(tmp_path, monkeypatch):
    """The filename and the content-type header are both the uploader's to
    claim; the magic number is not."""
    monkeypatch.setattr(uploads.settings, "uploads_dir", str(tmp_path))

    assert uploads.save_screenshot(PNG).endswith(".png")
    assert uploads.save_screenshot(JPEG).endswith(".jpg")


def test_a_file_that_is_not_an_image_is_refused(tmp_path, monkeypatch):
    monkeypatch.setattr(uploads.settings, "uploads_dir", str(tmp_path))

    with pytest.raises(uploads.UnsupportedImage):
        uploads.save_screenshot(b"GIF89a-actually-a-gif")
    with pytest.raises(uploads.UnsupportedImage):
        uploads.save_screenshot(b"#!/bin/sh\nrm -rf /")


def test_an_oversized_upload_is_refused_before_it_is_written(tmp_path, monkeypatch):
    monkeypatch.setattr(uploads.settings, "uploads_dir", str(tmp_path))

    with pytest.raises(uploads.UnsupportedImage):
        uploads.save_screenshot(PNG + b"0" * uploads.MAX_BYTES)
    assert list(tmp_path.iterdir()) == []


def test_two_uploads_never_collide(tmp_path, monkeypatch):
    monkeypatch.setattr(uploads.settings, "uploads_dir", str(tmp_path))

    assert uploads.save_screenshot(PNG) != uploads.save_screenshot(PNG)


# --- the desk decision ------------------------------------------------------


def test_a_new_report_waits_on_the_desk(session, sent):
    assert sent.status == reports.NEW
    assert sent.points_awarded == 0
    assert sent in reports.pending_reports(session)


def test_accepting_pays_the_reporter(session, sent, reporter):
    reports.accept(session, sent)

    assert sent.status == reports.ACCEPTED
    assert sent.points_awarded == reports.REPORT_POINTS
    assert points.balance(session, reporter.id) == reports.REPORT_POINTS


def test_accepting_twice_cannot_pay_twice(session, sent, reporter):
    """Two desk tabs, or a double-click. The ledger is append-only, so the
    guard has to be here rather than in a later correction."""
    reports.accept(session, sent)

    with pytest.raises(reports.AlreadyDecided):
        reports.accept(session, sent)

    assert points.balance(session, reporter.id) == reports.REPORT_POINTS
    assert (
        session.query(PointsLedger)
        .filter_by(user_id=reporter.id, reason="deal_report")
        .count()
        == 1
    )


def test_rejecting_pays_nothing(session, sent, reporter):
    reports.reject(session, sent)

    assert sent.status == reports.REJECTED
    assert sent.points_awarded == 0
    assert points.balance(session, reporter.id) == 0


def test_a_rejected_report_cannot_later_be_accepted(session, sent):
    """Undoing a decision would push a second notification about a report the
    reporter already heard about."""
    reports.reject(session, sent)

    with pytest.raises(reports.AlreadyDecided):
        reports.accept(session, sent)


def test_a_decided_report_leaves_the_queue(session, sent):
    reports.accept(session, sent)

    assert sent not in reports.pending_reports(session)


def test_a_reporter_with_no_device_still_gets_a_decision(session, reporter):
    """Nobody is blocked from clearing the queue by a shopper who never granted
    notification permission."""
    session.query(DeviceToken).filter_by(user_id=reporter.id).delete()
    session.commit()
    report = reports.create_report(session, reporter.id, "A deal", None)

    reports.accept(session, report)

    assert report.status == reports.ACCEPTED
    assert points.balance(session, reporter.id) == reports.REPORT_POINTS


# --- the endpoint -----------------------------------------------------------


def test_sending_a_report_stores_the_screenshot(client, as_signed_in, tmp_path, monkeypatch):
    monkeypatch.setattr(uploads.settings, "uploads_dir", str(tmp_path))
    as_signed_in(GUEST)

    response = client.post(
        "/me/reports",
        data={"text": "UBL 15% at Khaadi"},
        files={"screenshot": ("proof.png", PNG, "image/png")},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "new"
    assert body["text"] == "UBL 15% at Khaadi"
    assert body["screenshot_url"].startswith("/uploads/")
    assert body["points_awarded"] == 0


def test_a_report_can_be_words_only(client, as_signed_in):
    as_signed_in(GUEST)

    response = client.post("/me/reports", data={"text": "Sale at Sapphire"})

    assert response.status_code == 201
    assert response.json()["screenshot_url"] is None


def test_an_empty_report_is_refused(client, as_signed_in):
    as_signed_in(GUEST)

    assert client.post("/me/reports", data={"text": "   "}).status_code == 422


def test_a_non_image_attachment_is_refused(client, as_signed_in, tmp_path, monkeypatch):
    monkeypatch.setattr(uploads.settings, "uploads_dir", str(tmp_path))
    as_signed_in(GUEST)

    response = client.post(
        "/me/reports",
        data={"text": "proof attached"},
        files={"screenshot": ("proof.png", b"not-an-image", "image/png")},
    )

    assert response.status_code == 422


def test_my_reports_lists_only_my_own(client, as_signed_in, session):
    other = get_or_create_user(session, "firebase-uid-someone-else")
    reports.create_report(session, other.id, "Not mine", None)
    as_signed_in(GUEST)
    client.post("/me/reports", data={"text": "Mine"})

    body = client.get("/me/reports").json()

    assert [report["text"] for report in body] == ["Mine"]


def test_the_desk_can_accept_a_report(client, session, sent):
    response = client.post(
        f"/admin/reports/{sent.id}/accept", auth=("founder", "brandnest")
    )

    assert response.status_code == 200
    assert session.get(DealReport, sent.id).status == reports.ACCEPTED


def test_the_desk_gets_a_conflict_rather_than_paying_twice(client, sent):
    client.post(f"/admin/reports/{sent.id}/accept", auth=("founder", "brandnest"))

    second = client.post(
        f"/admin/reports/{sent.id}/accept", auth=("founder", "brandnest")
    )

    assert second.status_code == 409


def test_the_report_queue_needs_the_desk_password(client):
    assert client.get("/admin/reports").status_code == 401

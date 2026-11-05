"""Outbound FCM push.

Topic sends (US-6) reach every device subscribed to `sale-{brand_slug}` /
`offer-{bank_slug}` through the FCM client SDK — the backend never needs to
know which devices exist. Direct sends (US-13) are the opposite: a watch
alert is for one shopper's own device(s), so it needs their `fcm_token`s from
`device_token`, which is the first thing in this codebase to actually read
that table.

A failed send never breaks the worker's own job. `run_deal_transitions` and
`run_watch_alerts` both have to keep working whether or not a push goes out,
the same way a missing service-account key degrades `/me` without taking the
API down.
"""

import logging

from app.firebase import FirebaseUnavailable, firebase_app

logger = logging.getLogger(__name__)


def send_topic_notification(
    topic: str, title: str, body: str, data: dict[str, str] | None = None
) -> None:
    from firebase_admin import messaging

    try:
        app = firebase_app()
        messaging.send(
            messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                topic=topic,
            ),
            app=app,
        )
    except FirebaseUnavailable:
        logger.info("skipped push to %s: no Firebase service-account key", topic)
    except Exception as error:
        logger.warning("failed to send push to %s: %s", topic, error)


def send_device_notification(
    fcm_token: str, title: str, body: str, data: dict[str, str] | None = None
) -> bool:
    """One shopper's own device. Returns whether the send actually went out,
    so a caller can tell a real failure from "no key on this machine" without
    parsing logs."""
    from firebase_admin import messaging

    try:
        app = firebase_app()
        messaging.send(
            messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=data or {},
                token=fcm_token,
            ),
            app=app,
        )
        return True
    except FirebaseUnavailable:
        logger.info("skipped push to a device: no Firebase service-account key")
        return False
    except Exception as error:
        logger.warning("failed to send push to a device: %s", error)
        return False

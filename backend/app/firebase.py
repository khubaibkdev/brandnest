"""The shared `firebase_admin` app, initialised once, on first use.

Lazy because the API must still boot and serve the public catalog on a machine
that has no service-account key — a missing key disables `/me` and push, not
the whole server. Both ID-token verification (`app/auth.py`) and outbound push
(`app/services/notifications.py`) need the same app; initialising it twice
raises, so this is the one place that does it.
"""

import os
import threading

_init_lock = threading.Lock()
_firebase_app = None


class FirebaseUnavailable(Exception):
    """No service-account key on this machine."""


def firebase_app():
    global _firebase_app
    if _firebase_app is None:
        with _init_lock:
            if _firebase_app is None:
                import firebase_admin
                from firebase_admin import credentials

                from app.config import settings

                path = settings.firebase_credentials_path
                if not os.path.exists(path):
                    raise FirebaseUnavailable(f"no Firebase service-account key at {path}")
                _firebase_app = firebase_admin.initialize_app(
                    credentials.Certificate(path)
                )
    return _firebase_app

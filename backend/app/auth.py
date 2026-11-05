"""Firebase ID-token verification and the user row behind it (US-9).

The app signs in anonymously on first launch and links a Google account later,
keeping the same Firebase UID. So a `user` row is created the first time we see
a UID and outlives the upgrade from guest to signed-in — nothing to migrate when
someone finally links an account.

Only `/me` routes need this. The catalog, sale calendar and offer directory stay
open, because a guest has to be able to use the app before any token exists.
"""

import logging

from fastapi import Depends, Header, HTTPException
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import db_session
from app.firebase import FirebaseUnavailable, firebase_app
from app.models import User

logger = logging.getLogger(__name__)


class TokenError(Exception):
    """The bearer token is missing, malformed, expired, or not ours."""


def verify_id_token(token: str) -> str:
    """Return the Firebase UID a token belongs to, or raise [TokenError]."""
    from firebase_admin import auth as firebase_auth

    try:
        firebase_app()
    except FirebaseUnavailable as error:
        raise TokenError(str(error)) from error
    try:
        return firebase_auth.verify_id_token(token)["uid"]
    except Exception as error:
        # Expired, tampered, signed by another project — all one answer to the
        # caller, and the detail stays in our logs rather than the response.
        logger.info("rejected an ID token: %s", error)
        raise TokenError(str(error)) from error


def get_or_create_user(session: Session, firebase_uid: str) -> User:
    """The user row for a UID, created the first time that UID appears.

    The app fires several requests at launch, so two of them can race to create
    the same brand-new user; the insert yields to whichever got there first and
    both end up with the same row.
    """
    user = session.scalar(select(User).where(User.firebase_uid == firebase_uid))
    if user is not None:
        return user

    session.execute(
        insert(User)
        .values(firebase_uid=firebase_uid)
        .on_conflict_do_nothing(index_elements=["firebase_uid"])
    )
    session.commit()
    return session.scalar(select(User).where(User.firebase_uid == firebase_uid))


def current_user(
    authorization: str | None = Header(default=None),
    session: Session = Depends(db_session),
) -> User:
    """FastAPI dependency: the signed-in (or anonymous) user behind the request."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Sign-in required")
    try:
        firebase_uid = verify_id_token(authorization.split(" ", 1)[1].strip())
    except TokenError:
        raise HTTPException(status_code=401, detail="Sign-in required") from None
    return get_or_create_user(session, firebase_uid)

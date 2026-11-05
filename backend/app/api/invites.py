"""The public side of a shared link (US-21).

With the app installed, Android opens `/i/{code}` straight in BrandNest — but
only after it has checked `assetlinks.json` on this host. Without the app, the
browser lands on the page below, which shows the code to type in once
BrandNest is installed.
"""

from html import escape

from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from app.config import settings
from app.db import db_session
from app.services import squads

router = APIRouter(tags=["invites"])

EVENT_LABELS = {
    "mehndi": "Mehndi",
    "baraat": "Baraat",
    "walima": "Walima",
    "eid": "Eid",
    "other": "Event",
}


@router.get("/.well-known/assetlinks.json")
def asset_links() -> list[dict]:
    return [
        {
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
                "namespace": "android_app",
                "package_name": settings.android_package,
                "sha256_cert_fingerprints": settings.android_cert_sha256,
            },
        }
    ]


@router.get("/i/{invite_code}", response_class=HTMLResponse)
def invite_page(invite_code: str, session: Session = Depends(db_session)) -> HTMLResponse:
    squad = squads.find_by_invite(session, invite_code)
    if squad is None:
        return HTMLResponse(_page("This invite has expired or the link is incomplete.", None), 404)
    heading = (
        f"You're invited to plan outfits for <strong>{escape(squad.name)}</strong>"
        f" ({EVENT_LABELS[squad.event_type]})"
    )
    return HTMLResponse(_page(heading, squad.invite_code))


def _page(heading: str, invite_code: str | None) -> str:
    code_block = (
        f"""<p>Install BrandNest, open <b>Squads</b>, tap <b>Join with code</b> and enter:</p>
<p class="code">{invite_code}</p>"""
        if invite_code
        else ""
    )
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>BrandNest Shaadi Squad</title>
<style>
body {{ font-family: system-ui, sans-serif; margin: 0; padding: 32px 16px; background: #fbf7f2; color: #2b2118; }}
main {{ max-width: 420px; margin: 0 auto; }}
h1 {{ font-size: 22px; line-height: 1.35; font-weight: 500; }}
.code {{ font: 600 28px/1 ui-monospace, monospace; letter-spacing: 4px; background: #fff;
        border: 1px solid #e6dccf; border-radius: 12px; padding: 16px; text-align: center; }}
</style></head>
<body><main>
<p>BrandNest · Shaadi Squad</p>
<h1>{heading}</h1>
{code_block}
</main></body></html>"""

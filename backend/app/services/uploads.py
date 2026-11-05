"""Where a shopper's screenshot goes (US-14).

ARCHITECTURE.md §1 puts product thumbnails on Cloudflare R2, and these belong
there eventually too. They are on a local volume today because R2 needs an
account only the founder can create, and the hosting path is already
"local compose → tunnel → VPS" — so this is the same move the rest of the stack
is making, not a shortcut around it. `deal_report.screenshot_url` holds a URL
either way, so moving to R2 later changes this module and nothing else.

Deliberately *not* stored in Postgres: the nightly `pg_dump` protects the
price-history archive, and padding it with image bytes makes the one backup
that matters slower and larger.
"""

import logging
import secrets
from pathlib import Path

from app.config import settings

logger = logging.getLogger(__name__)

# Screenshots off a phone. Generous enough for a tall screenshot, small enough
# that an accidental video upload is refused rather than filling the disk.
MAX_BYTES = 6 * 1024 * 1024

# Checked against the bytes themselves, not the filename or the browser's
# content-type — both are the uploader's to claim.
MAGIC_NUMBERS: tuple[tuple[bytes, str], ...] = (
    (b"\xff\xd8\xff", ".jpg"),
    (b"\x89PNG\r\n\x1a\n", ".png"),
    (b"RIFF", ".webp"),
)


class UnsupportedImage(Exception):
    """The bytes are not an image we accept."""


def save_screenshot(content: bytes) -> str:
    """Write the image and return the URL it will be served at."""
    if len(content) > MAX_BYTES:
        raise UnsupportedImage("That image is too large — 6MB is the limit.")
    extension = _extension_for(content)

    directory = Path(settings.uploads_dir)
    directory.mkdir(parents=True, exist_ok=True)
    # Random, not sequential: the desk's screenshots are reachable by URL, and
    # a guessable name would let anyone walk other people's reports.
    name = f"{secrets.token_urlsafe(16)}{extension}"
    (directory / name).write_bytes(content)
    logger.info("stored screenshot %s (%s bytes)", name, len(content))
    return f"{settings.uploads_url_path}/{name}"


def _extension_for(content: bytes) -> str:
    for magic, extension in MAGIC_NUMBERS:
        if content.startswith(magic):
            return extension
    raise UnsupportedImage("Only JPEG, PNG or WebP images can be attached.")

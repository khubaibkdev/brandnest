from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth import current_user
from app.db import db_session
from app.models import Product, User
from app.services import watches

router = APIRouter(tags=["watches"])


class WatchStatusOut(BaseModel):
    product_id: int | None
    title: str | None
    watching: bool


class WatchIn(BaseModel):
    product_id: int


@router.get("/brands/{slug}/products/watch-status", response_model=WatchStatusOut)
def watch_status(
    slug: str,
    url: str,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> WatchStatusOut:
    """Whether the product the toolbar just detected is one we've crawled, and
    whether this shopper is already watching it — the toolbar needs both to
    decide if the Watch toggle shows at all, and what state it starts in."""
    product = watches.find_product_by_url(session, slug, url)
    if product is None:
        return WatchStatusOut(product_id=None, title=None, watching=False)
    return WatchStatusOut(
        product_id=product.id,
        title=product.title,
        watching=watches.is_watching(session, user.id, product.id),
    )


@router.post("/me/watches", status_code=204)
def create_watch(
    payload: WatchIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> None:
    if session.get(Product, payload.product_id) is None:
        raise HTTPException(status_code=404, detail="Unknown product")
    watches.start_watching(session, user.id, payload.product_id)


@router.delete("/me/watches/{product_id}", status_code=204)
def delete_watch(
    product_id: int,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> None:
    watches.stop_watching(session, user.id, product_id)

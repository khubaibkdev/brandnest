from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import db_session
from app.models import Brand, BrandConfig

router = APIRouter(prefix="/brands", tags=["brands"])


class BrandOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    slug: str
    name: str
    logo_url: str | None
    categories: list[str]
    website_url: str
    platform: str


class BrandConfigOut(BaseModel):
    """The webview slice of `brand_config`. Crawl settings stay server-side."""

    model_config = ConfigDict(from_attributes=True)

    webview_user_agent: str | None
    checkout_domains: list[str]
    product_url_regex: str | None
    # US-18: the app watches for these to know an order completed. Server-side
    # editable so a brand changing its checkout does not need an app release.
    order_confirm_patterns: list[str]


@router.get("", response_model=list[BrandOut])
def list_brands(session: Session = Depends(db_session)) -> list[Brand]:
    stmt = (
        select(Brand)
        .where(Brand.is_active.is_(True))
        .order_by(Brand.priority_tier, Brand.name)
    )
    return list(session.scalars(stmt))


@router.get("/{slug}/config", response_model=BrandConfigOut)
def get_brand_config(slug: str, session: Session = Depends(db_session)) -> BrandConfig:
    stmt = select(BrandConfig).join(Brand).where(Brand.slug == slug)
    config = session.scalar(stmt)
    if config is None:
        raise HTTPException(status_code=404, detail="Unknown brand")
    return config

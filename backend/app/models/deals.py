from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class SaleEvent(Base):
    __tablename__ = "sale_event"

    id: Mapped[int] = mapped_column(primary_key=True)
    brand_id: Mapped[int] = mapped_column(ForeignKey("brand.id"), index=True)
    title: Mapped[str] = mapped_column(String(200))
    discount_text: Mapped[str | None] = mapped_column(String(200))
    starts_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # draft | needs_verification | verified | live | expired | rejected
    status: Mapped[str] = mapped_column(String(20), default="draft")
    # crawler | report | manual
    source: Mapped[str] = mapped_column(String(20), default="manual")
    proof_url: Mapped[str | None] = mapped_column(String(500))
    verified_by: Mapped[str | None] = mapped_column(String(80))
    verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Bank(Base):
    __tablename__ = "bank"

    id: Mapped[int] = mapped_column(primary_key=True)
    slug: Mapped[str] = mapped_column(String(80), unique=True)
    name: Mapped[str] = mapped_column(String(120))
    logo_url: Mapped[str | None] = mapped_column(String(300))
    offer_page_url: Mapped[str | None] = mapped_column(String(300))


class BankOffer(Base):
    __tablename__ = "bank_offer"

    id: Mapped[int] = mapped_column(primary_key=True)
    bank_id: Mapped[int] = mapped_column(ForeignKey("bank.id"), index=True)
    # nullable = multi-brand offer
    brand_id: Mapped[int | None] = mapped_column(ForeignKey("brand.id"), index=True)
    # values: credit | debit | islamic | wallet | bnpl
    card_types: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    discount_pct: Mapped[Decimal | None] = mapped_column(Numeric(5, 2))
    max_discount_amt: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    min_spend: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    # online | instore | both
    channel: Mapped[str] = mapped_column(String(10), default="both")
    valid_from: Mapped[date | None] = mapped_column()
    valid_to: Mapped[date | None] = mapped_column()
    proof_url: Mapped[str | None] = mapped_column(String(500))
    # draft | needs_verification | verified | live | expired | rejected
    status: Mapped[str] = mapped_column(String(20), default="draft")
    source: Mapped[str] = mapped_column(String(20), default="manual")
    verified_by: Mapped[str | None] = mapped_column(String(80))
    verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class DealReport(Base):
    __tablename__ = "deal_report"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    screenshot_url: Mapped[str | None] = mapped_column(String(500))
    text: Mapped[str | None] = mapped_column(Text)
    linked_offer_id: Mapped[int | None] = mapped_column(ForeignKey("bank_offer.id"))
    linked_sale_id: Mapped[int | None] = mapped_column(ForeignKey("sale_event.id"))
    # new | accepted | rejected
    status: Mapped[str] = mapped_column(String(20), default="new")
    points_awarded: Mapped[int] = mapped_column(default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

"""Shaadi Squad (US-21): a family plans one event's outfits on a shared board."""

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    Numeric,
    SmallInteger,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class SquadEvent(Base):
    __tablename__ = "squad_event"

    id: Mapped[int] = mapped_column(primary_key=True)
    owner_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    name: Mapped[str] = mapped_column(String(80))
    # mehndi | baraat | walima | eid | other
    event_type: Mapped[str] = mapped_column(String(10))
    event_date: Mapped[date | None] = mapped_column(Date)
    invite_code: Mapped[str] = mapped_column(String(12), unique=True)
    budget_total: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class SquadMember(Base):
    __tablename__ = "squad_member"
    __table_args__ = (UniqueConstraint("squad_event_id", "user_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    squad_event_id: Mapped[int] = mapped_column(
        ForeignKey("squad_event.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    # Guests have no name on their account, and family needs to see who
    # pinned what — so each squad asks for the name relatives know you by.
    display_name: Mapped[str] = mapped_column(String(40))
    # owner | member
    role: Mapped[str] = mapped_column(String(10), default="member")
    budget_personal: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class SquadItem(Base):
    __tablename__ = "squad_item"
    __table_args__ = (UniqueConstraint("squad_event_id", "url"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    squad_event_id: Mapped[int] = mapped_column(
        ForeignKey("squad_event.id", ondelete="CASCADE"), index=True
    )
    added_by: Mapped[int] = mapped_column(ForeignKey("squad_member.id", ondelete="CASCADE"))
    brand_id: Mapped[int] = mapped_column(ForeignKey("brand.id"))
    # Set when the page is one we crawl, so the board can show today's price;
    # otherwise the snapshot below is all there is.
    product_id: Mapped[int | None] = mapped_column(ForeignKey("product.id"))
    url: Mapped[str] = mapped_column(String(1000))
    title: Mapped[str] = mapped_column(String(300))
    image_url: Mapped[str | None] = mapped_column(String(1000))
    price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    assigned_to: Mapped[int | None] = mapped_column(
        ForeignKey("squad_member.id", ondelete="SET NULL")
    )
    note: Mapped[str | None] = mapped_column(String(300))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class SquadVote(Base):
    __tablename__ = "squad_vote"

    item_id: Mapped[int] = mapped_column(
        ForeignKey("squad_item.id", ondelete="CASCADE"), primary_key=True
    )
    member_id: Mapped[int] = mapped_column(
        ForeignKey("squad_member.id", ondelete="CASCADE"), primary_key=True
    )
    # +1 | -1
    value: Mapped[int] = mapped_column(SmallInteger)


class SquadComment(Base):
    __tablename__ = "squad_comment"

    id: Mapped[int] = mapped_column(primary_key=True)
    item_id: Mapped[int] = mapped_column(
        ForeignKey("squad_item.id", ondelete="CASCADE"), index=True
    )
    member_id: Mapped[int] = mapped_column(ForeignKey("squad_member.id", ondelete="CASCADE"))
    body: Mapped[str] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

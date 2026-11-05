from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class User(Base):
    __tablename__ = "user"

    id: Mapped[int] = mapped_column(primary_key=True)
    firebase_uid: Mapped[str] = mapped_column(String(128), unique=True)
    email: Mapped[str | None] = mapped_column(String(200))
    phone: Mapped[str | None] = mapped_column(String(30))
    city: Mapped[str | None] = mapped_column(String(80))
    # list of {bank_id, card_type}
    my_banks: Mapped[list] = mapped_column(JSONB, default=list)
    sizes_per_brand: Mapped[dict] = mapped_column(JSONB, default=dict)
    budget_prefs: Mapped[dict] = mapped_column(JSONB, default=dict)
    is_gold: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class DeviceToken(Base):
    __tablename__ = "device_token"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    fcm_token: Mapped[str] = mapped_column(String(300), unique=True)
    platform: Mapped[str] = mapped_column(String(10), default="android")
    topics: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class WatchItem(Base):
    __tablename__ = "watch_item"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    variant_id: Mapped[int | None] = mapped_column(ForeignKey("product_variant.id"))
    product_id: Mapped[int | None] = mapped_column(ForeignKey("product.id"))
    brand_id: Mapped[int | None] = mapped_column(ForeignKey("brand.id"))
    collection_url: Mapped[str | None] = mapped_column(String(500))
    # price_drop | restock | prelaunch
    kind: Mapped[str] = mapped_column(String(20))
    threshold_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    last_notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class PointsLedger(Base):
    __tablename__ = "points_ledger"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    delta: Mapped[int] = mapped_column()
    # streak | report_verified | order_confirmed | referral | rewarded_ad | redemption
    reason: Mapped[str] = mapped_column(String(30))
    ref_id: Mapped[str | None] = mapped_column(String(120))
    # pending | confirmed | reversed
    status: Mapped[str] = mapped_column(String(10), default="confirmed")
    idempotency_key: Mapped[str] = mapped_column(String(160), unique=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

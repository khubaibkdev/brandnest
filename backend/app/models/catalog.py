from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


class Brand(Base):
    __tablename__ = "brand"

    id: Mapped[int] = mapped_column(primary_key=True)
    slug: Mapped[str] = mapped_column(String(80), unique=True)
    name: Mapped[str] = mapped_column(String(120))
    website_url: Mapped[str] = mapped_column(String(300))
    logo_url: Mapped[str | None] = mapped_column(String(300))
    categories: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    # shopify | magento | salesforce_cc | custom
    platform: Mapped[str] = mapped_column(String(20), default="custom")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    priority_tier: Mapped[int] = mapped_column(default=2)

    config: Mapped["BrandConfig | None"] = relationship(back_populates="brand")
    products: Mapped[list["Product"]] = relationship(back_populates="brand")


class BrandConfig(Base):
    __tablename__ = "brand_config"

    brand_id: Mapped[int] = mapped_column(ForeignKey("brand.id"), primary_key=True)
    webview_user_agent: Mapped[str | None] = mapped_column(String(300))
    product_url_regex: Mapped[str | None] = mapped_column(String(300))
    checkout_domains: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    order_confirm_patterns: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    products_json_ok: Mapped[bool] = mapped_column(Boolean, default=False)
    sitemap_url: Mapped[str | None] = mapped_column(String(300))
    # What the sitemap actually lists: "products" (Sapphire) or "categories"
    # to page through for product links (Khaadi). Only salesforce_cc reads it.
    sitemap_lists: Mapped[str] = mapped_column(String(16), default="products")
    # F=nightly full, S=sale signals, W=watched, R=lawn radar (see CRAWLER_PLAYBOOK.md §2)
    frequency_tier: Mapped[str] = mapped_column(String(1), default="F")
    max_rps: Mapped[float | None] = mapped_column()
    toolbar_flags: Mapped[dict] = mapped_column(JSONB, default=dict)

    brand: Mapped[Brand] = relationship(back_populates="config")


class Product(Base):
    __tablename__ = "product"
    __table_args__ = (UniqueConstraint("brand_id", "external_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    brand_id: Mapped[int] = mapped_column(ForeignKey("brand.id"), index=True)
    external_id: Mapped[str] = mapped_column(String(80))
    source_url: Mapped[str] = mapped_column(String(500))
    title: Mapped[str] = mapped_column(String(300))
    description: Mapped[str | None] = mapped_column(Text)
    category: Mapped[str | None] = mapped_column(String(80))
    gender: Mapped[str | None] = mapped_column(String(20))
    tags: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    image_urls: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    thumb_r2_key: Mapped[str | None] = mapped_column(String(200))
    first_seen: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    last_seen: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)

    brand: Mapped[Brand] = relationship(back_populates="products")
    variants: Mapped[list["ProductVariant"]] = relationship(back_populates="product")


class ProductVariant(Base):
    __tablename__ = "product_variant"
    __table_args__ = (UniqueConstraint("product_id", "external_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("product.id"), index=True)
    external_id: Mapped[str] = mapped_column(String(80))
    size: Mapped[str | None] = mapped_column(String(60))
    color: Mapped[str | None] = mapped_column(String(60))
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    compare_at_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    in_stock: Mapped[bool] = mapped_column(Boolean, default=True)
    last_checked: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    product: Mapped[Product] = relationship(back_populates="variants")
    price_history: Mapped[list["PriceHistory"]] = relationship(back_populates="variant")


class PriceHistory(Base):
    __tablename__ = "price_history"
    __table_args__ = (UniqueConstraint("variant_id", "observed_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    variant_id: Mapped[int] = mapped_column(ForeignKey("product_variant.id"), index=True)
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    compare_at_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    in_stock: Mapped[bool] = mapped_column(Boolean)
    observed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    variant: Mapped[ProductVariant] = relationship(back_populates="price_history")

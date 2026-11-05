"""brand_config.sitemap_lists for category-discovery crawling

Revision ID: 2d4d39eec503
Revises: 95d26fc025a9
Create Date: 2026-09-03 11:41:08.798343

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '2d4d39eec503'
down_revision: Union[str, None] = '95d26fc025a9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "brand_config",
        sa.Column(
            "sitemap_lists",
            sa.String(length=16),
            nullable=False,
            server_default="products",
        ),
    )


def downgrade() -> None:
    op.drop_column("brand_config", "sitemap_lists")

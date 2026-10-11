"""add banner scheduling and campaign fields

Revision ID: a3272fa3e0df
Revises: 54f82dcd8729
Create Date: 2026-08-10 21:23:09.511179

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a3272fa3e0df'
down_revision: Union[str, Sequence[str], None] = '54f82dcd8729'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    op.add_column(
        "banners",
        sa.Column(
            "starts_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    op.add_column(
        "banners",
        sa.Column(
            "ends_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    op.add_column(
        "banners",
        sa.Column(
            "campaign_name",
            sa.String(length=150),
            nullable=True,
        ),
    )

    op.add_column(
        "banners",
        sa.Column(
            "priority",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
    )


def downgrade() -> None:
    """Downgrade schema."""

    op.drop_column("banners", "priority")
    op.drop_column("banners", "campaign_name")
    op.drop_column("banners", "ends_at")
    op.drop_column("banners", "starts_at")
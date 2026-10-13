"""Bounded discovery cache and free request accounting."""

from alembic import op
import sqlalchemy as sa

revision = "c26f71b9ea68"
down_revision = "b15e60a8df57"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "discovery_cache",
        sa.Column("key", sa.String(120), primary_key=True),
        sa.Column("kind", sa.String(20), nullable=False),
        sa.Column("city_id", sa.String(36), nullable=True),
        sa.Column("value", sa.Text(), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_discovery_cache_kind", "discovery_cache", ["kind"])
    op.create_index("ix_discovery_cache_city_id", "discovery_cache", ["city_id"])
    op.create_table(
        "discovery_budget",
        sa.Column("day", sa.String(10), primary_key=True),
        sa.Column("calls", sa.Integer(), nullable=False),
    )


def downgrade():
    op.drop_table("discovery_budget")
    op.drop_table("discovery_cache")

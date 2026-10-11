"""add AI billing settings and audit logs

Revision ID: c5eb2f28c930
Revises: fc864a944ac3
Create Date: 2026-08-16 00:49:01.011382
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c5eb2f28c930"
down_revision: Union[str, Sequence[str], None] = "fc864a944ac3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create AI billing settings and audit log tables."""

    op.create_table(
        "ai_billing_audit_logs",
        sa.Column(
            "action",
            sa.String(length=50),
            nullable=False,
        ),
        sa.Column(
            "previous_mode",
            sa.String(length=20),
            nullable=True,
        ),
        sa.Column(
            "new_mode",
            sa.String(length=20),
            nullable=False,
        ),
        sa.Column(
            "paid_enabled",
            sa.Boolean(),
            nullable=False,
        ),
        sa.Column(
            "paid_provider",
            sa.String(length=50),
            nullable=False,
        ),
        sa.Column(
            "daily_budget",
            sa.Float(),
            nullable=False,
        ),
        sa.Column(
            "monthly_budget",
            sa.Float(),
            nullable=False,
        ),
        sa.Column(
            "admin_id",
            sa.String(length=36),
            nullable=True,
        ),
        sa.Column(
            "details",
            sa.Text(),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "id",
            sa.String(length=36),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint(
            "id",
            name=op.f("pk_ai_billing_audit_logs"),
        ),
    )

    op.create_table(
        "ai_billing_settings",
        sa.Column(
            "paid_enabled",
            sa.Boolean(),
            nullable=False,
        ),
        sa.Column(
            "billing_mode",
            sa.String(length=20),
            nullable=False,
        ),
        sa.Column(
            "paid_provider",
            sa.String(length=50),
            nullable=False,
        ),
        sa.Column(
            "daily_budget",
            sa.Float(),
            nullable=False,
        ),
        sa.Column(
            "monthly_budget",
            sa.Float(),
            nullable=False,
        ),
        sa.Column(
            "daily_spent",
            sa.Float(),
            nullable=False,
        ),
        sa.Column(
            "monthly_spent",
            sa.Float(),
            nullable=False,
        ),
        sa.Column(
            "updated_by",
            sa.String(length=36),
            nullable=True,
        ),
        sa.Column(
            "id",
            sa.String(length=36),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text(
                "(CURRENT_TIMESTAMP)"
            ),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text(
                "(CURRENT_TIMESTAMP)"
            ),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint(
            "id",
            name=op.f("pk_ai_billing_settings"),
        ),
    )


def downgrade() -> None:
    """Remove AI billing tables."""

    op.drop_table("ai_billing_settings")
    op.drop_table("ai_billing_audit_logs")

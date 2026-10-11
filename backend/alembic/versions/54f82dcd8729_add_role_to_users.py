"""add role to users

Revision ID: 54f82dcd8729
Revises: 4372f8576aab
Create Date: 2026-08-10 18:50:04.466425
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "54f82dcd8729"
down_revision: Union[str, Sequence[str], None] = "4372f8576aab"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add role to users."""

    op.add_column(
        "users",
        sa.Column(
            "role",
            sa.String(length=30),
            nullable=False,
            server_default="user",
        ),
    )

    op.create_index(
        "ix_users_role",
        "users",
        ["role"],
        unique=False,
    )


def downgrade() -> None:
    """Remove role from users."""

    op.drop_index(
        "ix_users_role",
        table_name="users",
    )

    op.drop_column(
        "users",
        "role",
    )
"""create destination photos table

Revision ID: c1a_destination_photos
Revises: a3272fa3e0df
"""

from typing import Sequence
from typing import Union

from alembic import op
import sqlalchemy as sa


revision: str = "c1a_destination_photos"

down_revision: Union[
    str,
    Sequence[str],
    None,
] = "a3272fa3e0df"

branch_labels = None
depends_on = None


def upgrade() -> None:

    op.create_table(
        "destination_photos",

        sa.Column(
            "destination_id",
            sa.String(length=36),
            nullable=False,
        ),

        sa.Column(
            "image_url",
            sa.String(length=1000),
            nullable=False,
        ),

        sa.Column(
            "caption",
            sa.String(length=300),
            nullable=True,
        ),

        sa.Column(
            "display_order",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),

        sa.Column(
            "is_cover",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),

        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
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
                "CURRENT_TIMESTAMP",
            ),
            nullable=False,
        ),

        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text(
                "CURRENT_TIMESTAMP",
            ),
            nullable=False,
        ),

        sa.Column(
            "is_deleted",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),

        sa.Column(
            "deleted_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),

        sa.ForeignKeyConstraint(
            ["destination_id"],
            ["destinations.id"],
            name="fk_destination_photos_destination_id_destinations",
            ondelete="CASCADE",
        ),

        sa.PrimaryKeyConstraint(
            "id",
            name="pk_destination_photos",
        ),
    )

    op.create_index(
        "ix_destination_photos_destination_id",
        "destination_photos",
        ["destination_id"],
        unique=False,
    )

    op.create_index(
        "ix_destination_photos_display_order",
        "destination_photos",
        ["display_order"],
        unique=False,
    )


def downgrade() -> None:

    op.drop_index(
        "ix_destination_photos_display_order",
        table_name="destination_photos",
    )

    op.drop_index(
        "ix_destination_photos_destination_id",
        table_name="destination_photos",
    )

    op.drop_table("destination_photos")
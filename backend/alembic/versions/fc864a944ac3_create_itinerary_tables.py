"""create itinerary tables

Revision ID: fc864a944ac3
Revises: 9b7abbe6a81e
Create Date: 2026-08-14 00:23:26.209990
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "fc864a944ac3"
down_revision: Union[str, Sequence[str], None] = "9b7abbe6a81e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create itinerary tables."""

    # ==========================================================
    # Itinerary Days
    # ==========================================================

    op.create_table(
        "itinerary_days",

        sa.Column(
            "id",
            sa.String(length=36),
            nullable=False,
        ),

        sa.Column(
            "trip_id",
            sa.String(length=36),
            nullable=False,
        ),

        sa.Column(
            "day_number",
            sa.Integer(),
            nullable=False,
        ),

        sa.Column(
            "date",
            sa.Date(),
            nullable=False,
        ),

        sa.Column(
            "title",
            sa.String(length=200),
            nullable=True,
        ),

        sa.Column(
            "notes",
            sa.Text(),
            nullable=True,
        ),

        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),

        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),

        sa.PrimaryKeyConstraint(
            "id",
            name="pk_itinerary_days",
        ),

        sa.ForeignKeyConstraint(
            ["trip_id"],
            ["trips.id"],
            name="fk_itinerary_days_trip_id_trips",
        ),

        sa.UniqueConstraint(
            "trip_id",
            "day_number",
            name="uq_itinerary_day_trip_day",
        ),
    )

    op.create_index(
        "ix_itinerary_days_trip_id",
        "itinerary_days",
        ["trip_id"],
    )

    op.create_index(
        "ix_itinerary_days_date",
        "itinerary_days",
        ["date"],
    )

    # ==========================================================
    # Itinerary Items
    # ==========================================================

    op.create_table(
        "itinerary_items",

        sa.Column(
            "id",
            sa.String(length=36),
            nullable=False,
        ),

        sa.Column(
            "itinerary_day_id",
            sa.String(length=36),
            nullable=False,
        ),

        # ------------------------------------------------------
        # Optional Place
        # ------------------------------------------------------

        sa.Column(
            "place_id",
            sa.String(length=36),
            nullable=True,
        ),

        # ------------------------------------------------------
        # Basic Information
        # ------------------------------------------------------

        sa.Column(
            "title",
            sa.String(length=200),
            nullable=False,
        ),

        sa.Column(
            "description",
            sa.Text(),
            nullable=True,
        ),

        # ------------------------------------------------------
        # Activity
        # ------------------------------------------------------

        sa.Column(
            "activity_type",
            sa.String(length=80),
            nullable=False,
            server_default="activity",
        ),

        # ------------------------------------------------------
        # Timing
        # ------------------------------------------------------

        sa.Column(
            "start_time",
            sa.Time(),
            nullable=True,
        ),

        sa.Column(
            "end_time",
            sa.Time(),
            nullable=True,
        ),

        sa.Column(
            "estimated_duration_minutes",
            sa.Integer(),
            nullable=True,
        ),

        # ------------------------------------------------------
        # Ordering
        # ------------------------------------------------------

        sa.Column(
            "sequence",
            sa.Integer(),
            nullable=False,
            server_default="1",
        ),

        # ------------------------------------------------------
        # Transportation
        # ------------------------------------------------------

        sa.Column(
            "transport_mode",
            sa.String(length=50),
            nullable=True,
        ),

        # ------------------------------------------------------
        # Location
        # ------------------------------------------------------

        sa.Column(
            "latitude",
            sa.Numeric(
                precision=10,
                scale=6,
            ),
            nullable=True,
        ),

        sa.Column(
            "longitude",
            sa.Numeric(
                precision=10,
                scale=6,
            ),
            nullable=True,
        ),

        # ------------------------------------------------------
        # Notes
        # ------------------------------------------------------

        sa.Column(
            "notes",
            sa.Text(),
            nullable=True,
        ),

        # ------------------------------------------------------
        # Timestamps
        # ------------------------------------------------------

        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),

        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),

        # ------------------------------------------------------
        # Primary Key
        # ------------------------------------------------------

        sa.PrimaryKeyConstraint(
            "id",
            name="pk_itinerary_items",
        ),

        # ------------------------------------------------------
        # Foreign Keys
        # ------------------------------------------------------

        sa.ForeignKeyConstraint(
            ["itinerary_day_id"],
            ["itinerary_days.id"],
            name="fk_itinerary_items_day_id_itinerary_days",
        ),

        sa.ForeignKeyConstraint(
            ["place_id"],
            ["places.id"],
            name="fk_itinerary_items_place_id_places",
        ),
    )

    op.create_index(
        "ix_itinerary_items_day_id",
        "itinerary_items",
        ["itinerary_day_id"],
    )

    op.create_index(
        "ix_itinerary_items_place_id",
        "itinerary_items",
        ["place_id"],
    )

    op.create_index(
        "ix_itinerary_items_sequence",
        "itinerary_items",
        ["sequence"],
    )


def downgrade() -> None:
    """Drop itinerary tables."""

    op.drop_index(
        "ix_itinerary_items_sequence",
        table_name="itinerary_items",
    )

    op.drop_index(
        "ix_itinerary_items_place_id",
        table_name="itinerary_items",
    )

    op.drop_index(
        "ix_itinerary_items_day_id",
        table_name="itinerary_items",
    )

    op.drop_table("itinerary_items")

    op.drop_index(
        "ix_itinerary_days_date",
        table_name="itinerary_days",
    )

    op.drop_index(
        "ix_itinerary_days_trip_id",
        table_name="itinerary_days",
    )

    op.drop_table("itinerary_days")
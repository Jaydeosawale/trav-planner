"""create trips table

Revision ID: 9b7abbe6a81e
Revises: create_user_travel_behavior
Create Date: 2026-08-13 23:58:14.097575
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "9b7abbe6a81e"
down_revision: Union[str, Sequence[str], None] = "create_user_travel_behavior"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create trips table."""

    op.create_table(
        "trips",

        # ======================================================
        # Primary Key
        # ======================================================

        sa.Column(
            "id",
            sa.String(length=36),
            nullable=False,
        ),

        # ======================================================
        # Ownership
        # ======================================================

        sa.Column(
            "user_id",
            sa.String(length=36),
            nullable=False,
        ),

        # ======================================================
        # Source Planner
        # ======================================================

        sa.Column(
            "planner_id",
            sa.String(length=36),
            nullable=True,
        ),

        # ======================================================
        # Destination
        # ======================================================

        sa.Column(
            "destination_id",
            sa.String(length=36),
            nullable=False,
        ),

        # ======================================================
        # Basic Information
        # ======================================================

        sa.Column(
            "title",
            sa.String(length=200),
            nullable=False,
        ),

        # ======================================================
        # Travel Dates
        # ======================================================

        sa.Column(
            "start_date",
            sa.Date(),
            nullable=False,
        ),

        sa.Column(
            "end_date",
            sa.Date(),
            nullable=False,
        ),

        # ======================================================
        # Travelers
        # ======================================================

        sa.Column(
            "travelers",
            sa.Integer(),
            nullable=False,
            server_default="1",
        ),

        # ======================================================
        # Budget
        # ======================================================

        sa.Column(
            "budget_amount",
            sa.Numeric(
                precision=12,
                scale=2,
            ),
            nullable=True,
        ),

        sa.Column(
            "budget_currency",
            sa.String(length=3),
            nullable=False,
            server_default="INR",
        ),

        # ======================================================
        # Travel Preferences
        # ======================================================

        sa.Column(
            "travel_style",
            sa.String(length=100),
            nullable=True,
        ),

        sa.Column(
            "notes",
            sa.Text(),
            nullable=True,
        ),

        # ======================================================
        # Status
        # ======================================================

        sa.Column(
            "status",
            sa.String(length=50),
            nullable=False,
            server_default="planned",
        ),

        # ======================================================
        # Timestamps
        # ======================================================

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

        # ======================================================
        # Soft Delete
        # ======================================================

        sa.Column(
            "is_deleted",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),

        sa.Column(
            "deleted_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),

        # ======================================================
        # Constraints
        # ======================================================

        sa.PrimaryKeyConstraint(
            "id",
            name="pk_trips",
        ),

        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_trips_user_id_users",
        ),

        sa.ForeignKeyConstraint(
            ["planner_id"],
            ["planners.id"],
            name="fk_trips_planner_id_planners",
        ),

        sa.ForeignKeyConstraint(
            ["destination_id"],
            ["destinations.id"],
            name="fk_trips_destination_id_destinations",
        ),
    )

    # ==========================================================
    # Indexes
    # ==========================================================

    op.create_index(
        "ix_trips_user_id",
        "trips",
        ["user_id"],
    )

    op.create_index(
        "ix_trips_planner_id",
        "trips",
        ["planner_id"],
    )

    op.create_index(
        "ix_trips_destination_id",
        "trips",
        ["destination_id"],
    )

    op.create_index(
        "ix_trips_status",
        "trips",
        ["status"],
    )

    op.create_index(
        "ix_trips_start_date",
        "trips",
        ["start_date"],
    )

    op.create_index(
        "ix_trips_end_date",
        "trips",
        ["end_date"],
    )


def downgrade() -> None:
    """Drop trips table."""

    op.drop_index(
        "ix_trips_end_date",
        table_name="trips",
    )

    op.drop_index(
        "ix_trips_start_date",
        table_name="trips",
    )

    op.drop_index(
        "ix_trips_status",
        table_name="trips",
    )

    op.drop_index(
        "ix_trips_destination_id",
        table_name="trips",
    )

    op.drop_index(
        "ix_trips_planner_id",
        table_name="trips",
    )

    op.drop_index(
        "ix_trips_user_id",
        table_name="trips",
    )

    op.drop_table("trips")
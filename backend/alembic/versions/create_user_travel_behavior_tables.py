"""create user travel behavior tables."""

from typing import Sequence
from typing import Union

from alembic import op
import sqlalchemy as sa


revision: str = "create_user_travel_behavior"
down_revision: Union[str, Sequence[str], None] = "69c5dde0da8d"
branch_labels = None
depends_on = None


def upgrade() -> None:

    # ======================================================
    # Travel Profile
    # ======================================================

    op.create_table(
        "user_travel_profiles",

        sa.Column(
            "id",
            sa.String(36),
            primary_key=True,
            nullable=False,
        ),

        sa.Column(
            "user_id",
            sa.String(36),
            nullable=False,
        ),

        sa.Column(
            "travel_style",
            sa.String(100),
            nullable=True,
        ),

        sa.Column(
            "budget_level",
            sa.String(50),
            nullable=True,
        ),

        sa.Column(
            "preferred_transport",
            sa.String(100),
            nullable=True,
        ),

        sa.Column(
            "accommodation_preference",
            sa.String(100),
            nullable=True,
        ),

        sa.Column(
            "food_preference",
            sa.String(100),
            nullable=True,
        ),

        sa.Column(
            "interests",
            sa.Text(),
            nullable=True,
        ),

        sa.Column(
            "other_preferences",
            sa.Text(),
            nullable=True,
        ),

        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),

        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),

        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_user_travel_profiles_user_id_users",
        ),

        sa.UniqueConstraint(
            "user_id",
            name="uq_user_travel_profiles_user_id",
        ),
    )

    op.create_index(
        "ix_user_travel_profiles_user_id",
        "user_travel_profiles",
        ["user_id"],
    )

    # ======================================================
    # Search History
    # ======================================================

    op.create_table(
        "user_search_history",

        sa.Column(
            "id",
            sa.String(36),
            primary_key=True,
            nullable=False,
        ),

        sa.Column(
            "user_id",
            sa.String(36),
            nullable=False,
        ),

        sa.Column(
            "query",
            sa.String(500),
            nullable=False,
        ),

        sa.Column(
            "search_type",
            sa.String(50),
            nullable=False,
            server_default="place",
        ),

        sa.Column(
            "filters_text",
            sa.Text(),
            nullable=True,
        ),

        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),

        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
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
            ["user_id"],
            ["users.id"],
            name="fk_user_search_history_user_id_users",
        ),
    )

    op.create_index(
        "ix_user_search_history_user_id",
        "user_search_history",
        ["user_id"],
    )

    # ======================================================
    # Likes
    # ======================================================

    op.create_table(
        "user_place_likes",

        sa.Column(
            "id",
            sa.String(36),
            primary_key=True,
            nullable=False,
        ),

        sa.Column(
            "user_id",
            sa.String(36),
            nullable=False,
        ),

        sa.Column(
            "place_id",
            sa.String(36),
            nullable=False,
        ),

        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),

        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),

        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_user_place_likes_user_id_users",
        ),

        sa.ForeignKeyConstraint(
            ["place_id"],
            ["places.id"],
            name="fk_user_place_likes_place_id_places",
        ),

        sa.UniqueConstraint(
            "user_id",
            "place_id",
            name="uq_user_place_like",
        ),
    )

    op.create_index(
        "ix_user_place_likes_user_id",
        "user_place_likes",
        ["user_id"],
    )

    op.create_index(
        "ix_user_place_likes_place_id",
        "user_place_likes",
        ["place_id"],
    )

    # ======================================================
    # Saves
    # ======================================================

    op.create_table(
        "user_place_saves",

        sa.Column(
            "id",
            sa.String(36),
            primary_key=True,
            nullable=False,
        ),

        sa.Column(
            "user_id",
            sa.String(36),
            nullable=False,
        ),

        sa.Column(
            "place_id",
            sa.String(36),
            nullable=False,
        ),

        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),

        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),

        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_user_place_saves_user_id_users",
        ),

        sa.ForeignKeyConstraint(
            ["place_id"],
            ["places.id"],
            name="fk_user_place_saves_place_id_places",
        ),

        sa.UniqueConstraint(
            "user_id",
            "place_id",
            name="uq_user_place_save",
        ),
    )

    op.create_index(
        "ix_user_place_saves_user_id",
        "user_place_saves",
        ["user_id"],
    )

    op.create_index(
        "ix_user_place_saves_place_id",
        "user_place_saves",
        ["place_id"],
    )

    # ======================================================
    # Views
    # ======================================================

    op.create_table(
        "user_place_views",

        sa.Column(
            "id",
            sa.String(36),
            primary_key=True,
            nullable=False,
        ),

        sa.Column(
            "user_id",
            sa.String(36),
            nullable=False,
        ),

        sa.Column(
            "place_id",
            sa.String(36),
            nullable=False,
        ),

        sa.Column(
            "viewed_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),

        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_user_place_views_user_id_users",
        ),

        sa.ForeignKeyConstraint(
            ["place_id"],
            ["places.id"],
            name="fk_user_place_views_place_id_places",
        ),
    )

    op.create_index(
        "ix_user_place_views_user_id",
        "user_place_views",
        ["user_id"],
    )

    op.create_index(
        "ix_user_place_views_place_id",
        "user_place_views",
        ["place_id"],
    )


def downgrade() -> None:

    op.drop_table("user_place_views")
    op.drop_table("user_place_saves")
    op.drop_table("user_place_likes")
    op.drop_table("user_search_history")
    op.drop_table("user_travel_profiles")
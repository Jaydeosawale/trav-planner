"""
Create places table.

Revision ID: 69c5dde0da8d
Revises: c1a_destination_photos
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# ==========================================================
# Revision identifiers
# ==========================================================

revision: str = "69c5dde0da8d"

down_revision: Union[str, Sequence[str], None] = (
    "c1a_destination_photos"
)

branch_labels: Union[str, Sequence[str], None] = None

depends_on: Union[str, Sequence[str], None] = None


# ==========================================================
# Upgrade
# ==========================================================

def upgrade() -> None:
    """
    Create places table.
    """

    op.create_table(
        "places",

        # --------------------------------------------------
        # Location
        # --------------------------------------------------

        sa.Column(
            "city_id",
            sa.String(length=36),
            nullable=False,
        ),

        sa.Column(
            "category_id",
            sa.String(length=36),
            nullable=True,
        ),

        # --------------------------------------------------
        # Basic Information
        # --------------------------------------------------

        sa.Column(
            "name",
            sa.String(length=200),
            nullable=False,
        ),

        sa.Column(
            "slug",
            sa.String(length=220),
            nullable=False,
        ),

        sa.Column(
            "place_type",
            sa.String(length=80),
            nullable=False,
        ),

        sa.Column(
            "short_description",
            sa.String(length=500),
            nullable=True,
        ),

        sa.Column(
            "description",
            sa.Text(),
            nullable=True,
        ),

        # --------------------------------------------------
        # Address
        # --------------------------------------------------

        sa.Column(
            "address",
            sa.String(length=500),
            nullable=True,
        ),

        sa.Column(
            "locality",
            sa.String(length=150),
            nullable=True,
        ),

        sa.Column(
            "postal_code",
            sa.String(length=30),
            nullable=True,
        ),

        # --------------------------------------------------
        # Coordinates
        # --------------------------------------------------

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

        # --------------------------------------------------
        # Media
        # --------------------------------------------------

        sa.Column(
            "image_url",
            sa.String(length=500),
            nullable=True,
        ),

        # --------------------------------------------------
        # External Provider
        # --------------------------------------------------

        sa.Column(
            "provider",
            sa.String(length=50),
            nullable=True,
        ),

        sa.Column(
            "external_place_id",
            sa.String(length=200),
            nullable=True,
        ),

        # --------------------------------------------------
        # Discovery
        # --------------------------------------------------

        sa.Column(
            "rating",
            sa.Numeric(
                precision=3,
                scale=2,
            ),
            nullable=True,
        ),

        sa.Column(
            "price_level",
            sa.Integer(),
            nullable=True,
        ),

        sa.Column(
            "is_featured",
            sa.Boolean(),
            nullable=False,
        ),

        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
        ),

        # --------------------------------------------------
        # Common Base Fields
        # --------------------------------------------------

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

        sa.Column(
            "is_deleted",
            sa.Boolean(),
            nullable=False,
        ),

        sa.Column(
            "deleted_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),

        # --------------------------------------------------
        # Foreign Keys
        # --------------------------------------------------

        sa.ForeignKeyConstraint(
            ["category_id"],
            ["categories.id"],
            name=op.f(
                "fk_places_category_id_categories"
            ),
        ),

        sa.ForeignKeyConstraint(
            ["city_id"],
            ["cities.id"],
            name=op.f(
                "fk_places_city_id_cities"
            ),
        ),

        # --------------------------------------------------
        # Primary Key
        # --------------------------------------------------

        sa.PrimaryKeyConstraint(
            "id",
            name=op.f("pk_places"),
        ),
    )

    # ======================================================
    # Indexes
    # ======================================================

    op.create_index(
        op.f("ix_places_category_id"),
        "places",
        ["category_id"],
        unique=False,
    )

    op.create_index(
        op.f("ix_places_city_id"),
        "places",
        ["city_id"],
        unique=False,
    )

    op.create_index(
        op.f("ix_places_external_place_id"),
        "places",
        ["external_place_id"],
        unique=False,
    )

    op.create_index(
        op.f("ix_places_locality"),
        "places",
        ["locality"],
        unique=False,
    )

    op.create_index(
        op.f("ix_places_name"),
        "places",
        ["name"],
        unique=False,
    )

    op.create_index(
        op.f("ix_places_place_type"),
        "places",
        ["place_type"],
        unique=False,
    )

    op.create_index(
        op.f("ix_places_provider"),
        "places",
        ["provider"],
        unique=False,
    )

    op.create_index(
        op.f("ix_places_slug"),
        "places",
        ["slug"],
        unique=True,
    )


# ==========================================================
# Downgrade
# ==========================================================

def downgrade() -> None:
    """
    Remove places table.
    """

    op.drop_index(
        op.f("ix_places_slug"),
        table_name="places",
    )

    op.drop_index(
        op.f("ix_places_provider"),
        table_name="places",
    )

    op.drop_index(
        op.f("ix_places_place_type"),
        table_name="places",
    )

    op.drop_index(
        op.f("ix_places_name"),
        table_name="places",
    )

    op.drop_index(
        op.f("ix_places_locality"),
        table_name="places",
    )

    op.drop_index(
        op.f("ix_places_external_place_id"),
        table_name="places",
    )

    op.drop_index(
        op.f("ix_places_city_id"),
        table_name="places",
    )

    op.drop_index(
        op.f("ix_places_category_id"),
        table_name="places",
    )

    op.drop_table("places")
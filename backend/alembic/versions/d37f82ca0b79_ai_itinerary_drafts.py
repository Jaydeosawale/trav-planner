from alembic import op
import sqlalchemy as sa

revision = "d37f82ca0b79"
down_revision = "c26f71b9ea68"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "ai_itinerary_drafts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), nullable=False),
        sa.Column("city_id", sa.String(36), nullable=False),
        sa.Column("content_json", sa.Text(), nullable=False),
        sa.Column("trip_id", sa.String(36), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_ai_itinerary_drafts_user_id", "ai_itinerary_drafts", ["user_id"]
    )


def downgrade():
    op.drop_table("ai_itinerary_drafts")

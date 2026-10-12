"""Persistent zero-cost AI provider routing."""

from alembic import op
import sqlalchemy as sa

revision = "f92c48e6bd35"
down_revision = "e81f37b5ac24"
branch_labels = None
depends_on = None


def upgrade():
    table = op.create_table(
        "ai_routing_settings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("provider_order", sa.Text(), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("updated_by", sa.String(36), nullable=True),
    )
    op.create_table(
        "ai_usage_records",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("provider", sa.String(30), nullable=False),
        sa.Column("model", sa.String(100), nullable=True),
        sa.Column("succeeded", sa.Boolean(), nullable=False),
        sa.Column("input_tokens", sa.Integer(), nullable=True),
        sa.Column("output_tokens", sa.Integer(), nullable=True),
        sa.Column("total_tokens", sa.Integer(), nullable=True),
        sa.Column("error_category", sa.String(30), nullable=True),
    )
    op.create_index(
        "ix_ai_usage_records_created_at", "ai_usage_records", ["created_at"]
    )
    op.bulk_insert(
        table,
        [{"id": 1, "provider_order": '["openai","groq","gemini"]', "enabled": True}],
    )


def downgrade():
    op.drop_table("ai_usage_records")
    op.drop_table("ai_routing_settings")

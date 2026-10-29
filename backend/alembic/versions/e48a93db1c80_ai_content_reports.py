"""Persist in-app AI content reports for moderation."""
from alembic import op
import sqlalchemy as sa
revision = 'e48a93db1c80'
down_revision = 'd37f82ca0b79'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('ai_content_reports',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('user_id', sa.String(36), nullable=False),
        sa.Column('source_kind', sa.String(20), nullable=False),
        sa.Column('reference_id', sa.String(36), nullable=False),
        sa.Column('reason', sa.String(40), nullable=False),
        sa.Column('details', sa.Text(), nullable=False),
        sa.Column('content_excerpt', sa.Text(), nullable=False),
        sa.Column('status', sa.String(20), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()))
    op.create_index('ix_ai_content_reports_user_id', 'ai_content_reports', ['user_id'])

def downgrade():
    op.drop_table('ai_content_reports')

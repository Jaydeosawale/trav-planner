"""Owned planner briefs and bounded conversation context."""
from alembic import op
import sqlalchemy as sa
revision = 'a04d59f7ce46'
down_revision = 'f92c48e6bd35'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('planner_conversations',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('user_id', sa.String(36), nullable=False),
        sa.Column('title', sa.String(120), nullable=False),
        sa.Column('brief_json', sa.Text(), nullable=False),
        sa.Column('turns_json', sa.Text(), nullable=False),
        sa.Column('version', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False))
    op.create_index('ix_planner_conversations_user_id', 'planner_conversations', ['user_id'])


def downgrade():
    op.drop_table('planner_conversations')

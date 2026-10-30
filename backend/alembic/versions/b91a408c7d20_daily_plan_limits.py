"""Daily per-account completed-plan allowance."""
from alembic import op
import sqlalchemy as sa
revision = 'b91a408c7d20'
down_revision = 'e48a93db1c80'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('ai_daily_plan_usage',
        sa.Column('user_id', sa.String(36), primary_key=True),
        sa.Column('day', sa.Date(), primary_key=True),
        sa.Column('used', sa.Integer(), nullable=False, server_default='0'))

def downgrade():
    op.drop_table('ai_daily_plan_usage')

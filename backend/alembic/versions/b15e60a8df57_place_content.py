"""Reviewed place photos and visiting notes."""
from alembic import op
import sqlalchemy as sa
revision='b15e60a8df57'
down_revision='a04d59f7ce46'
branch_labels=None
depends_on=None

def upgrade():
    op.add_column('places',sa.Column('image_credit',sa.Text(),nullable=True))
    op.add_column('places',sa.Column('visiting_notes',sa.Text(),nullable=True))
    op.add_column('places',sa.Column('content_revision',sa.String(30),nullable=True))

def downgrade():
    for field in ['content_revision','visiting_notes','image_credit']:
        op.drop_column('places',field)

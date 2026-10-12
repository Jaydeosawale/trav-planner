"""Allow owned trips to any published catalogue city without creating master data."""
from alembic import op
import sqlalchemy as sa

revision = 'e81f37b5ac24'
down_revision = 'd71a3c1f8b20'
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('trips', sa.Column('city_id', sa.String(36), nullable=True))
    op.create_foreign_key('fk_trips_city_id_cities', 'trips', 'cities', ['city_id'], ['id'])
    op.create_index('ix_trips_city_id', 'trips', ['city_id'])
    op.execute('UPDATE trips SET city_id = (SELECT city_id FROM destinations WHERE destinations.id = trips.destination_id)')
    op.alter_column('trips', 'destination_id', existing_type=sa.String(36), nullable=True)

def downgrade():
    connection = op.get_bind()
    if connection.execute(sa.text('SELECT COUNT(*) FROM trips WHERE destination_id IS NULL')).scalar():
        raise RuntimeError('City-only trips must be migrated before downgrading; no trip data was deleted.')
    op.alter_column('trips', 'destination_id', existing_type=sa.String(36), nullable=False)
    op.drop_index('ix_trips_city_id', table_name='trips')
    op.drop_constraint('fk_trips_city_id_cities', 'trips', type_='foreignkey')
    op.drop_column('trips', 'city_id')

"""
Remove state name unique constraint.

State identity is country + state code.
"""

from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "06c9e1683709"
down_revision: Union[str, Sequence[str], None] = "f7a4ae1e9630"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """
    Remove country + state name uniqueness.

    State names are not guaranteed to be unique
    within a country. State codes are the unique
    identifier within a country.
    """
    with op.batch_alter_table("states") as batch_op:
        batch_op.drop_constraint(
            "uq_states_country_name",
            type_="unique",
        )


def downgrade() -> None:
    """
    Restore country + state name uniqueness.
    """
    with op.batch_alter_table("states") as batch_op:
        batch_op.create_unique_constraint(
            "uq_states_country_name",
            ["country_id", "name"],
        )
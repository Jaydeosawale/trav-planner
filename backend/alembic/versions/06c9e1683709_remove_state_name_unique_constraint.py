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

    op.drop_constraint(
        "uq_states_country_name",
        "states",
        type_="unique",
    )


def downgrade() -> None:
    """
    Restore country + state name uniqueness.
    """

    op.create_unique_constraint(
        "uq_states_country_name",
        "states",
        ["country_id", "name"],
    )

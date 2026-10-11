from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class BillingMode(str, Enum):
    """
    Controls how paid AI usage is handled.

    FREE_ONLY:
        Never use paid AI.

    SOFT:
        Paid AI can be used only when explicitly enabled
        and according to the configured budget.

    HARD:
        Admin explicitly allows paid AI as a persistent
        fallback policy.
    """

    FREE_ONLY = "free_only"
    SOFT = "soft"
    HARD = "hard"


@dataclass
class BillingPolicy:
    """
    Central safety policy for paid AI usage.

    IMPORTANT:
    paid_enabled=False is the default.

    Therefore a paid request can NEVER happen unless
    Admin explicitly enables it.
    """

    paid_enabled: bool = False

    mode: BillingMode = BillingMode.FREE_ONLY

    daily_budget: float = 0.0
    monthly_budget: float = 0.0

    daily_spent: float = 0.0
    monthly_spent: float = 0.0

    def can_use_paid(self) -> bool:
        """
        Determine whether a paid AI request is allowed.
        """

        # Absolute safety gate.
        if not self.paid_enabled:
            return False

        # FREE_ONLY always blocks paid usage.
        if self.mode == BillingMode.FREE_ONLY:
            return False

        # Daily budget.
        if (
            self.daily_budget > 0
            and self.daily_spent >= self.daily_budget
        ):
            return False

        # Monthly budget.
        if (
            self.monthly_budget > 0
            and self.monthly_spent >= self.monthly_budget
        ):
            return False

        return True

    def record_cost(self, amount: float) -> None:
        """
        Record a paid AI cost.
        """

        if amount < 0:
            raise ValueError(
                "AI cost cannot be negative."
            )

        self.daily_spent += amount
        self.monthly_spent += amount

    def remaining_daily_budget(self) -> float | None:
        """
        Return remaining daily budget.

        None means no daily budget has been configured.
        """

        if self.daily_budget <= 0:
            return None

        return max(
            self.daily_budget - self.daily_spent,
            0.0,
        )

    def remaining_monthly_budget(self) -> float | None:
        """
        Return remaining monthly budget.

        None means no monthly budget has been configured.
        """

        if self.monthly_budget <= 0:
            return None

        return max(
            self.monthly_budget - self.monthly_spent,
            0.0,
        )
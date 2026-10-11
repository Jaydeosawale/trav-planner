from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.admin.repository import (
    AIBillingRepository,
)
from app.services.ai.billing_policy import (
    BillingMode,
    BillingPolicy,
)


@dataclass
class AdminBillingState:
    """
    Current Admin-controlled AI billing state.
    """

    paid_enabled: bool
    mode: BillingMode

    paid_provider: str

    daily_budget: float
    monthly_budget: float

    daily_spent: float
    monthly_spent: float

    updated_by: str | None = None


class AdminBillingService:
    """
    Admin-controlled AI billing service.

    Responsibilities:

        PostgreSQL
            ↓
        persistent configuration
            ↓
        BillingPolicy

    IMPORTANT:

    This service does not bypass BillingPolicy.

    Paid AI is allowed only when BillingPolicy explicitly
    authorizes it.
    """

    def __init__(
        self,
        *,
        billing_policy: BillingPolicy,
        paid_provider: str = "groq",
    ) -> None:

        self._policy = billing_policy

        self._paid_provider = (
            paid_provider.strip().lower()
        )

        self._updated_by: str | None = None

    # ==========================================================
    # PROVIDER VALIDATION
    # ==========================================================

    @staticmethod
    def _validate_provider(
        provider: str,
    ) -> str:

        normalized = provider.strip().lower()

        supported = {
            "groq",
            "gemini",
            "ollama",
        }

        if normalized not in supported:
            raise ValueError(
                f"Unsupported paid AI provider: {provider}"
            )

        return normalized

    # ==========================================================
    # BUDGET VALIDATION
    # ==========================================================

    @staticmethod
    def _validate_budget(
        amount: float,
        name: str,
    ) -> float:

        if amount < 0:
            raise ValueError(
                f"{name} cannot be negative."
            )

        return float(amount)

    # ==========================================================
    # STATE
    # ==========================================================

    def get_state(self) -> AdminBillingState:
        """
        Return current runtime billing state.
        """

        return AdminBillingState(
            paid_enabled=self._policy.paid_enabled,
            mode=self._policy.mode,
            paid_provider=self._paid_provider,
            daily_budget=self._policy.daily_budget,
            monthly_budget=self._policy.monthly_budget,
            daily_spent=self._policy.daily_spent,
            monthly_spent=self._policy.monthly_spent,
            updated_by=self._updated_by,
        )

    # ==========================================================
    # LOAD FROM DATABASE
    # ==========================================================

    async def load_from_database(
        self,
        db: AsyncSession,
    ) -> AdminBillingState:
        """
        Load persistent Admin billing configuration.

        If no configuration exists, create a safe default:

            paid_enabled = False
            mode = FREE_ONLY
            provider = groq
        """

        settings = (
            await AIBillingRepository.get_settings(db)
        )

        if settings is None:

            settings = (
                await AIBillingRepository.create_settings(
                    db,
                    paid_enabled=False,
                    billing_mode=(
                        BillingMode.FREE_ONLY.value
                    ),
                    paid_provider=self._paid_provider,
                    daily_budget=0.0,
                    monthly_budget=0.0,
                    daily_spent=0.0,
                    monthly_spent=0.0,
                    updated_by=None,
                )
            )

            await db.commit()

        self._apply_database_state(settings)

        return self.get_state()

    # ==========================================================
    # APPLY DATABASE STATE
    # ==========================================================

    def _apply_database_state(
        self,
        settings,
    ) -> None:

        try:
            mode = BillingMode(
                settings.billing_mode
            )
        except ValueError as exc:
            raise ValueError(
                "Invalid billing mode stored in database: "
                f"{settings.billing_mode}"
            ) from exc

        self._policy.paid_enabled = (
            settings.paid_enabled
        )

        self._policy.mode = mode

        self._policy.daily_budget = (
            settings.daily_budget
        )

        self._policy.monthly_budget = (
            settings.monthly_budget
        )

        self._policy.daily_spent = (
            settings.daily_spent
        )

        self._policy.monthly_spent = (
            settings.monthly_spent
        )

        self._paid_provider = (
            self._validate_provider(
                settings.paid_provider
            )
        )

        self._updated_by = (
            settings.updated_by
        )

    # ==========================================================
    # PERSIST CURRENT STATE
    # ==========================================================

    async def _persist(
        self,
        db: AsyncSession,
        *,
        action: str,
        previous_mode: str | None,
        admin_id: str | None,
        details: str | None = None,
    ) -> AdminBillingState:

        settings = (
            await AIBillingRepository.get_settings(db)
        )

        if settings is None:

            settings = (
                await AIBillingRepository.create_settings(
                    db,
                    paid_enabled=(
                        self._policy.paid_enabled
                    ),
                    billing_mode=(
                        self._policy.mode.value
                    ),
                    paid_provider=(
                        self._paid_provider
                    ),
                    daily_budget=(
                        self._policy.daily_budget
                    ),
                    monthly_budget=(
                        self._policy.monthly_budget
                    ),
                    daily_spent=(
                        self._policy.daily_spent
                    ),
                    monthly_spent=(
                        self._policy.monthly_spent
                    ),
                    updated_by=admin_id,
                )
            )

        else:

            settings = (
                await AIBillingRepository.update_settings(
                    db,
                    settings,
                    paid_enabled=(
                        self._policy.paid_enabled
                    ),
                    billing_mode=(
                        self._policy.mode.value
                    ),
                    paid_provider=(
                        self._paid_provider
                    ),
                    daily_budget=(
                        self._policy.daily_budget
                    ),
                    monthly_budget=(
                        self._policy.monthly_budget
                    ),
                    updated_by=admin_id,
                )
            )

            # Keep accumulated spending untouched.

        await AIBillingRepository.create_audit_log(
            db,
            action=action,
            previous_mode=previous_mode,
            new_mode=self._policy.mode.value,
            paid_enabled=self._policy.paid_enabled,
            paid_provider=self._paid_provider,
            daily_budget=self._policy.daily_budget,
            monthly_budget=self._policy.monthly_budget,
            admin_id=admin_id,
            details=details,
        )

        await db.commit()

        self._updated_by = admin_id

        return self.get_state()
     

     
         # ==========================================================
    # RECORD AI USAGE COST
    # ==========================================================

    async def record_usage_cost(
        self,
        db: AsyncSession,
        *,
        amount: float,
        provider: str,
        model: str,
    ) -> AdminBillingState:
        """
        Record the cost of a completed paid AI request.

        Responsibilities:

            AIGateway
                ↓
            calculated cost
                ↓
            this method
                ↓
            BillingPolicy
                ↓
            Repository
                ↓
            PostgreSQL

        This method does not calculate pricing and does not
        create an Admin audit log.
        """

        # ------------------------------------------------------
        # Validate amount
        # ------------------------------------------------------

        if amount < 0:
            raise ValueError(
                "AI usage cost cannot be negative."
            )

        # ------------------------------------------------------
        # Zero-cost request
        # ------------------------------------------------------

        if amount == 0:
            return self.get_state()

        # ------------------------------------------------------
        # Validate provider
        # ------------------------------------------------------

        provider = self._validate_provider(
            provider
        )

        # ------------------------------------------------------
        # Provider must match Admin paid provider
        # ------------------------------------------------------

        if provider != self._paid_provider:
            raise PermissionError(
                "AI usage provider does not match "
                "the configured paid provider."
            )

        # ------------------------------------------------------
        # Paid AI must currently be allowed
        # ------------------------------------------------------

        if not self._policy.can_use_paid():
            raise PermissionError(
                "Paid AI usage is not currently allowed "
                "by the billing policy."
            )

        # ------------------------------------------------------
        # Budget protection
        #
        # can_use_paid() checks the current balance.
        # We must also prevent THIS request from pushing
        # spending beyond the configured budget.
        # ------------------------------------------------------

        new_daily_spent = (
            self._policy.daily_spent + amount
        )

        new_monthly_spent = (
            self._policy.monthly_spent + amount
        )

        if (
            self._policy.daily_budget > 0
            and new_daily_spent
            > self._policy.daily_budget
        ):
            raise PermissionError(
                "Daily AI budget would be exceeded."
            )

        if (
            self._policy.monthly_budget > 0
            and new_monthly_spent
            > self._policy.monthly_budget
        ):
            raise PermissionError(
                "Monthly AI budget would be exceeded."
            )

        # ------------------------------------------------------
        # Update runtime policy
        # ------------------------------------------------------

        self._policy.record_cost(
            amount
        )

        # ------------------------------------------------------
        # Load persistent settings
        # ------------------------------------------------------

        settings = (
            await AIBillingRepository.get_settings(db)
        )

        if settings is None:
            raise RuntimeError(
                "AI billing settings do not exist."
            )

        # ------------------------------------------------------
        # Persist spending
        # ------------------------------------------------------

        await AIBillingRepository.record_spending(
            db,
            settings,
            amount=amount,
        )

        await db.commit()

        return self.get_state()

    # ==========================================================
    # DISABLE
    # ==========================================================

    async def disable(
        self,
        db: AsyncSession,
        *,
        admin_id: str | None = None,
    ) -> AdminBillingState:

        previous_mode = self._policy.mode.value

        self._policy.paid_enabled = False
        self._policy.mode = BillingMode.FREE_ONLY

        return await self._persist(
            db,
            action="DISABLE",
            previous_mode=previous_mode,
            admin_id=admin_id,
        )

    # ==========================================================
    # SOFT ENABLE
    # ==========================================================

    async def soft_enable(
        self,
        db: AsyncSession,
        *,
        paid_provider: str | None = None,
        daily_budget: float | None = None,
        monthly_budget: float | None = None,
        admin_id: str | None = None,
    ) -> AdminBillingState:

        previous_mode = self._policy.mode.value

        if paid_provider is not None:
            self._paid_provider = (
                self._validate_provider(
                    paid_provider
                )
            )

        if daily_budget is not None:
            self._policy.daily_budget = (
                self._validate_budget(
                    daily_budget,
                    "Daily budget",
                )
            )

        if monthly_budget is not None:
            self._policy.monthly_budget = (
                self._validate_budget(
                    monthly_budget,
                    "Monthly budget",
                )
            )

        self._policy.paid_enabled = True
        self._policy.mode = BillingMode.SOFT

        return await self._persist(
            db,
            action="SOFT_ENABLE",
            previous_mode=previous_mode,
            admin_id=admin_id,
        )

    # ==========================================================
    # HARD ENABLE
    # ==========================================================

    async def hard_enable(
        self,
        db: AsyncSession,
        *,
        paid_provider: str | None = None,
        daily_budget: float | None = None,
        monthly_budget: float | None = None,
        admin_id: str | None = None,
    ) -> AdminBillingState:

        previous_mode = self._policy.mode.value

        if paid_provider is not None:
            self._paid_provider = (
                self._validate_provider(
                    paid_provider
                )
            )

        if daily_budget is not None:
            self._policy.daily_budget = (
                self._validate_budget(
                    daily_budget,
                    "Daily budget",
                )
            )

        if monthly_budget is not None:
            self._policy.monthly_budget = (
                self._validate_budget(
                    monthly_budget,
                    "Monthly budget",
                )
            )

        self._policy.paid_enabled = True
        self._policy.mode = BillingMode.HARD

        return await self._persist(
            db,
            action="HARD_ENABLE",
            previous_mode=previous_mode,
            admin_id=admin_id,
        )

    # ==========================================================
    # PAID PROVIDER
    # ==========================================================

    async def set_paid_provider(
        self,
        db: AsyncSession,
        provider: str,
        *,
        admin_id: str | None = None,
    ) -> AdminBillingState:

        previous_mode = self._policy.mode.value

        self._paid_provider = (
            self._validate_provider(provider)
        )

        return await self._persist(
            db,
            action="SET_PAID_PROVIDER",
            previous_mode=previous_mode,
            admin_id=admin_id,
        )

    @property
    def paid_provider(self) -> str:
        return self._paid_provider

    # ==========================================================
    # BUDGETS
    # ==========================================================

    async def set_budgets(
        self,
        db: AsyncSession,
        *,
        daily_budget: float | None = None,
        monthly_budget: float | None = None,
        admin_id: str | None = None,
    ) -> AdminBillingState:

        previous_mode = self._policy.mode.value

        if daily_budget is not None:
            self._policy.daily_budget = (
                self._validate_budget(
                    daily_budget,
                    "Daily budget",
                )
            )

        if monthly_budget is not None:
            self._policy.monthly_budget = (
                self._validate_budget(
                    monthly_budget,
                    "Monthly budget",
                )
            )

        return await self._persist(
            db,
            action="SET_BUDGETS",
            previous_mode=previous_mode,
            admin_id=admin_id,
        )
     

         # ==========================================================
    # COST RECORDING
    # ==========================================================

    async def record_cost(
        self,
        db: AsyncSession,
        amount: float,
    ) -> AdminBillingState:
        """
        Record a successful paid AI request.

        This updates both:
            - runtime BillingPolicy
            - persistent PostgreSQL billing state

        This method does NOT authorize paid AI.
        Authorization remains the responsibility of
        BillingPolicy.can_use_paid().
        """

        if amount < 0:
            raise ValueError(
                "AI cost cannot be negative."
            )

        if amount == 0:
            return self.get_state()

        # Update runtime state.
        self._policy.record_cost(amount)

        # Load persistent state.
        settings = (
            await AIBillingRepository.get_settings(db)
        )

        if settings is None:
            settings = (
                await AIBillingRepository.create_settings(
                    db,
                    paid_enabled=(
                        self._policy.paid_enabled
                    ),
                    billing_mode=(
                        self._policy.mode.value
                    ),
                    paid_provider=(
                        self._paid_provider
                    ),
                    daily_budget=(
                        self._policy.daily_budget
                    ),
                    monthly_budget=(
                        self._policy.monthly_budget
                    ),
                    daily_spent=(
                        self._policy.daily_spent
                    ),
                    monthly_spent=(
                        self._policy.monthly_spent
                    ),
                    updated_by=self._updated_by,
                )
            )
        else:
            await AIBillingRepository.record_spending(
                db,
                settings,
                amount=amount,
            )

        await db.commit()

        return self.get_state()
    # ==========================================================
    # SAFETY
    # ==========================================================

    def can_use_paid(self) -> bool:
        """
        Final runtime safety gate.
        """

        return self._policy.can_use_paid()
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.admin.model import (
    AIBillingAuditLog,
    AIBillingSettings,
)


class AIBillingRepository:
    """
    Database access for AI billing configuration and audit logs.
    """

    # ==========================================================
    # SETTINGS
    # ==========================================================

    @staticmethod
    async def get_settings(
        db: AsyncSession,
    ) -> AIBillingSettings | None:
        """
        Get the current AI billing settings.

        The system is designed around one active configuration.
        """

        result = await db.execute(
            select(AIBillingSettings)
            .order_by(
                AIBillingSettings.created_at.asc()
            )
            .limit(1)
        )

        return result.scalar_one_or_none()

    @staticmethod
    async def create_settings(
        db: AsyncSession,
        *,
        paid_enabled: bool = False,
        billing_mode: str = "free_only",
        paid_provider: str = "groq",
        daily_budget: float = 0.0,
        monthly_budget: float = 0.0,
        daily_spent: float = 0.0,
        monthly_spent: float = 0.0,
        updated_by: str | None = None,
    ) -> AIBillingSettings:

        settings = AIBillingSettings(
            paid_enabled=paid_enabled,
            billing_mode=billing_mode,
            paid_provider=paid_provider,
            daily_budget=daily_budget,
            monthly_budget=monthly_budget,
            daily_spent=daily_spent,
            monthly_spent=monthly_spent,
            updated_by=updated_by,
        )

        db.add(settings)

        await db.flush()

        return settings

    @staticmethod
    async def update_settings(
        db: AsyncSession,
        settings: AIBillingSettings,
        *,
        paid_enabled: bool,
        billing_mode: str,
        paid_provider: str,
        daily_budget: float,
        monthly_budget: float,
        updated_by: str | None,
    ) -> AIBillingSettings:

        settings.paid_enabled = paid_enabled
        settings.billing_mode = billing_mode
        settings.paid_provider = paid_provider
        settings.daily_budget = daily_budget
        settings.monthly_budget = monthly_budget
        settings.updated_by = updated_by

        await db.flush()

        return settings
         # ==========================================================
    # SPENDING
    # ==========================================================

    @staticmethod
    async def record_spending(
        db: AsyncSession,
        settings: AIBillingSettings,
        *,
        amount: float,
    ) -> AIBillingSettings:
        """
        Persist AI spending.

        The caller is responsible for deciding whether the
        cost should be recorded.

        This method only persists the amount.
        """

        if amount < 0:
            raise ValueError(
                "AI spending amount cannot be negative."
            )

        settings.daily_spent = (
            settings.daily_spent + amount
        )

        settings.monthly_spent = (
            settings.monthly_spent + amount
        )

        await db.flush()

        return settings
    # ==========================================================
    # AUDIT
    # ==========================================================

    @staticmethod
    async def create_audit_log(
        db: AsyncSession,
        *,
        action: str,
        previous_mode: str | None,
        new_mode: str,
        paid_enabled: bool,
        paid_provider: str,
        daily_budget: float,
        monthly_budget: float,
        admin_id: str | None,
        details: str | None = None,
    ) -> AIBillingAuditLog:

        audit = AIBillingAuditLog(
            action=action,
            previous_mode=previous_mode,
            new_mode=new_mode,
            paid_enabled=paid_enabled,
            paid_provider=paid_provider,
            daily_budget=daily_budget,
            monthly_budget=monthly_budget,
            admin_id=admin_id,
            details=details,
            created_at=datetime.now(
                timezone.utc
            ),
        )

        db.add(audit)

        await db.flush()

        return audit

    @staticmethod
    async def get_audit_logs(
        db: AsyncSession,
        *,
        limit: int = 50,
    ) -> list[AIBillingAuditLog]:

        result = await db.execute(
            select(AIBillingAuditLog)
            .order_by(
                AIBillingAuditLog.created_at.desc()
            )
            .limit(limit)
        )

        return list(
            result.scalars().all()
        )
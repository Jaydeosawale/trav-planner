from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.dependencies.admin import get_current_admin
from app.modules.admin.repository import AIBillingRepository
from app.modules.auth.model import User
from app.services.ai.admin_billing_service import (
    AdminBillingService,
)
from app.services.ai.billing_policy import BillingPolicy

from .schema import (
    AIBillingAuditLogResponse,
    AIBillingBudgetRequest,
    AIBillingEnableRequest,
    AIBillingProviderRequest,
    AIBillingStateResponse,
)


router = APIRouter()


# ==========================================================
# HELPERS
# ==========================================================


def _create_service() -> AdminBillingService:
    """
    Create a billing service for an Admin API request.

    The persistent configuration is loaded from PostgreSQL
    before the requested operation.
    """

    return AdminBillingService(
        billing_policy=BillingPolicy(),
        paid_provider="groq",
    )


def _state_response(
    state,
) -> AIBillingStateResponse:

    return AIBillingStateResponse(
        paid_enabled=state.paid_enabled,
        mode=state.mode.value,
        paid_provider=state.paid_provider,
        daily_budget=state.daily_budget,
        monthly_budget=state.monthly_budget,
        daily_spent=state.daily_spent,
        monthly_spent=state.monthly_spent,
        updated_by=state.updated_by,
    )


# ==========================================================
# GET CURRENT BILLING STATE
# ==========================================================


@router.get(
    "",
    response_model=AIBillingStateResponse,
    summary="Get AI billing configuration",
)
async def get_ai_billing(
    current_admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Return the current persistent AI billing configuration.
    """

    service = _create_service()

    state = await service.load_from_database(db)

    return _state_response(state)


# ==========================================================
# SOFT ENABLE
# ==========================================================


@router.post(
    "/soft-enable",
    response_model=AIBillingStateResponse,
    summary="Enable paid AI in SOFT mode",
)
async def soft_enable_ai_billing(
    request: AIBillingEnableRequest,
    current_admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Enable paid AI as a controlled fallback.

    The Admin identity is taken from the authenticated user.
    """

    service = _create_service()

    await service.load_from_database(db)

    state = await service.soft_enable(
        db,
        paid_provider=request.paid_provider,
        daily_budget=request.daily_budget,
        monthly_budget=request.monthly_budget,
        admin_id=str(current_admin.id),
    )

    return _state_response(state)


# ==========================================================
# HARD ENABLE
# ==========================================================


@router.post(
    "/hard-enable",
    response_model=AIBillingStateResponse,
    summary="Enable paid AI in HARD mode",
)
async def hard_enable_ai_billing(
    request: AIBillingEnableRequest,
    current_admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Enable paid AI as a persistent Admin-authorized fallback.
    """

    service = _create_service()

    await service.load_from_database(db)

    state = await service.hard_enable(
        db,
        paid_provider=request.paid_provider,
        daily_budget=request.daily_budget,
        monthly_budget=request.monthly_budget,
        admin_id=str(current_admin.id),
    )

    return _state_response(state)


# ==========================================================
# DISABLE
# ==========================================================


@router.post(
    "/disable",
    response_model=AIBillingStateResponse,
    summary="Disable paid AI",
)
async def disable_ai_billing(
    current_admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Disable paid AI immediately.

    Existing budgets are preserved.
    """

    service = _create_service()

    await service.load_from_database(db)

    state = await service.disable(
        db,
        admin_id=str(current_admin.id),
    )

    return _state_response(state)


# ==========================================================
# CHANGE PROVIDER
# ==========================================================


@router.patch(
    "/provider",
    response_model=AIBillingStateResponse,
    summary="Change paid AI provider",
)
async def set_ai_billing_provider(
    request: AIBillingProviderRequest,
    current_admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Change the configured paid AI provider.
    """

    service = _create_service()

    await service.load_from_database(db)

    state = await service.set_paid_provider(
        db,
        request.paid_provider,
        admin_id=str(current_admin.id),
    )

    return _state_response(state)


# ==========================================================
# CHANGE BUDGET
# ==========================================================


@router.patch(
    "/budget",
    response_model=AIBillingStateResponse,
    summary="Change AI billing budgets",
)
async def set_ai_billing_budget(
    request: AIBillingBudgetRequest,
    current_admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Change daily and/or monthly paid AI budgets.
    """

    if (
        request.daily_budget is None
        and request.monthly_budget is None
    ):
        from fastapi import HTTPException

        raise HTTPException(
            status_code=400,
            detail=(
                "At least one budget value must be provided."
            ),
        )

    service = _create_service()

    await service.load_from_database(db)

    state = await service.set_budgets(
        db,
        daily_budget=request.daily_budget,
        monthly_budget=request.monthly_budget,
        admin_id=str(current_admin.id),
    )

    return _state_response(state)


# ==========================================================
# AUDIT LOGS
# ==========================================================


@router.get(
    "/audit-logs",
    response_model=list[AIBillingAuditLogResponse],
    summary="Get AI billing audit logs",
)
async def get_ai_billing_audit_logs(
    limit: int = Query(
        default=50,
        ge=1,
        le=100,
    ),
    current_admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Return recent AI billing Admin actions.
    """

    logs = await AIBillingRepository.get_audit_logs(
        db,
        limit=limit,
    )

    return [
        AIBillingAuditLogResponse(
            id=str(log.id),
            action=log.action,
            previous_mode=log.previous_mode,
            new_mode=log.new_mode,
            paid_enabled=log.paid_enabled,
            paid_provider=log.paid_provider,
            daily_budget=log.daily_budget,
            monthly_budget=log.monthly_budget,
            admin_id=log.admin_id,
            details=log.details,
            created_at=log.created_at.isoformat(),
        )
        for log in logs
    ]


# Provider selection is independent of the legacy paid billing controls.
from app.services.ai.routing import AIRoutingSettings, RoutingUpdate, load_routing, connection_status
import json

@router.get('/routing')
async def get_routing(current_admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db)):
    configuration = await load_routing(db)
    return {**configuration.model_dump(), 'providers': connection_status(), 'cost_policy': 'zero_cost'}

@router.put('/routing')
async def update_routing(payload: RoutingUpdate, current_admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db)):
    row = await db.get(AIRoutingSettings, 1, with_for_update=True)
    if row is None:
        row = AIRoutingSettings(id=1)
        db.add(row)
    row.provider_order = json.dumps(payload.provider_order)
    row.enabled = payload.enabled
    row.updated_by = str(current_admin.id)
    settings = await AIBillingRepository.get_settings(db)
    if settings is None:
        settings = await AIBillingRepository.create_settings(db)
    await AIBillingRepository.create_audit_log(db, action='routing_update', previous_mode=settings.billing_mode, new_mode=settings.billing_mode, paid_enabled=settings.paid_enabled, paid_provider=settings.paid_provider, daily_budget=settings.daily_budget, monthly_budget=settings.monthly_budget, admin_id=str(current_admin.id), details=json.dumps(payload.model_dump()))
    await db.commit()
    return {**payload.model_dump(), 'providers': connection_status(), 'cost_policy': 'zero_cost'}


@router.get('/usage')
async def get_ai_usage(current_admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db)):
    from datetime import datetime, timezone, timedelta
    from sqlalchemy import select, func
    from app.services.ai.routing import AIUsageRecord
    since = datetime.now(timezone.utc)-timedelta(days=1)
    rows = (await db.execute(select(AIUsageRecord.provider,func.count().label('attempts'),func.sum(AIUsageRecord.input_tokens).label('input_tokens'),func.sum(AIUsageRecord.output_tokens).label('output_tokens'),func.sum(AIUsageRecord.total_tokens).label('total_tokens')).where(AIUsageRecord.created_at >= since).group_by(AIUsageRecord.provider))).mappings().all()
    return {'window':'last_24_hours','providers':[dict(row) for row in rows]}

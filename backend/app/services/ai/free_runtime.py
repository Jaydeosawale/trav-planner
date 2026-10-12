"""Zero-cost runtime routing. A bounded attempt per provider, no paid fallback."""

import time
import httpx
from app.services.ai.routing import load_routing, connection_status
from app.database.session import SessionLocal
from app.integrations.llm.factory import get_llm_provider
from app.services.ai.quota_manager import QuotaManager

# Each process retains provider-reported quota across requests. On restart the
# provider remains authoritative; missing quota is not a fabricated balance.
quota_manager = QuotaManager()
cooldowns = {}


async def configuration():
    async with SessionLocal() as db:
        return await load_routing(db)


async def run(method, *, forced_provider=None, **arguments):
    config = await configuration()
    statuses = connection_status()
    attempted = []
    if not config.enabled:
        return None, "AI is paused by the administrator.", attempted
    order = [forced_provider] if forced_provider else config.provider_order
    for name in order:
        if name not in config.provider_order or not statuses.get(name, {}).get(
            "eligible"
        ):
            continue
        if cooldowns.get(name, 0) > time.monotonic():
            continue
        quota = quota_manager.get(name)
        if quota and not quota.free_available:
            # Known reset times come only from provider responses. When absent,
            # retry after the cooldown rather than claiming the quota reset.
            if quota.reset_at is not None:
                continue
        attempted.append(name)
        try:
            provider = get_llm_provider(name, quota_manager=quota_manager)
            response = await getattr(provider, method)(**arguments)
            if not response.content.strip() and not response.tool_calls:
                raise ValueError("Provider returned an empty response.")
            await record(name, response=response)
            return response, "", attempted
        except Exception as exc:
            status = (
                getattr(exc, "status_code", None)
                or getattr(getattr(exc, "response", None), "status_code", None)
                or getattr(exc, "code", None)
            )
            import logging
            category = str(status) if status else type(exc).__name__
            if isinstance(exc, ValueError) and str(exc) == "Provider returned an empty response.":
                category = "empty_response"
            logging.getLogger(__name__).warning("AI provider failure provider=%s stage=%s status=%s category=%s", name, method, status, category)
            await record(name, error=category)
            retryable = (
                status in (401, 403, 404, 408, 429, 500, 502, 503, 504)
                or isinstance(exc, (httpx.TimeoutException, httpx.NetworkError))
                or type(exc).__name__
                in (
                    "APIConnectionError",
                    "APITimeoutError",
                    "ConnectionError",
                    "TimeoutError",
                )
            )
            if not retryable:
                # Don't expose SDK errors, URLs, key fragments, or prompts.
                return (
                    None,
                    "AI could not complete this request. Please try a simpler request.",
                    attempted,
                )
            cooldowns[name] = time.monotonic() + (900 if status in (401, 403) else 60)
            # Never switch providers inside an active tool conversation.
            if forced_provider:
                break
    return (
        None,
        "AI is temporarily unavailable. Your trips and saved places are still available.",
        attempted,
    )


async def record(provider, *, response=None, error=None):
    from app.services.ai.routing import AIUsageRecord

    from datetime import datetime, timezone
    now = datetime.now(timezone.utc)
    usage = response.usage if response else None
    try:
        async with SessionLocal() as db:
            db.add(
                AIUsageRecord(
                    created_at=now,
                    updated_at=now,
                    provider=provider,
                    model=response.model if response else None,
                    succeeded=response is not None,
                    input_tokens=usage.input_tokens if usage else None,
                    output_tokens=usage.output_tokens if usage else None,
                    total_tokens=usage.total_tokens if usage else None,
                    error_category=error,
                )
            )
            await db.commit()
    except Exception:
        import logging

        logging.getLogger(__name__).warning(
            "AI usage recording unavailable; no request replayed."
        )

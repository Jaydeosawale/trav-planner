from __future__ import annotations

import asyncio

import httpx

from app.main import app
from app.common.security.jwt import create_access_token


BASE_URL = "/api/v1/admin/ai-billing"


def print_case(title: str) -> None:
    print()
    print("=" * 60)
    print(title)
    print("=" * 60)


async def main() -> None:
    print("=" * 60)
    print("ADMIN AI BILLING AUTHORIZATION TEST")
    print("=" * 60)

    # ==========================================================
    # EXISTING USERS IN POSTGRESQL
    # ==========================================================

    admin_id = "2babb481-ef01-4ae6-8c11-0df70805ab4c"
    normal_user_id = "885c8498-b6a5-4724-8d04-f47d332a5b4e"

    # ==========================================================
    # ASYNC HTTP CLIENT
    # ==========================================================
    #
    # raise_app_exceptions=False is important here.
    #
    # It allows us to inspect the actual HTTP response generated
    # by FastAPI instead of allowing an application exception to
    # escape from the ASGI transport.
    #

    transport = httpx.ASGITransport(
        app=app,
        raise_app_exceptions=False,
    )

    async with httpx.AsyncClient(
        transport=transport,
        base_url="http://testserver",
    ) as client:

        # ======================================================
        # CASE 1 — NO TOKEN
        # ======================================================

        print_case("CASE 1 — NO TOKEN")

        response = await client.get(
            BASE_URL,
        )

        print("Status:", response.status_code)
        print("Body  :", response.text)

        assert response.status_code == 401, (
            f"Expected 401, got {response.status_code}"
        )

        print("PASSED")

        # ======================================================
        # CASE 2 — INVALID TOKEN
        # ======================================================

        print_case("CASE 2 — INVALID TOKEN")

        response = await client.get(
            BASE_URL,
            headers={
                "Authorization": "Bearer invalid-token",
            },
        )

        print("Status:", response.status_code)
        print("Body  :", response.text)

        assert response.status_code == 401, (
            f"Expected 401, got {response.status_code}"
        )

        print("PASSED")

        # ======================================================
        # CASE 3 — NORMAL USER
        # ======================================================

        print_case("CASE 3 — NORMAL USER")

        user_token = create_access_token(
            normal_user_id,
        )

        response = await client.get(
            BASE_URL,
            headers={
                "Authorization": f"Bearer {user_token}",
            },
        )

        print("Status:", response.status_code)
        print("Body  :", response.text)

        assert response.status_code == 403, (
            f"Expected 403, got {response.status_code}"
        )

        print("PASSED")

        # ======================================================
        # CASE 4 — ADMIN
        # ======================================================

        print_case("CASE 4 — ADMIN")

        admin_token = create_access_token(
            admin_id,
        )

        admin_headers = {
            "Authorization": f"Bearer {admin_token}",
        }

        response = await client.get(
            BASE_URL,
            headers=admin_headers,
        )

        print("Status:", response.status_code)
        print("Body  :", response.text)

        assert response.status_code == 200, (
            f"Expected 200, got {response.status_code}"
        )

        data = response.json()

        assert data["paid_enabled"] is False
        assert data["mode"] == "free_only"

        print("Paid enabled:", data["paid_enabled"])
        print("Mode        :", data["mode"])
        print("Provider    :", data["paid_provider"])
        print("PASSED")

        # ======================================================
        # CASE 5 — ADMIN SOFT ENABLE
        # ======================================================

        print_case("CASE 5 — ADMIN SOFT ENABLE")

        response = await client.post(
            f"{BASE_URL}/soft-enable",
            headers=admin_headers,
            json={
                "paid_provider": "groq",
                "daily_budget": 10.0,
                "monthly_budget": 100.0,
            },
        )

        print("Status:", response.status_code)
        print("Body  :", response.text)

        assert response.status_code == 200, (
            f"Expected 200, got {response.status_code}"
        )

        data = response.json()

        assert data["paid_enabled"] is True
        assert data["mode"] == "soft"
        assert data["paid_provider"] == "groq"

        print("Paid enabled:", data["paid_enabled"])
        print("Mode        :", data["mode"])
        print("Provider    :", data["paid_provider"])
        print("PASSED")

        # ======================================================
        # CASE 6 — ADMIN AUDIT LOGS
        # ======================================================

        print_case("CASE 6 — ADMIN AUDIT LOGS")

        response = await client.get(
            f"{BASE_URL}/audit-logs",
            headers=admin_headers,
        )

        print("Status:", response.status_code)
        print("Body  :", response.text)

        assert response.status_code == 200, (
            f"Expected 200, got {response.status_code}"
        )

        logs = response.json()

        assert isinstance(logs, list)

        print("Audit logs:", len(logs))
        print("PASSED")

        # ======================================================
        # CASE 7 — ADMIN DISABLE
        # ======================================================

        print_case("CASE 7 — ADMIN DISABLE")

        response = await client.post(
            f"{BASE_URL}/disable",
            headers=admin_headers,
        )

        print("Status:", response.status_code)
        print("Body  :", response.text)

        assert response.status_code == 200, (
            f"Expected 200, got {response.status_code}"
        )

        data = response.json()

        assert data["paid_enabled"] is False
        assert data["mode"] == "free_only"

        print("Paid enabled:", data["paid_enabled"])
        print("Mode        :", data["mode"])
        print("PASSED")

    # ==========================================================
    # COMPLETE
    # ==========================================================

    print()
    print("=" * 60)
    print("ADMIN AI BILLING AUTHORIZATION TEST: PASSED")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
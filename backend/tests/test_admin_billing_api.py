from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


print("=" * 60)
print("ADMIN AI BILLING API ROUTE TEST")
print("=" * 60)


# ----------------------------------------------------------
# ROUTE EXISTENCE
# ----------------------------------------------------------

openapi = app.openapi()
paths = openapi["paths"]

expected = [
    "/api/v1/admin/ai-billing",
    "/api/v1/admin/ai-billing/soft-enable",
    "/api/v1/admin/ai-billing/hard-enable",
    "/api/v1/admin/ai-billing/disable",
    "/api/v1/admin/ai-billing/provider",
    "/api/v1/admin/ai-billing/budget",
    "/api/v1/admin/ai-billing/audit-logs",
]

print("\nROUTES")

for path in expected:
    assert path in paths, f"Missing route: {path}"
    print("OK:", path)


print("\n" + "=" * 60)
print("ADMIN AI BILLING API ROUTES: PASSED")
print("=" * 60)

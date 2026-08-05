from fastapi import FastAPI

from app.api.v1.health import router as health_router
from app.config.settings import settings

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
)

app.include_router(
    health_router,
    prefix="/api/v1",
    tags=["Health"],
)


@app.get("/")
async def root():
    return {
        "message": "Trav Planner API"
    }
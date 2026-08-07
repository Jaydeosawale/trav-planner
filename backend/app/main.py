from fastapi import FastAPI

from app.api.v1.health import router as health_router
from app.config.settings import settings
from app.api.v1.planner import router as planner_router
from fastapi.middleware.cors import CORSMiddleware

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



app.include_router(
    planner_router,
    prefix="/api/v1",
    tags=["Planner"],
)



app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://10.102.215.77:8000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
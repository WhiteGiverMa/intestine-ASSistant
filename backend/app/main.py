from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.routers import records, auth, stats, ai
from app.database import engine, Base

app = FastAPI(
    title="Intestine ASSistant API",
    description="肠道健康助手后端API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["认证"])
app.include_router(records.router, prefix="/api/v1/records", tags=["记录"])
app.include_router(stats.router, prefix="/api/v1/stats", tags=["统计"])
app.include_router(ai.router, prefix="/api/v1/ai", tags=["AI分析"])

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.get("/")
async def root():
    return {"message": "Intestine ASSistant API", "version": "1.0.0"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

from fastapi import FastAPI
from app.routers import health, summary, metrics, status, compare, anomalies

app = FastAPI(
    title="AI Monitoring Agent",
    description="FastAPI middleware for Netdata + AnythingLLM",
    version="1.0.0"
)

app.include_router(health.router)
app.include_router(summary.router)
app.include_router(metrics.router)
app.include_router(status.router)
app.include_router(compare.router)
app.include_router(anomalies.router)

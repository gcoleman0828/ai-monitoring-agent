from fastapi import APIRouter, HTTPException
from app.services.anomaly_service import detect_anomalies

router = APIRouter()

@router.get("/anomalies")
def anomalies(host: str):
    try:
        return detect_anomalies(host)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

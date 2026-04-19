from fastapi import APIRouter, HTTPException
from app.services.status_service import build_status

router = APIRouter()

@router.get("/status")
def status(host: str):
    try:
        return build_status(host)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

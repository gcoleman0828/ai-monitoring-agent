from fastapi import APIRouter, HTTPException
from app.services.summary_service import build_summary

router = APIRouter()

@router.get("/summary")
def summary(host: str):
    try:
        return build_summary(host)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

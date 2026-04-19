from fastapi import APIRouter, HTTPException
from app.services.compare_service import compare_hosts

router = APIRouter()

@router.get("/compare")
def compare(host1: str, host2: str):
    try:
        return compare_hosts(host1, host2)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

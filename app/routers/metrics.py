from fastapi import APIRouter, HTTPException
from app.services.netdata_client import get_cpu_usage, get_memory_usage

router = APIRouter()

@router.get("/cpu")
def cpu(host: str):
    try:
        return get_cpu_usage(host)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

@router.get("/memory")
def memory(host: str):
    try:
        return get_memory_usage(host)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

from pydantic import BaseModel
from typing import List

class MetricResponse(BaseModel):
    host: str
    metric: str
    value: float
    unit: str

class SummaryResponse(BaseModel):
    host: str
    summary: str

class StatusResponse(BaseModel):
    host: str
    overall_status: str
    cpu_percent: float
    memory_percent: float

class AnomalyResponse(BaseModel):
    host: str
    anomalies_detected: bool
    findings: List[str]

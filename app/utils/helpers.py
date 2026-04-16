def percent_to_status(value: float) -> str:
    if value >= 90:
        return "critical"
    if value >= 75:
        return "warning"
    return "healthy"

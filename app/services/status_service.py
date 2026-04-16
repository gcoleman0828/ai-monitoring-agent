from app.services.netdata_client import get_cpu_usage, get_memory_usage, validate_host

def build_status(host: str):
    validate_host(host)

    cpu = get_cpu_usage(host)["value"]
    memory = get_memory_usage(host)["value"]

    if cpu > 85 or memory > 90:
        overall = "warning"
    else:
        overall = "healthy"

    return {
        "host": host,
        "overall_status": overall,
        "cpu_percent": cpu,
        "memory_percent": memory
    }

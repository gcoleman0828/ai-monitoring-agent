from app.services.netdata_client import get_cpu_usage, get_memory_usage, validate_host

def build_summary(host: str):
    validate_host(host)

    cpu = get_cpu_usage(host)
    memory = get_memory_usage(host)

    return {
        "host": host,
        "summary": f"{host} is currently running at {cpu['value']}% CPU and {memory['value']}% memory utilization.",
        "cpu": cpu,
        "memory": memory
    }

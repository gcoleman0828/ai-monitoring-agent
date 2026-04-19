from app.services.netdata_client import get_cpu_usage, get_memory_usage, validate_host

def detect_anomalies(host: str):
    validate_host(host)

    cpu = get_cpu_usage(host)["value"]
    memory = get_memory_usage(host)["value"]

    anomalies = []

    if cpu > 85:
        anomalies.append(f"High CPU detected: {cpu}%")

    if memory > 90:
        anomalies.append(f"High memory detected: {memory}%")

    return {
        "host": host,
        "anomalies_detected": len(anomalies) > 0,
        "findings": anomalies
    }

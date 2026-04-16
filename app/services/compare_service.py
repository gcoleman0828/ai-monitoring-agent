from app.services.netdata_client import get_cpu_usage, get_memory_usage, validate_host

def compare_hosts(host1: str, host2: str):
    validate_host(host1)
    validate_host(host2)

    return {
        "host1": {
            "name": host1,
            "cpu_percent": get_cpu_usage(host1)["value"],
            "memory_percent": get_memory_usage(host1)["value"]
        },
        "host2": {
            "name": host2,
            "cpu_percent": get_cpu_usage(host2)["value"],
            "memory_percent": get_memory_usage(host2)["value"]
        }
    }

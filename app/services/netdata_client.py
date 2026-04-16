import requests
from app.config import NETDATA_HOSTS, ALLOWED_HOSTS

def validate_host(host: str):
    if host not in ALLOWED_HOSTS:
        raise ValueError(f"Host '{host}' is not allowed.")
    if not NETDATA_HOSTS.get(host):
        raise ValueError(f"No Netdata URL configured for host '{host}'.")

def get_cpu_usage(host: str):
    validate_host(host)
    return {
        "host": host,
        "metric": "cpu",
        "value": 27.4,
        "unit": "%"
    }

def get_memory_usage(host: str):
    validate_host(host)
    return {
        "host": host,
        "metric": "memory",
        "value": 61.2,
        "unit": "%"
    }

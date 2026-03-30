# ---------------------------------------------------------
# This future import lets us use type hints in a cleaner way.
# In beginner terms:
# It helps Python handle annotations like Optional[str]
# more consistently, especially in newer-style code.
# ---------------------------------------------------------
from __future__ import annotations


# ---------------------------------------------------------
# IMPORTS
# ---------------------------------------------------------

# os:
# Used to read environment variables, such as NETDATA_BASE_URL.
# Environment variables are settings that live outside the code.
import os

# datetime, timezone:
# Used to get the current date/time in UTC.
from datetime import datetime, timezone

# These are type-hint tools.
# They do not usually change runtime behavior, but they help humans
# and editors understand what kinds of values functions expect/return.
from typing import Any, Dict, List, Optional, Tuple

# requests:
# A Python library used to make HTTP calls to another service.
# In this file, it calls the Netdata API.
import requests

# FastAPI:
# The web framework that creates the API server.
# HTTPException:
# Used to intentionally return an HTTP error (like 400 or 404).
# Query:
# Used to define query parameters like ?host=recipe-server.
from fastapi import FastAPI, HTTPException, Query

# JSONResponse:
# Lets us manually return a JSON response, especially for custom errors.
from fastapi.responses import JSONResponse


# ---------------------------------------------------------
# CREATE THE FASTAPI APPLICATION
# ---------------------------------------------------------
# This 'app' object is the main web application.
# FastAPI uses it to register endpoints like /health and /cpu.
app = FastAPI(
    title="Netdata Middleware",
    version="1.4.0-stable-netdata-parser",
    description="FastAPI middleware for clean Netdata CPU and memory metrics."
)


# =========================================================
# CONFIG
# =========================================================

# NETDATA_BASE_URL:
# Read the environment variable named NETDATA_BASE_URL.
# If it does not exist, default to "http://192.168.0.192:19999".
# .rstrip("/") removes a trailing slash from the end if there is one.
#
# Example:
# "http://192.168.0.192:19999/" becomes "http://192.168.0.192:19999"
NETDATA_BASE_URL = os.getenv("NETDATA_BASE_URL", "http://YOUR_IP_ADDRESS:19999").rstrip("/")

# NETDATA_API_TOKEN:
# Read an optional Netdata API token.
# If no token exists, use an empty string.
# .strip() removes extra spaces around it.
NETDATA_API_TOKEN = os.getenv("NETDATA_API_TOKEN", "").strip()

# REQUEST_TIMEOUT:
# Read timeout seconds from the environment.
# If not set, default to 10 seconds.
# int(...) converts the text to a real integer.
REQUEST_TIMEOUT = int(os.getenv("NETDATA_TIMEOUT", "10"))

# KNOWN_HOSTS:
# These are the only allowed host names users can request.
# This is a safety/control feature so someone cannot ask for any random host.
KNOWN_HOSTS = [
    "recipe-server",
    "ai-chatbot",
    "colemanplex",
]


# =========================================================
# BASIC HELPERS
# =========================================================

def utc_now_iso() -> str:
    """
    Return the current time in UTC as an ISO 8601 string.

    Example result:
    2026-03-26T22:15:00+00:00

    Step by step:
    - datetime.now(timezone.utc) gets the current UTC time
    - replace(microsecond=0) removes tiny fractions of a second
    - isoformat() converts the datetime to a text string
    """
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def build_headers() -> Dict[str, str]:
    """
    Build the HTTP headers used when calling Netdata.

    Why this exists:
    - Some Netdata setups require a bearer token.
    - Some do not.
    - This function creates the header only when needed.
    """
    # Start with an empty dictionary.
    headers: Dict[str, str] = {}

    # If there is an API token, add an Authorization header.
    if NETDATA_API_TOKEN:
        headers["Authorization"] = f"Bearer {NETDATA_API_TOKEN}"

    # Return the finished headers dictionary.
    return headers


def normalize_host(host: Optional[str]) -> Optional[str]:
    """
    Clean up a host string.

    What it does:
    - If host is None, return None.
    - Remove leading/trailing spaces.
    - Convert to lowercase.
    - If the result is empty, return None.

    Examples:
    " Recipe-Server " -> "recipe-server"
    "" -> None
    None -> None
    """
    if host is None:
        return None

    # strip() removes spaces on both ends
    # lower() makes the text lowercase
    cleaned = host.strip().lower()

    # Return the cleaned host if it contains text.
    # Otherwise return None.
    return cleaned if cleaned else None


def validate_host(host: Optional[str]) -> str:
    """
    Validate that the requested host is present and allowed.

    What happens here:
    1. Clean the host name with normalize_host()
    2. If the host is missing/empty, raise HTTP 400
    3. Compare against KNOWN_HOSTS
    4. If not found, raise HTTP 400 with a helpful message
    5. Return the normalized host
    """
    normalized = normalize_host(host)

    # If the host is empty or missing, return a 400 Bad Request.
    if not normalized:
        raise HTTPException(status_code=400, detail="Host is required.")

    # Make a lowercase version of all known hosts so comparison is consistent.
    valid_hosts = [h.lower() for h in KNOWN_HOSTS]

    # If the host is not in the allowed list, raise an error.
    if normalized not in valid_hosts:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown host '{host}'. Valid hosts: {', '.join(KNOWN_HOSTS)}"
        )

    # If everything is good, return the cleaned host name.
    return normalized


def fetch_json(url: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Make an HTTP GET request and return parsed JSON.

    Parameters:
    - url: the full URL to call
    - params: optional query string parameters

    Why this helper exists:
    - It keeps all request logic in one place.
    - It handles request failures consistently.
    - It converts bad network/JSON issues into API-friendly errors.
    """
    try:
        # Send the HTTP GET request to Netdata.
        response = requests.get(
            url,
            params=params,
            headers=build_headers(),
            timeout=REQUEST_TIMEOUT,
        )

        # If the server returned an HTTP error like 404 or 500,
        # raise_for_status() will throw an exception.
        response.raise_for_status()

        # Convert the JSON body into Python data and return it.
        return response.json()

    except requests.exceptions.RequestException as exc:
        # This catches network issues, timeouts, DNS problems, bad HTTP status, etc.
        raise HTTPException(
            status_code=502,
            detail=f"Failed to reach Netdata at {url}: {exc}"
        ) from exc

    except ValueError as exc:
        # This catches invalid JSON parsing.
        raise HTTPException(
            status_code=502,
            detail=f"Netdata returned invalid JSON from {url}"
        ) from exc


# =========================================================
# NETDATA PARSING HELPERS
# =========================================================

def safe_float(value: Any) -> Optional[float]:
    """
    Try to convert a value into a float safely.

    Returns:
    - float value if conversion works
    - None if conversion fails

    Examples:
    "12.5" -> 12.5
    8 -> 8.0
    None -> None
    "hello" -> None
    """
    try:
        if value is None:
            return None
        return float(value)
    except (TypeError, ValueError):
        return None


def extract_scalar(value: Any) -> Optional[float]:
    """
    Convert either:
      12.34
    or:
      [12.34, 0, 0]
    into a simple float.

    Why this exists:
    Netdata may return a direct number or a list that starts with a number.
    This function normalizes both cases into one float value.
    """
    # If the incoming value is a list...
    if isinstance(value, list):
        # Empty list -> nothing usable
        if not value:
            return None

        # Use the first value in the list
        return safe_float(value[0])

    # If it is not a list, just try converting it directly.
    return safe_float(value)


def get_result_section(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Netdata may put the real chart data under payload["result"].

    If payload["result"] exists and is a dictionary, return that.
    Otherwise return the original payload.

    This hides format differences from the rest of the code.
    """
    result = payload.get("result")
    if isinstance(result, dict):
        return result
    return payload


def extract_labels(payload: Dict[str, Any]) -> List[str]:
    """
    Extract the column labels from the Netdata payload.

    Example possible labels:
    ["time", "used", "free"]

    If labels is missing or not a list, return [].
    """
    result = get_result_section(payload)
    labels = result.get("labels", [])

    if not isinstance(labels, list):
        return []

    # Convert every label to a clean string.
    return [str(label).strip() for label in labels]


def extract_rows(payload: Dict[str, Any]) -> List[List[Any]]:
    """
    Extract the data rows from the Netdata payload.

    Expected shape:
    {
        "labels": [...],
        "data": [
            [row1 values...],
            [row2 values...]
        ]
    }

    Return only rows that are actually lists.
    """
    result = get_result_section(payload)
    rows = result.get("data", [])

    if not isinstance(rows, list):
        return []

    return [row for row in rows if isinstance(row, list)]


def extract_latest_row(payload: Dict[str, Any]) -> Optional[List[Any]]:
    """
    Return the newest row of chart data.

    This code assumes the latest row is the first row: rows[0].
    If there are no rows, return None.
    """
    rows = extract_rows(payload)

    if not rows:
        return None

    return rows[0]


def build_label_map(labels: List[str]) -> Dict[str, int]:
    """
    Build a quick lookup dictionary from label name to column index.

    Example:
    ["time", "used", "free"]
    becomes:
    {"time": 0, "used": 1, "free": 2}

    Why this helps:
    Instead of searching the labels list every time,
    we can directly look up the column position by name.
    """
    return {label.lower(): idx for idx, label in enumerate(labels)}


def get_value_by_label(payload: Dict[str, Any], label_name: str) -> Optional[float]:
    """
    Get a value from the latest row using a label name.

    Example:
    If labels = ["time", "used", "free"]
    and latest row = [1711490000, 4096, 2048]
    then get_value_by_label(payload, "used") returns 4096.0
    """
    labels = extract_labels(payload)
    latest_row = extract_latest_row(payload)

    # If either labels or row is missing, we cannot continue.
    if not labels or latest_row is None:
        return None

    # Build label -> index lookup
    label_map = build_label_map(labels)

    # Normalize the requested label and find its column index
    idx = label_map.get(label_name.strip().lower())

    # If label not found, or row is shorter than expected, return None.
    if idx is None or idx >= len(latest_row):
        return None

    # Pull the value from the row and normalize it to a float.
    return extract_scalar(latest_row[idx])


def get_first_numeric_value(payload: Dict[str, Any]) -> Optional[float]:
    """
    Fallback helper:
    return the first usable numeric value from the latest row.

    Why this exists:
    Sometimes the exact label names we expect are not present.
    In that case, we still try to find a meaningful number.

    Special case:
    If the first label is 'time', skip it.
    """
    labels = extract_labels(payload)
    latest_row = extract_latest_row(payload)

    if latest_row is None:
        return None

    # Usually the first column is a timestamp named "time".
    start_idx = 0
    if labels and labels[0].lower() == "time":
        start_idx = 1

    # Scan from left to right until we find a numeric value.
    for idx in range(start_idx, len(latest_row)):
        value = extract_scalar(latest_row[idx])
        if value is not None:
            return value

    return None


# =========================================================
# CHART ACCESS
# =========================================================

def build_chart_candidates(host: str, chart: str) -> List[str]:
    """
    Build several possible chart identifier formats to try.

    Why this exists:
    Netdata chart naming can vary depending on how it is queried.
    So instead of trusting a single chart format, we try several.

    The first two are the more complex chart:// formats.
    The later ones are simpler fallbacks.
    """
    return [
        f"chart://hosts:{host}/instance:{chart}/dimensions:*/after:-60/before:0/points:1/group:average/options:",
        f"chart://hosts:{host}/instance:{chart}/dimensions:*/after:-60/before:0/points:1/group:average/options:seconds",
        f"{host}.{chart}",
        f"{host}:{chart}",
        chart,
    ]


def get_chart_data(chart: str, host: str) -> Dict[str, Any]:
    """
    Ask Netdata for chart data for a specific chart and host.

    Step by step:
    1. Validate host
    2. Build a list of chart name candidates
    3. Try each candidate
    4. Call Netdata /api/v1/data with that candidate
    5. If returned data contains a latest row, accept it
    6. If none work, raise a 404
    """
    normalized_host = validate_host(host)
    candidates = build_chart_candidates(normalized_host, chart)

    # Keep the most recent error message for debugging.
    last_error: Optional[str] = None

    for candidate in candidates:
        try:
            payload = fetch_json(
                f"{NETDATA_BASE_URL}/api/v1/data",
                params={
                    "chart": candidate,
                    "format": "json2",
                    "points": 1,
                    "after": -60,
                },
            )

            # Check whether the payload actually contains at least one row.
            latest_row = extract_latest_row(payload)
            if latest_row is not None:
                return payload

        except HTTPException as exc:
            # Save the error and try the next candidate format.
            last_error = exc.detail
            continue

    # If all candidates failed, return a not found error.
    raise HTTPException(
        status_code=404,
        detail=f"Chart '{chart}' data not found for host '{normalized_host}'. Last error: {last_error}"
    )


# =========================================================
# METRIC CALCULATIONS
# =========================================================

def calculate_cpu_percent(payload: Dict[str, Any]) -> Optional[float]:
    """
    Calculate CPU usage percent from Netdata chart data.

    Strategy:
    - Try to add known 'busy' CPU dimensions together
    - If that fails, fall back to the first numeric value

    Common busy CPU labels:
    user, system, nice, softirq, irq, iowait, guest, guest_nice, steal
    """
    busy_dimensions = [
        "user",
        "system",
        "nice",
        "softirq",
        "irq",
        "iowait",
        "guest",
        "guest_nice",
        "steal",
    ]

    total = 0.0
    found = False

    # Add up every busy CPU component that exists in the payload.
    for dim in busy_dimensions:
        value = get_value_by_label(payload, dim)
        if value is not None:
            total += value
            found = True

    # If we found at least one busy dimension, return the total.
    if found:
        return round(total, 2)

    # Fallback:
    # If the expected labels do not exist, use the first numeric value we can find.
    fallback = get_first_numeric_value(payload)
    if fallback is not None:
        return round(fallback, 2)

    return None


def calculate_memory_percent(payload: Dict[str, Any]) -> Optional[float]:
    """
    Calculate memory usage percent from Netdata data.

    Preferred formula:
        used / (used + free) * 100

    Fallbacks:
    - allocated
    - apps
    - active
    - first numeric value
    """
    used = get_value_by_label(payload, "used")
    free = get_value_by_label(payload, "free")

    # Best case: both used and free are available
    if used is not None and free is not None:
        total = used + free
        if total > 0:
            return round((used / total) * 100.0, 2)

    # Some memory charts use different label names.
    for label in ["allocated", "apps", "active"]:
        alt_value = get_value_by_label(payload, label)
        if alt_value is not None:
            return round(alt_value, 2)

    # Final fallback:
    fallback = get_first_numeric_value(payload)
    if fallback is not None:
        return round(fallback, 2)

    return None


def get_cpu_percent(host: str) -> Optional[float]:
    """
    Convenience function:
    - fetch the system.cpu chart for the host
    - calculate CPU percent from that payload
    """
    payload = get_chart_data("system.cpu", host)
    return calculate_cpu_percent(payload)


def get_memory_percent(host: str) -> Optional[float]:
    """
    Convenience function:
    - fetch the system.ram chart for the host
    - calculate memory percent from that payload
    """
    payload = get_chart_data("system.ram", host)
    return calculate_memory_percent(payload)


def metric_status(value: Optional[float], warn: float, crit: float) -> str:
    """
    Convert a metric number into a health word.

    Rules:
    - None -> unknown
    - >= crit -> critical
    - >= warn -> warning
    - otherwise -> healthy
    """
    if value is None:
        return "unknown"
    if value >= crit:
        return "critical"
    if value >= warn:
        return "warning"
    return "healthy"


def build_summary(cpu_value: Optional[float], memory_value: Optional[float]) -> Tuple[str, str, str]:
    """
    Build overall status plus individual CPU and memory statuses.

    Return value:
    (overall_status, cpu_status, memory_status)

    Thresholds:
    - CPU warning at 75, critical at 90
    - Memory warning at 80, critical at 90
    """
    cpu_status = metric_status(cpu_value, warn=75.0, crit=90.0)
    memory_status = metric_status(memory_value, warn=80.0, crit=90.0)

    # Decide the overall status based on the worst condition.
    if "critical" in (cpu_status, memory_status):
        overall_status = "critical"
    elif "warning" in (cpu_status, memory_status):
        overall_status = "warning"
    elif "unknown" in (cpu_status, memory_status):
        overall_status = "unknown"
    else:
        overall_status = "healthy"

    # These text strings are built but not returned.
    # They may be leftovers from an earlier version or for future use.
    cpu_text = f"CPU is {cpu_value}% ({cpu_status})" if cpu_value is not None else "CPU unavailable"
    memory_text = f"memory is {memory_value}% ({memory_status})" if memory_value is not None else "memory unavailable"

    # Avoid linter complaining that variables are unused in some editors.
    _ = cpu_text
    _ = memory_text

    return overall_status, cpu_status, memory_status


# =========================================================
# ROUTES
# =========================================================

@app.get("/")
def root() -> Dict[str, Any]:
    """
    Root endpoint.
    This is like a simple homepage for the API.
    It tells you what service this is and what routes are available.
    """
    return {
        "service": "netdata-middleware",
        "version": "1.4.0-stable-netdata-parser",
        "endpoints": [
            "/health",
            "/hosts",
            "/cpu?host=recipe-server",
            "/memory?host=recipe-server",
            "/summary?host=recipe-server",
        ],
    }


@app.get("/health")
def health() -> Dict[str, Any]:
    """
    Basic health check endpoint.

    Useful for:
    - verifying the middleware is running
    - testing whether the API responds at all
    """
    return {
        "status": "ok",
        "service": "netdata-middleware",
        "netdata_base_url": NETDATA_BASE_URL,
        "time_collected": utc_now_iso(),
    }


@app.get("/hosts")
def hosts() -> Dict[str, Any]:
    """
    Return the list of allowed hosts.
    Helpful for confirming what host names are valid.
    """
    return {
        "count": len(KNOWN_HOSTS),
        "hosts": KNOWN_HOSTS,
        "time_collected": utc_now_iso(),
        "note": "Known hosts configured manually.",
    }


@app.get("/cpu")
def cpu(
    host: str = Query(..., description="Known Netdata host name")
) -> Dict[str, Any]:
    """
    Return current CPU usage for one host.

    Example:
    /cpu?host=recipe-server
    """
    normalized_host = validate_host(host)
    value = get_cpu_percent(normalized_host)

    if value is None:
        raise HTTPException(status_code=404, detail=f"CPU data not found for host '{host}'")

    status = metric_status(value, warn=75.0, crit=90.0)

    return {
        "host": normalized_host,
        "metric": "cpu",
        "current_value": value,
        "unit": "percent",
        "status": status,
        "time_collected": utc_now_iso(),
        "short_summary": f"CPU usage on {normalized_host} is {value}% and status is {status}.",
    }


@app.get("/memory")
def memory(
    host: str = Query(..., description="Known Netdata host name")
) -> Dict[str, Any]:
    """
    Return current memory usage for one host.

    Example:
    /memory?host=recipe-server
    """
    normalized_host = validate_host(host)
    value = get_memory_percent(normalized_host)

    if value is None:
        raise HTTPException(status_code=404, detail=f"Memory data not found for host '{host}'")

    status = metric_status(value, warn=80.0, crit=90.0)

    return {
        "host": normalized_host,
        "metric": "memory",
        "current_value": value,
        "unit": "percent",
        "status": status,
        "time_collected": utc_now_iso(),
        "short_summary": f"Memory usage on {normalized_host} is {value}% and status is {status}.",
    }


@app.get("/summary")
def summary(
    host: str = Query(..., description="Known Netdata host name")
) -> Dict[str, Any]:
    """
    Return combined CPU and memory information plus an overall status.

    Example:
    /summary?host=recipe-server
    """
    normalized_host = validate_host(host)

    cpu_value = get_cpu_percent(normalized_host)
    memory_value = get_memory_percent(normalized_host)

    overall_status, cpu_status, memory_status = build_summary(cpu_value, memory_value)

    # Build short English phrases for the summary line.
    parts = []
    parts.append(f"CPU is {cpu_value}% ({cpu_status})" if cpu_value is not None else "CPU unavailable")
    parts.append(f"memory is {memory_value}% ({memory_status})" if memory_value is not None else "memory unavailable")

    return {
        "host": normalized_host,
        "generated_at": utc_now_iso(),
        "overall_status": overall_status,
        "cpu_percent": cpu_value,
        "cpu_status": cpu_status,
        "memory_percent": memory_value,
        "memory_status": memory_status,
        "short_summary": f"{normalized_host} summary: " + ", ".join(parts) + ".",
    }


@app.exception_handler(HTTPException)
def http_exception_handler(request, exc: HTTPException):
    """
    Custom error handler for HTTPException.

    Instead of FastAPI's default error format, this returns a consistent JSON shape:
    {
        "status": "error",
        "detail": "...",
        "time_collected": "..."
    }

    Note:
    The 'request' argument is required by FastAPI for exception handlers,
    even if we do not use it directly.
    """
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "status": "error",
            "detail": exc.detail,
            "time_collected": utc_now_iso(),
        },
    )

#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"

echo "========================================"
echo "Testing API endpoints at $BASE_URL"
echo "========================================"

test_endpoint() {
  local name="$1"
  local url="$2"

  echo
  echo "Testing $name"
  echo "GET $url"

  if curl -fsS "$url"; then
    echo
    echo "OK: $name"
  else
    echo
    echo "FAILED: $name"
  fi
}

test_endpoint "/health" "$BASE_URL/health"
test_endpoint "/summary" "$BASE_URL/summary?host=recipe-server"
test_endpoint "/cpu" "$BASE_URL/cpu?host=recipe-server"
test_endpoint "/memory" "$BASE_URL/memory?host=recipe-server"
test_endpoint "/status" "$BASE_URL/status?host=recipe-server"
test_endpoint "/compare" "$BASE_URL/compare?host1=recipe-server&host2=ai-chatbot"
test_endpoint "/anomalies" "$BASE_URL/anomalies?host=recipe-server"

echo
echo "========================================"
echo "Endpoint tests complete"
echo "========================================"
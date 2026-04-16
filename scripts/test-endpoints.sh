#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"

echo "Testing /health"
curl -fsS "$BASE_URL/health"
echo -e "\n"

echo "Testing /summary"
curl -fsS "$BASE_URL/summary?host=recipe-server"
echo -e "\n"

echo "Testing /cpu"
curl -fsS "$BASE_URL/cpu?host=recipe-server"
echo -e "\n"

echo "Testing /memory"
curl -fsS "$BASE_URL/memory?host=recipe-server"
echo -e "\n"

echo "Testing /status"
curl -fsS "$BASE_URL/status?host=recipe-server"
echo -e "\n"

echo "Testing /compare"
curl -fsS "$BASE_URL/compare?host1=recipe-server&host2=ai-chatbot"
echo -e "\n"

echo "Testing /anomalies"
curl -fsS "$BASE_URL/anomalies?host=recipe-server"
echo -e "\n"

echo "All endpoint tests completed."

#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "AI Monitoring Agent - Verification"
echo "========================================"

check_file() {
  local file="$1"
  if [ -f "$file" ]; then
    echo "OK: $file found"
  else
    echo "MISSING: $file"
  fi
}

echo
echo "Checking required files..."
check_file "bootstrap.sh"
check_file "install-ai-stack.sh"
check_file "verify-install.sh"
check_file "requirements.txt"
check_file "docker-compose.yml"
check_file ".env.example"
check_file "app/main.py"
check_file "scripts/start-api.sh"
check_file "scripts/test-endpoints.sh"

echo
echo "Checking Python..."
python3 --version || true

echo
echo "Checking pip..."
pip3 --version || true

echo
echo "Checking Docker..."
docker --version || true

echo
echo "Checking Docker Compose..."
docker compose version || true

echo
echo "Checking virtual environment..."
if [ -d ".venv" ]; then
  echo "OK: .venv exists"
else
  echo "MISSING: .venv"
fi

echo
echo "Checking installed Python packages..."
if [ -d ".venv" ]; then
  source .venv/bin/activate
  pip show fastapi >/dev/null 2>&1 && echo "OK: fastapi installed" || echo "MISSING: fastapi"
  pip show uvicorn >/dev/null 2>&1 && echo "OK: uvicorn installed" || echo "MISSING: uvicorn"
  deactivate
else
  echo "Skipped package check because .venv is missing"
fi

echo
echo "Project tree (top 3 levels)..."
find . -maxdepth 3 | sort

echo
echo "========================================"
echo "Verification complete"
echo "========================================"
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
check_file "docker-compose.yml"
check_file ".env.example"
check_file "requirements.txt"
check_file "app/main.py"
check_file "scripts/start-api.sh"
check_file "scripts/start-stack.sh"
check_file "scripts/test-endpoints.sh"
check_file "scripts/pull-model.sh"

echo
echo "Checking Python..."
python3 --version || true

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
echo "Checking Compose config..."
docker compose config >/dev/null 2>&1 && echo "OK: docker compose config valid" || echo "FAILED: docker compose config invalid"

echo
echo "Verification complete"
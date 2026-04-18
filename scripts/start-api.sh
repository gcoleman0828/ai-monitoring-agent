#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -d ".venv" ]; then
  echo "ERROR: .venv not found. Run ./install-ai-stack.sh first."
  exit 1
fi

if [ ! -f ".env" ]; then
  echo "WARNING: .env not found. Copy .env.example to .env and update it."
fi

source .venv/bin/activate

echo "Starting FastAPI on 0.0.0.0:8000 ..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
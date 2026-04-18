#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f ".env" ]; then
  echo "ERROR: .env not found."
  echo "Run: cp .env.example .env"
  echo "Then update your Netdata URLs."
  exit 1
fi

echo "Starting full stack with Docker Compose..."
docker compose up -d --build

echo
echo "Container status:"
docker compose ps

echo
echo "URLs:"
echo "  AnythingLLM: http://localhost:3001"
echo "  FastAPI API : http://localhost:8000"
echo "  Ollama API  : http://localhost:11434"
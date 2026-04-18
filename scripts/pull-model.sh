#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f ".env" ]; then
  echo "ERROR: .env not found."
  exit 1
fi

MODEL="$(grep '^OLLAMA_MODEL=' .env | cut -d= -f2- || true)"
MODEL="${MODEL:-llama3.2}"

echo "Waiting for Ollama container..."
for i in {1..30}; do
  if docker exec ollama ollama list >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "Pulling model: $MODEL"
docker exec ollama ollama pull "$MODEL"

echo
echo "Installed models:"
docker exec ollama ollama list
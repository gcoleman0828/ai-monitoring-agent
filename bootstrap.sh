#!/usr/bin/env bash
set -euo pipefail

CREATE_ENV_IF_MISSING="${CREATE_ENV_IF_MISSING:-yes}"
PULL_OLLAMA_MODEL="${PULL_OLLAMA_MODEL:-yes}"

log() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $1"
    exit 1
  fi
}

log "Checking that script is running from repo root"

if [ ! -f "docker-compose.yml" ] || [ ! -f "bootstrap.sh" ]; then
  echo "ERROR: Run this script from the ai-monitoring-agent repo root."
  exit 1
fi

log "Checking required tools"
require_cmd docker
require_cmd bash
require_cmd grep
require_cmd sed

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker compose plugin is required."
  exit 1
fi

log "Setting script permissions"
chmod +x *.sh || true
chmod +x scripts/*.sh || true

if [ "$CREATE_ENV_IF_MISSING" = "yes" ]; then
  if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    log "Creating .env from .env.example"
    cp .env.example .env
    echo "Created .env from template."
    echo "IMPORTANT: Edit .env with your real Netdata URLs and allowed hosts before continuing."
    echo "Then rerun ./bootstrap.sh"
    exit 0
  fi
fi

if [ ! -f ".env" ]; then
  echo "ERROR: .env file not found."
  echo "Create one from .env.example first."
  exit 1
fi

log "Validating required .env values"
grep -q "^JWT_SECRET=" .env || { echo "ERROR: JWT_SECRET missing in .env"; exit 1; }
grep -q "^OLLAMA_MODEL=" .env || { echo "ERROR: OLLAMA_MODEL missing in .env"; exit 1; }
grep -q "^NETDATA_RECIPE_SERVER_URL=" .env || { echo "ERROR: NETDATA_RECIPE_SERVER_URL missing in .env"; exit 1; }
grep -q "^NETDATA_AI_CHATBOT_URL=" .env || { echo "ERROR: NETDATA_AI_CHATBOT_URL missing in .env"; exit 1; }
grep -q "^NETDATA_COLEMANPLEX_URL=" .env || { echo "ERROR: NETDATA_COLEMANPLEX_URL missing in .env"; exit 1; }

log "Building and starting containers"
docker compose up -d --build

log "Waiting for Ollama API"
for i in {1..30}; do
  if curl -fsS http://localhost:${OLLAMA_PORT:-11434}/api/tags >/dev/null 2>&1; then
    echo "Ollama is responding."
    break
  fi
  sleep 2
done

if [ "$PULL_OLLAMA_MODEL" = "yes" ]; then
  log "Pulling Ollama model"
  docker exec ollama ollama pull "$(grep '^OLLAMA_MODEL=' .env | cut -d= -f2)"
fi

log "Waiting for FastAPI"
for i in {1..30}; do
  if curl -fsS http://localhost:${FASTAPI_PORT:-8000}/health >/dev/null 2>&1; then
    echo "FastAPI is responding."
    break
  fi
  sleep 2
done

log "Checking container status"
docker compose ps

log "Bootstrap complete"
echo "AnythingLLM: http://localhost:${ANYTHINGLLM_PORT:-3001}"
echo "Ollama:      http://localhost:${OLLAMA_PORT:-11434}"
echo "FastAPI:     http://localhost:${FASTAPI_PORT:-8000}"
echo
echo "Next steps:"
echo "1. Open AnythingLLM"
echo "2. Create your admin account"
echo "3. Set provider to Ollama"
echo "4. Use Ollama URL: http://ollama:11434 if inside the app config, or http://localhost:${OLLAMA_PORT:-11434} from the host browser"
echo "5. Configure tools/connectors to use FastAPI URL: http://fastapi:8000"
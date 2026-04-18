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

log "Checking that script is running from repo root"

if [ ! -f "docker-compose.yml" ] || [ ! -f "install-ai-stack.sh" ]; then
  echo "ERROR: Run this script from the ai-monitoring-agent repo root."
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
    echo "IMPORTANT: Edit .env with your real Netdata URLs before continuing."
    echo "Then rerun ./bootstrap.sh"
    exit 0
  fi
fi

log "Running host install"
./install-ai-stack.sh

log "Running verification"
./verify-install.sh

log "Starting full Docker stack"
bash scripts/start-stack.sh

if [ "$PULL_OLLAMA_MODEL" = "yes" ]; then
  log "Pulling default Ollama model"
  bash scripts/pull-model.sh
fi

log "Bootstrap complete"
echo "Open AnythingLLM: http://localhost:3001"
echo "FastAPI middleware : http://localhost:8000"
echo "Ollama API         : http://localhost:11434"
echo
echo "NOTE: If 'docker ps' fails, run 'newgrp docker' or log out and back in."
echo "Next required manual step:"
echo "Open AnythingLLM in the browser and complete first-run UI setup."
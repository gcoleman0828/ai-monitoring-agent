#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/gcoleman0828/ai-monitoring-agent.git}"
REPO_DIR="${REPO_DIR:-ai-monitoring-agent}"
BRANCH="${BRANCH:-main}"
CREATE_ENV_IF_MISSING="${CREATE_ENV_IF_MISSING:-yes}"
PULL_OLLAMA_MODEL="${PULL_OLLAMA_MODEL:-yes}"

log() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

log "Checking required host tools"

if ! command -v git >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y git
fi

if ! command -v curl >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y curl
fi

if [ -d "$REPO_DIR/.git" ]; then
  log "Repo already exists. Updating existing repo"
  cd "$REPO_DIR"
  git fetch origin
  git checkout "$BRANCH"
  git pull origin "$BRANCH"
else
  log "Cloning repo"
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

log "Setting script permissions"
chmod +x bootstrap.sh || true
chmod +x install-ai-stack.sh || true
chmod +x verify-install.sh || true
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
echo "Next required manual step:"
echo "Open AnythingLLM in the browser and complete first-run UI setup."
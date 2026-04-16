#!/usr/bin/env bash
set -euo pipefail

########################################
# Configuration
########################################
REPO_URL="${REPO_URL:-https://github.com/YOUR_GITHUB_USERNAME/ai-monitoring-agent.git}"
REPO_DIR="${REPO_DIR:-ai-monitoring-agent}"
BRANCH="${BRANCH:-main}"
AUTO_START_API="${AUTO_START_API:-yes}"
RUN_TESTS="${RUN_TESTS:-yes}"
CREATE_ENV_IF_MISSING="${CREATE_ENV_IF_MISSING:-yes}"

########################################
# Helpers
########################################
log() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

########################################
# Preconditions
########################################
log "Checking required host tools"

if ! command -v git >/dev/null 2>&1; then
  echo "git not found. Installing git..."
  sudo apt update
  sudo apt install -y git
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl not found. Installing curl..."
  sudo apt update
  sudo apt install -y curl
fi

########################################
# Clone or Update Repo
########################################
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

########################################
# Permissions
########################################
log "Setting script permissions"
chmod +x bootstrap.sh || true
chmod +x install-ai-stack.sh || true
chmod +x verify-install.sh || true
chmod +x scripts/*.sh || true

########################################
# .env Setup
########################################
if [ "$CREATE_ENV_IF_MISSING" = "yes" ]; then
  if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    log "Creating .env from .env.example"
    cp .env.example .env
    echo "Created .env from template."
    echo "IMPORTANT: Edit .env with your real Netdata URLs if needed."
  else
    log ".env already exists or .env.example missing"
  fi
fi

########################################
# Install Dependencies
########################################
log "Running install-ai-stack.sh"
./install-ai-stack.sh

########################################
# Verify
########################################
log "Running verification"
./verify-install.sh

########################################
# Start API
########################################
if [ "$AUTO_START_API" = "yes" ]; then
  log "Starting FastAPI in background"
  nohup bash scripts/start-api.sh > api.log 2>&1 &
  sleep 5
  echo "FastAPI started in background. Logs: $(pwd)/api.log"
else
  log "Skipping API auto-start"
fi

########################################
# Run Endpoint Tests
########################################
if [ "$RUN_TESTS" = "yes" ]; then
  log "Running endpoint tests"
  bash scripts/test-endpoints.sh || true
else
  log "Skipping endpoint tests"
fi

########################################
# Done
########################################
log "Bootstrap complete"

echo "Useful commands:"
echo "  cd $REPO_DIR"
echo "  source .venv/bin/activate"
echo "  bash scripts/start-api.sh"
echo "  bash scripts/test-endpoints.sh"
echo "  tail -f api.log"

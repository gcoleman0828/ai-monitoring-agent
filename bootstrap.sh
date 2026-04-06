cat > ~/ai-monitoring-agent/bootstrap.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/gcoleman0828/ai-monitoring-agent.git"
REPO_DIR="$HOME/ai-monitoring-agent"
BRANCH="main"

echo "==> AI Stack bootstrap starting..."

if [[ "$EUID" -eq 0 ]]; then
  echo "Please run this as your normal user, not root."
  exit 1
fi

echo "==> Updating apt cache..."
sudo apt update

echo "==> Installing prerequisites..."
sudo apt install -y git curl ca-certificates

if [[ -d "$REPO_DIR/.git" ]]; then
  echo "==> Repo already exists at $REPO_DIR"
  cd "$REPO_DIR"
  git fetch origin
  git checkout "$BRANCH"
  git pull --ff-only origin "$BRANCH"
else
  echo "==> Cloning repository..."
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
fi

if [[ ! -f "$REPO_DIR/install-ai-stack.sh" ]]; then
  echo "ERROR: install-ai-stack.sh not found in repo root."
  exit 1
fi

chmod +x "$REPO_DIR/install-ai-stack.sh"

echo "==> Running main installer..."
cd "$REPO_DIR"
bash "$REPO_DIR/install-ai-stack.sh"

echo
echo "==> Bootstrap complete."
echo "Repo location: $REPO_DIR"
echo "You may need to log out and back in if docker group membership was just added."
EOF

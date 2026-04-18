#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "AI Monitoring Agent - Host Install Start"
echo "========================================"

echo "[1/7] Updating Ubuntu packages..."
sudo apt update

echo "[2/7] Installing required packages..."
sudo apt install -y \
  python3 \
  python3-pip \
  python3-venv \
  docker.io \
  docker-compose-v2 \
  curl \
  git

echo "[3/7] Enabling Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "[4/7] Adding current user to docker group..."
sudo usermod -aG docker "$USER" || true

echo "[5/7] Creating Python virtual environment if missing..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi

echo "[6/7] Installing Python dependencies..."
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

echo "[7/7] Setting script permissions..."
chmod +x bootstrap.sh || true
chmod +x verify-install.sh || true
chmod +x scripts/*.sh || true

echo "========================================"
echo "Install complete."
echo "========================================"
echo
echo "NOTE:"
echo "- If docker commands fail without sudo, log out and back in."
echo "- Next steps:"
echo "    cp .env.example .env"
echo "    nano .env"
echo "    bash scripts/start-api.sh"
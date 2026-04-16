#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "AI Monitoring Agent - Host Install Start"
echo "========================================"

echo "[1/6] Updating Ubuntu packages..."
sudo apt update

echo "[2/6] Installing required packages..."
sudo apt install -y \
  python3 \
  python3-pip \
  python3-venv \
  docker.io \
  docker-compose-v2 \
  curl \
  git

echo "[3/6] Enabling Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "[4/6] Creating Python virtual environment if missing..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi

echo "[5/6] Installing Python dependencies..."
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

echo "[6/6] Setting script permissions..."
chmod +x verify-install.sh || true
chmod +x scripts/*.sh || true

echo "========================================"
echo "Install complete."
echo "========================================"

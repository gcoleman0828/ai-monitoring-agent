#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "AI Monitoring Agent - Host Install Start"
echo "========================================"

echo "[1/10] Updating Ubuntu packages..."
sudo apt update

echo "[2/10] Installing prerequisites..."
sudo apt install -y ca-certificates curl gnupg python3 python3-pip python3-venv git

echo "[3/10] Removing conflicting Docker packages if present..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt remove -y "$pkg" 2>/dev/null || true
done

echo "[4/10] Setting up Docker apt keyring..."
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.asc ]; then
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
fi
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "[5/10] Adding Docker repository..."
ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[6/10] Updating package index with Docker repo..."
sudo apt update

echo "[7/10] Installing Docker Engine + Compose plugin..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[8/10] Enabling Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "[9/10] Verifying Docker install..."
sudo docker --version
sudo docker compose version
sudo docker ps

echo "[10/10] Adding current user to docker group..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker "$USER" || true

echo "Creating Python virtual environment if missing..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi

echo "Installing Python dependencies..."
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

echo "Setting script permissions..."
chmod +x *.sh || true
chmod +x scripts/*.sh || true

echo
echo "========================================"
echo "Install complete."
echo "========================================"
echo "If 'docker ps' fails without sudo, run:"
echo "  newgrp docker"
echo "or log out and back in."
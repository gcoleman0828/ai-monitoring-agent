echo
echo "Checking Docker..."
sudo docker --version || true

echo
echo "Checking Docker Compose..."
sudo docker compose version || true

echo
echo "Checking Compose config..."
sudo docker compose config >/dev/null 2>&1 && echo "OK: docker compose config valid" || echo "FAILED: docker compose config invalid"
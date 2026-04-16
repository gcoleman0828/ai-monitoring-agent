#!/usr/bin/env bash

echo "Checking repo files..."
test -f install-ai-stack.sh && echo "OK: install-ai-stack.sh found" || echo "MISSING: install-ai-stack.sh"
test -f requirements.txt && echo "OK: requirements.txt found" || echo "MISSING: requirements.txt"
test -f app/main.py && echo "OK: app/main.py found" || echo "MISSING: app/main.py"
test -f docker-compose.yml && echo "OK: docker-compose.yml found" || echo "MISSING: docker-compose.yml"

echo
echo "Checking Python..."
python3 --version

echo
echo "Checking Docker..."
docker --version

echo
echo "Checking Docker Compose..."
docker compose version

echo
echo "Checking project tree..."
find . -maxdepth 3 | sort

#!/usr/bin/env bash
set -e

cp .env.example .env
echo ".env file created from .env.example"
echo "Edit .env now with your real Netdata IPs before starting the API."

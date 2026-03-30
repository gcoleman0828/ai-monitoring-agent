# AI Infrastructure Monitoring Agent

A local-first AI monitoring project that connects Netdata metrics to a natural language workflow using FastAPI, AnythingLLM, and Ollama.

## Architecture

Netdata → FastAPI middleware → AnythingLLM → Ollama

## What it does

This project allows natural language questions against infrastructure metrics, such as:

- What is the status of RasberryPi?
- Compare memory usage across hosts
- Is anything abnormal right now?

## Components

- Netdata for metrics collection
- FastAPI for API normalization and host-safe endpoints
- AnythingLLM for tool use and orchestration
- Ollama for local LLM inference

## Project Structure

```text
ai-monitoring-agent/
├── docker-compose.yml
├── .env.example
├── README.md
├── fastapi/
├── screenshots/
└── docs/

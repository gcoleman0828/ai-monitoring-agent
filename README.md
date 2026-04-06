# 🚀 AI Monitoring Stack  
### Netdata + FastAPI + AnythingLLM + Ollama

![Docker](https://img.shields.io/badge/Docker-Ready-blue)
![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Linux-green)
![AI](https://img.shields.io/badge/LLM-Ollama%20%28llama3%29-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

A fully containerized, local-first AI monitoring platform that lets you query infrastructure metrics using natural language.

---

# 📚 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Bootstrap Script](#bootstrap-script)
- [Environment Configuration](#environment-configuration)
- [AnythingLLM Setup](#anythingllm-setup)
- [Flow Configuration](#flow-configuration)
- [Testing](#testing)
- [Agent Usage](#agent-usage)
- [Troubleshooting](#troubleshooting)
- [Common Commands](#common-commands)
- [Git Notes](#git-notes)
- [Future Enhancements](#future-enhancements)

---

# 🧠 Overview

This stack enables:

- 📊 Real-time infrastructure monitoring via Netdata  
- 🤖 AI-powered analysis using Ollama (llama3)  
- 🔗 Middleware abstraction via FastAPI  
- 💬 Natural language querying through AnythingLLM  

---

# 🏗️ Architecture

<details>
<summary>🔍 High-Level Architecture</summary>

```text
+-------------------+
|   User Browser    |
|  http://VM:3001   |
+---------+---------+
          |
          v
+-------------------+
|   AnythingLLM     |
|   Agent / Flows   |
+---------+---------+
          |
          v
+-------------------+
|      FastAPI      |
| Monitoring API    |
+----+----------+---+
     |          |
     v          v
+--------+   +---------+
|Netdata |   | Ollama  |
|Servers |   | llama3  |
+--------+   +---------+

</details> <details> <summary>🐳 Docker Networking</summary>

Docker Network

anythingllm ─────► fastapi ─────► Netdata (external)
      │                │
      └──────────────► ollama

</details>

📁 Project Structure

ai-monitoring-stack/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── README.md
├── bootstrap-ai-monitoring-stack.sh
├── data/
│   ├── anythingllm/
│   └── ollama/
└── fastapi/
    ├── Dockerfile
    ├── requirements.txt
    └── main.py

⚡ Quick Start

git clone https://github.com/YOUR-ORG/YOUR-REPO.git
cd YOUR-REPO
chmod +x bootstrap-ai-monitoring-stack.sh
./bootstrap-ai-monitoring-stack.sh

Then:

nano .env
docker compose up -d --build fastapi


<details> <summary>📜 Full Bootstrap Script</summary>

ENTER SCRIPT HERE

</details>

⚙️ Environment Configuration

Edit:

nano .env

Example:

RECIPE_SERVER_URL=http://192.168.0.101:19999
AI_CHATBOT_URL=http://192.168.0.133:19999
COLEMANPLEX_URL=http://192.168.0.150:19999
OLLAMA_BASE_URL=http://ollama:11434
REQUEST_TIMEOUT=10

🌐 AnythingLLM Setup
<details> <summary>👤 First-Time Setup</summary>
Open:
http://YOUR_VM_IP:3001
Create account:
Email
Password
Workspace
Go to Settings → LLM Preferences
Setting	Value
Provider	Ollama
URL	http://ollama:11434
Fetch models
Select llama3
Save
</details>
🔧 Flow Configuration

Use these API URLs inside AnythingLLM flows:

http://fastapi:8000/summary?host=${host}
http://fastapi:8000/cpu?host=${host}
http://fastapi:8000/memory?host=${host}
http://fastapi:8000/status?host=${host}
http://fastapi:8000/anomalies?host=${host}
http://fastapi:8000/compare?host1=${host1}&host2=${host2}

❌ Avoid:

localhost
host.docker.internal
🧪 Testing
<details> <summary>🧪 Run All Tests</summary>
docker ps
curl http://localhost:8000/health
curl http://localhost:11434/api/tags
docker exec -it ollama ollama list
</details>
🤖 Agent Usage

Click the Agent button and try:

@agent What is the status of recipe-server?
More prompts:
@agent Show CPU usage for ai-chatbot
@agent Are there any anomalies on colemanplex?
@agent Compare recipe-server and ai-chatbot

📦 Common Commands
docker compose up -d
docker compose up -d --build fastapi
docker compose down
📁 Git Notes

This project gives you:

🔄 Fully portable Docker stack
🧠 Local LLM (no external cost)
📊 Real-time infrastructure insights
🤖 AI-driven operations interface

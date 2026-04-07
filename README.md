# 🧠 AI Monitoring Agent (Local AI Stack)

A fully self-hosted AI-powered monitoring system that integrates:

- 📊 Netdata (metrics collection)
- ⚡ FastAPI (middleware / API layer)
- 🤖 AnythingLLM (AI interface + agents)
- 🧠 Ollama (local LLMs like llama3)

This stack allows you to ask natural language questions like:

> "What is the CPU usage on recipe-server?"

---

## 🏗️ Architecture Overview


Netdata → FastAPI → AnythingLLM → Ollama


- Netdata collects system metrics
- FastAPI normalizes and exposes endpoints
- AnythingLLM calls APIs via agent flows
- Ollama processes natural language locally

---

## ⚙️ Features

- ✅ Fully local (no external API required)
- ✅ Natural language monitoring
- ✅ Multi-server support
- ✅ Extensible FastAPI endpoints
- ✅ Docker-based deployment
- ✅ One-command bootstrap for new VMs

---

## 📁 Project Structure


ai-monitoring-agent/
├── docker-compose.yml
├── bootstrap.sh
├── install-ai-stack.sh
├── fastapi/
│ ├── main.py
│ ├── routes/
│ └── services/
├── docs/
├── .env.example
├── .gitignore
└── README.md


---

## 🚀 Quick Start (One Command Install)

Run this on a fresh Ubuntu VM:

```bash
curl -fsSL https://raw.githubusercontent.com/gcoleman0828/ai-monitoring-agent/main/bootstrap.sh | bash

This will:

Install Docker + dependencies
Clone the repo
Start containers
Pull llama3
Initialize environment
🔧 Manual Installation
1. Clone Repo
git clone https://github.com/gcoleman0828/ai-monitoring-agent.git
cd ai-monitoring-agent
2. Run Installer
chmod +x install-ai-stack.sh
./install-ai-stack.sh
3. Access Services
Service	URL
AnythingLLM	http://localhost:3001

FastAPI	http://localhost:8000

Ollama	http://localhost:11434
🤖 AnythingLLM Setup (First Time)
Open: http://localhost:3001
Create your account
Go to Settings → LLM
Select:
Provider: Ollama
Model: llama3
🔌 FastAPI Endpoints

Example endpoints:

/health
/summary?host=recipe-server
/cpu?host=recipe-server
/memory?host=recipe-server
🧪 Example API Response
{
  "host": "recipe-server",
  "cpu_usage": 23.5,
  "memory_usage": 61.2,
  "status": "healthy"
}
🤖 AnythingLLM Agent Flow

Use API Call block:

http://host.docker.internal:8000/summary?host=${host}

Define variable:

host = recipe-server
🧠 Example Prompts
"What is the CPU usage on recipe-server?"
"Compare memory usage across all servers"
"Is any server under heavy load?"
🐳 Docker Usage

Start:

docker compose up -d

Stop:

docker compose down

View logs:

docker logs -f anythingllm
🔐 Environment Variables
cp .env.example .env

⚠️ Never commit .env to GitHub.

🧼 Git Workflow (Recommended)
git status
git pull --rebase origin main
git add .
git commit -m "your message"
git push origin main
🛠️ Troubleshooting
Docker Permission Issue
sudo usermod -aG docker $USER

Log out and back in.

Ollama Model Missing
docker exec -it <ollama_container> ollama pull llama3
FastAPI Not Responding
curl http://localhost:8000/health
Port Already in Use
sudo lsof -i :8000
🔮 Future Enhancements
📈 Anomaly detection endpoints
📊 Historical trend analysis
🚨 Alerting system
☁️ AWS integration
📦 Backup / restore flows
🔄 CI/CD pipeline

🛠️ Troubleshooting
Docker Permission Issue

👤 Author

Gregg Coleman
Director of Solution Architecture
AI / Cloud / Infrastructure

⚠️ Disclaimer

This project is for educational and internal use.
Ensure proper security before exposing externally.


---

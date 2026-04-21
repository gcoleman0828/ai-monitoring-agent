# AI Monitoring Agent

A fully local, containerized AI monitoring assistant for Ubuntu that combines:

- **Netdata** for real-time infrastructure metrics
- **FastAPI** as a middleware/API layer
- **Ollama** for local LLM inference
- **AnythingLLM** for chat, tools, and natural-language interaction

This project is designed to let a user ask questions like:

- “What is the CPU usage on recipe-server?”
- “How much memory is used on ai-chatbot?”
- “Give me a summary of colemanplex.”

and have the answer come from **live Netdata-backed data**, not from memory.

---

## What This Project Is For

This project provides a simple, reproducible way to deploy an AI-powered infrastructure assistant on a fresh Ubuntu VM.

It is intended for:

- home lab monitoring
- local AI experimentation
- learning how AI tools can interact with infrastructure APIs
- building a reusable pattern for natural-language operational support

The stack runs locally in Docker containers and is designed to be installed with a single bootstrap process.

---

## High-Level Architecture

```mermaid
flowchart LR
    User[User in Browser]
    A[AnythingLLM]
    O[Ollama]
    F[AI Monitoring API<br/>FastAPI Middleware]
    N1[Netdata<br/>recipe-server]
    N2[Netdata<br/>ai-chatbot]
    N3[Netdata<br/>colemanplex]

    User --> A
    A --> O
    A --> F
    F --> N1
    F --> N2
    F --> N3

    Solution Overview
Components
AnythingLLM

AnythingLLM provides the chat interface and tool or connector capability. It is what the user interacts with in the browser.

Ollama

Ollama runs the local language model, such as llama3, and provides inference to AnythingLLM.

FastAPI Middleware

The FastAPI service acts as the monitoring API layer. It receives tool calls from AnythingLLM, validates the requested host, queries the right Netdata endpoint, and returns structured monitoring data.

Netdata

Netdata is already installed on the monitored hosts and serves real-time system metrics through its API.

Project Structure

A typical project layout looks like this:

ai-monitoring-agent/
├── bootstrap.sh
├── docker-compose.yml
├── .env.example
├── README.md
└── middleware/
    ├── Dockerfile
    ├── requirements.txt
    └── app/
        ├── main.py
        ├── routers/
        └── services/
Key Files
bootstrap.sh
Main installer and deployment script for clean Ubuntu VMs.
docker-compose.yml
Defines the Docker services and networking.
.env.example
Reference file for configuration variables.
middleware/
Contains the FastAPI application code, Dockerfile, and Python dependencies.
Fresh Ubuntu VM Installation

This project is intended to be installed from a clean Ubuntu VM using the bootstrap script.

Supported Flow
Start with a fresh Ubuntu VM
Install Git
Clone the repo over HTTPS
Run bootstrap.sh
Enter the 3 Netdata IP addresses when prompted
Open AnythingLLM
Configure the LLM provider
Create a Workspace
Create an Agent Flow
Configure the monitoring connector
Test monitoring prompts
Prerequisites

Recommended VM:

Ubuntu 24.04 LTS or 22.04 LTS
4 vCPU
8 GB RAM minimum
40 GB disk
Internet access

Ports used by default:

3001 = AnythingLLM
8000 = AI Monitoring API
11434 = Ollama
Step-by-Step Installation
1. Update Ubuntu
sudo apt update && sudo apt upgrade -y
sudo reboot

Reconnect after reboot.

2. Install Git
sudo apt install -y git
3. Clone the Repository

Use HTTPS so the process works for anyone without SSH keys.

git clone https://github.com/gcoleman0828/ai-monitoring-agent.git
cd ai-monitoring-agent
4. Make the Bootstrap Script Executable
chmod +x bootstrap.sh
5. Run the Bootstrap Script
sudo ./bootstrap.sh

During the run, the script will prompt for the IP addresses of:

recipe-server
ai-chatbot
colemanplex

Enter only the raw IP address, for example:

192.168.0.101

Do not include:

http://
https://
:19999
/api/v1

The script builds the full Netdata URL for you.

6. Validate the Deployment

After the script completes, test the services on the Ubuntu VM:

curl http://localhost:8000/health
curl http://localhost:11434/api/tags
sudo docker ps

Expected outcomes:

FastAPI health endpoint responds successfully
Ollama returns model information
the containers are running
7. Open AnythingLLM

From your workstation browser, open:

http://<VM-IP>:3001

Example:

http://192.168.0.133:3001
8. Create the AnythingLLM Admin Account

On first launch:

create the admin account
sign in
9. Configure Ollama in AnythingLLM

Set the provider to Ollama.

Use this internal Docker URL:

http://ollama:11434

Choose model:

llama3
AnythingLLM Workspace Setup

Once AnythingLLM is running and connected to Ollama, create a dedicated Workspace for infrastructure monitoring.

Recommended Workspace Name
AI Infrastructure Monitoring Workspace
Why this name works well

This name is explicit and gives both the user and the LLM immediate context that:

this Workspace is for infrastructure monitoring
it is tied to AI-assisted analysis
it should be used for host health, CPU, memory, and monitoring-related questions
Recommended Workspace Description

Use a description like this:

This workspace is dedicated to live infrastructure monitoring for the monitored Netdata hosts recipe-server, ai-chatbot, and colemanplex. Use the monitoring API tools to retrieve real-time CPU, memory, status, and summary information. Do not answer monitoring questions from memory when a live tool call can be used. Prefer live API-based responses whenever the question is about system health, utilization, anomalies, or comparisons between monitored hosts.
Why this description works well

It tells the LLM:

what the workspace is for
which hosts are valid
that live tool use is preferred
that monitoring questions should not be answered from memory
which types of monitoring questions should trigger tool usage
AnythingLLM Agent Flow Setup

After creating the Workspace, create an Agent Flow for live monitoring requests.

Recommended Agent Flow Name
Live Netdata Infrastructure Monitoring Agent
Why this name works well

This name is strong because it tells the LLM exactly what the flow is for:

Live means real-time data
Netdata identifies the source system
Infrastructure Monitoring identifies the domain
Agent clearly signals this is the operational reasoning path for monitoring questions
Recommended Agent Flow Description

Use this description:

Use this agent flow for any question about the current health, CPU usage, memory usage, overall status, or monitoring summary of recipe-server, ai-chatbot, or colemanplex. This flow must call the monitoring API for live data instead of answering from memory. If a host is not specified, ask which monitored host the user means. If a valid host is provided, call the monitoring API immediately. Prefer tool-based responses for operational questions, infrastructure questions, host health checks, and metric-based requests.
Why this description works well

It gives the model immediate operational guidance:

which questions belong here
which hosts are allowed
that the tool must be called
that memory-only answers are not acceptable for monitoring questions
what to do when the user does not specify a host
AnythingLLM Connector or Tool Setup

Use the internal Docker service name for the monitoring API:

http://ai-monitoring-api:8000
Connector Base URL
http://ai-monitoring-api:8000
Example Health Endpoint
http://ai-monitoring-api:8000/health
Example Summary Endpoint
http://ai-monitoring-api:8000/summary?host=recipe-server
Why this URL is correct

Because AnythingLLM and the FastAPI service run on the same Docker network, they should communicate using the Docker service name, not localhost.

Recommended Monitoring Tool Definition
Tool Name
Live Netdata Host Summary Tool
Why this name works well

This tells the LLM that the tool is:

live
based on Netdata
focused on hosts
used for summary/status retrieval
Tool Description

Use this exact style of description:

Use this tool whenever the user asks about server health, CPU usage, memory usage, performance, current status, or a monitoring summary for a monitored host. Valid hosts are recipe-server, ai-chatbot, and colemanplex. This tool provides live monitoring data from the AI Monitoring API, which is backed by Netdata. Always use this tool for monitoring questions instead of answering from memory. If the user asks for the current state of a host, a live summary, or operational health information, call this tool immediately.
Why this description works well

It tells the LLM:

when to use the tool
which hosts are valid
where the data comes from
that the tool should be preferred over memory
that “current” or “live” monitoring questions must trigger it
Recommended Workspace or System Prompt

If AnythingLLM allows a workspace-level prompt or instruction block, use something like this:

You are an infrastructure monitoring assistant for a local AI monitoring system.

Your job is to answer questions about the live operational status of the monitored hosts:
- recipe-server
- ai-chatbot
- colemanplex

For any question about current CPU usage, current memory usage, health, host status, performance, anomalies, or live summaries, you must use the monitoring API tools instead of answering from memory.

If the user asks a monitoring question and does not specify a host, ask which monitored host they mean.

If the user specifies one of the valid hosts, call the monitoring API immediately.

Do not fabricate metrics. Do not guess live operational status. Use live tool calls whenever the question is about current infrastructure state.

This gives the strongest possible guidance that monitoring questions should trigger the API, not a guessed answer.

Recommended Agent Flow Test Process

Before trying variable-based connector calls, test with a hardcoded host first.

Test 1: Hardcoded summary endpoint

Use:

http://ai-monitoring-api:8000/summary?host=recipe-server

If that works, your internal networking and FastAPI routing are correct.

Test 2: Verify from inside the AnythingLLM container
sudo docker exec -it anythingllm /bin/bash
curl http://ai-monitoring-api:8000/health
curl "http://ai-monitoring-api:8000/summary?host=recipe-server"
Test 3: Real prompt in AnythingLLM

Try:

What is the CPU usage on recipe-server?

If the flow and tool are described well, the model should use the tool immediately.

What bootstrap.sh Does

The bootstrap script is the main installer for the project.

It performs the following tasks
1. Verifies sudo or root execution

The script requires elevated privileges because it installs packages, writes configuration, and manages Docker.

2. Verifies repo context

It checks that it is being run from the correct repo root.

3. Installs required base packages

It installs packages such as:

curl
gnupg
openssl
sed
grep
other required system packages
4. Installs Docker and Docker Compose if missing

It attempts to install:

Docker Engine
Docker Compose plugin

If the preferred Docker CE install path fails, it falls back to Ubuntu packages.

5. Creates .env from scratch

Instead of copying .env.example, the script builds a clean .env itself.

6. Prompts for the 3 Netdata host IP addresses

The user enters only raw IPs, and the script converts them into full Netdata API URLs.

7. Generates a JWT secret

A secure JWT secret is generated automatically.

8. Writes default runtime settings

The script writes defaults such as:

OLLAMA_MODEL=llama3
FASTAPI_PORT=8000
ANYTHINGLLM_PORT=3001
OLLAMA_PORT=11434
9. Builds and starts the Docker containers

It runs the stack using Docker Compose.

10. Waits for service readiness

It checks for:

Ollama API readiness
FastAPI health readiness
11. Pulls the Ollama model

It pulls the configured Ollama model automatically.

12. Prints service URLs and next steps

At the end, it prints where to access the services.

Environment Variables

The bootstrap script creates .env with values similar to:

JWT_SECRET=<generated-secret>
OLLAMA_MODEL=llama3
NETDATA_RECIPE_SERVER_URL=http://192.168.0.192:19999/api/v1
NETDATA_AI_CHATBOT_URL=http://192.168.0.133:19999/api/v1
NETDATA_COLEMANPLEX_URL=http://192.168.0.69:19999/api/v1
FASTAPI_PORT=8000
ANYTHINGLLM_PORT=3001
OLLAMA_PORT=11434
What each value means
JWT_SECRET

Used by the FastAPI application for JWT or security-related functionality.

OLLAMA_MODEL

The Ollama model AnythingLLM should use. Current default:

OLLAMA_MODEL=llama3
NETDATA_RECIPE_SERVER_URL

The full Netdata API endpoint for the recipe-server host.

Example:

NETDATA_RECIPE_SERVER_URL=http://192.168.0.192:19999/api/v1
NETDATA_AI_CHATBOT_URL

The full Netdata API endpoint for the ai-chatbot host.

Example:

NETDATA_AI_CHATBOT_URL=http://192.168.0.133:19999/api/v1
NETDATA_COLEMANPLEX_URL

The full Netdata API endpoint for the colemanplex host.

Example:

NETDATA_COLEMANPLEX_URL=http://192.168.0.69:19999/api/v1
FASTAPI_PORT

Port exposed on the Ubuntu host for the AI Monitoring API.

Default:

FASTAPI_PORT=8000
ANYTHINGLLM_PORT

Port exposed on the Ubuntu host for AnythingLLM.

Default:

ANYTHINGLLM_PORT=3001
OLLAMA_PORT

Port exposed on the Ubuntu host for Ollama.

Default:

OLLAMA_PORT=11434
What the IP Addresses Mean

When the bootstrap script asks for IP addresses, it is asking for the hosts where Netdata is already installed and reachable.

Example Mapping

If prompted for recipe-server, and the real server IP is:

192.168.0.192

the bootstrap script converts that into:

http://192.168.0.192:19999/api/v1

That becomes the value of:

NETDATA_RECIPE_SERVER_URL
Summary

The user enters this:

192.168.0.192

The script builds this:

http://192.168.0.192:19999/api/v1

This prevents formatting errors and keeps the install process simpler.

Docker Service Naming

The stack uses consistent internal service naming to keep Docker networking and AnythingLLM connector configuration clean.

Recommended internal API name:

ai-monitoring-api

This allows AnythingLLM to reach the API internally using:

http://ai-monitoring-api:8000

This is more intuitive than using a generic name such as fastapi.

Troubleshooting

This section covers the most common issues encountered during build, deployment, and testing.

Error: Required command not found: docker
Cause

Docker was not installed before the old bootstrap logic checked for it.

Solution

Use the updated bootstrap script that installs Docker automatically.

Then rerun:

sudo ./bootstrap.sh
Error: duplicated variables in .env
Cause

Earlier versions of the script appended to .env incorrectly or mixed generated values with copied placeholder values.

Solution

The current bootstrap creates .env from scratch and avoids .env.example as the runtime source.

Delete the old .env and rerun:

rm -f .env
sudo ./bootstrap.sh
Error: JWT_SECRET missing in .env
Cause

Earlier .env generation logic created malformed or incomplete files.

Solution

The current bootstrap generates JWT_SECRET automatically. If needed:

rm -f .env
sudo ./bootstrap.sh
Error: key cannot contain a space
Cause

The generated .env was malformed because prompt text was accidentally written into the file.

Solution

Use the corrected bootstrap script and recreate .env:

rm -f .env
sudo ./bootstrap.sh
Error: FastAPI container restarting with ModuleNotFoundError: No module named 'requests'
Cause

The middleware container image was missing the requests dependency.

Solution

Add requests to requirements.txt, then rebuild:

sudo docker compose down
sudo docker compose up -d --build
Error: FastAPI /health works but /summary returns 400
Cause

The request reached the API, but the API rejected the host or could not map it correctly.

Common reasons
wrong environment variable names
stale container
host mapping mismatch in Python code
Solution

Make sure the Python code uses the same env vars the bootstrap writes:

NETDATA_HOSTS = {
    "recipe-server": os.getenv("NETDATA_RECIPE_SERVER_URL", ""),
    "ai-chatbot": os.getenv("NETDATA_AI_CHATBOT_URL", ""),
    "colemanplex": os.getenv("NETDATA_COLEMANPLEX_URL", ""),
}

Then rebuild:

sudo docker compose down
sudo docker compose up -d --build --force-recreate
Error: /summary returns No Netdata URL configured for host 'recipe-server'
Cause

The FastAPI code expected different environment variable names than the bootstrap created.

Solution

Update the Python code to use:

NETDATA_RECIPE_SERVER_URL
NETDATA_AI_CHATBOT_URL
NETDATA_COLEMANPLEX_URL

Then rebuild the container.

Error: old container names still appear, such as fastapi
Cause

Docker was still using older containers from a previous compose configuration.

Solution

Clean up stale containers and rebuild:

sudo docker compose down --remove-orphans
sudo docker rm -f fastapi ai-monitoring-agent ai-monitoring-api anythingllm ollama 2>/dev/null || true
sudo docker network prune -f
sudo docker compose up -d --build --force-recreate
Error: permission denied while trying to connect to the docker API socket
Cause

The current user is not in the Docker group.

Solution

Use sudo for Docker commands:

sudo docker ps

Optional improvement:

sudo usermod -aG docker $USER
newgrp docker
Error: binding or network conflict when rebuilding
Cause

Old containers, orphaned services, or host processes were still using the required ports.

Solution

Check for port conflicts:

sudo ss -tulpn | grep -E ':3001|:8000|:11434'

If needed, clean up Docker resources and rebuild:

sudo docker compose down --remove-orphans
sudo docker network prune -f
sudo docker compose up -d --build
Error: AnythingLLM connector cannot reach the API
Cause

Wrong internal Docker hostname was used.

Solution

Use the Docker service name, not host localhost. Recommended:

http://ai-monitoring-api:8000

Test from inside the AnythingLLM container:

sudo docker exec -it anythingllm /bin/bash
curl http://ai-monitoring-api:8000/health
Error: AnythingLLM connector returns 400 for /summary
Cause

The connector path worked, but the API rejected the request based on input validation or backend mapping.

Solution

First test the endpoint directly:

curl "http://localhost:8000/summary?host=recipe-server"

Then confirm:

the env vars are present in the API container
the host mapping in Python matches the expected host names
the service has been rebuilt after config or code changes
Error: curl: (56) Recv failure: Connection reset by peer
Cause

The connection reached the API service, but the app reset or failed while processing the request.

Solution

Follow container logs while testing:

sudo docker logs -f ai-monitoring-api

Then run the failing request again in another terminal.

Error: AnythingLLM works but monitoring prompts do not trigger the tool consistently
Cause

The tool description or workspace instructions are not strong enough.

Solution

Use a stricter tool description and system prompt that explicitly says:

always call the monitoring tool for infrastructure questions
valid hosts are recipe-server, ai-chatbot, and colemanplex
do not answer monitoring questions from memory
Useful Validation Commands
Health Checks
curl http://localhost:8000/health
curl http://localhost:11434/api/tags
Container Status
sudo docker ps
sudo docker compose ps
FastAPI Logs
sudo docker logs -f ai-monitoring-api
AnythingLLM Internal Connectivity Test
sudo docker exec -it anythingllm /bin/bash
curl http://ai-monitoring-api:8000/health
curl http://ollama:11434/api/tags
Day-2 Operations
Rebuild after code changes
sudo docker compose down
sudo docker compose up -d --build
Fully recreate containers after major config or naming changes
sudo docker compose down --remove-orphans
sudo docker compose up -d --build --force-recreate
View Logs
sudo docker logs -f ai-monitoring-api
sudo docker logs -f anythingllm
sudo docker logs -f ollama
Future Enhancements

Potential next improvements:

add more monitoring endpoints such as compare and anomalies
add stronger API error handling and validation
add health checks in Docker Compose
add persistent AnythingLLM storage validation
add a sample AnythingLLM tool definition export
add screenshots to the README
add a one-command validation script
Summary

AI Monitoring Agent is a local AI-powered infrastructure assistant that combines Netdata, FastAPI, Ollama, and AnythingLLM into a single containerized solution.

It is designed to be:

reproducible
local-first
easy to install on a clean Ubuntu VM
understandable for learning and iteration

The bootstrap-driven install flow keeps deployment simple while allowing the system to answer natural-language monitoring questions using live infrastructure data.
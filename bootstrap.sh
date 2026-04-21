#!/usr/bin/env bash
set -euo pipefail

PULL_OLLAMA_MODEL="${PULL_OLLAMA_MODEL:-yes}"

log() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $1"
    exit 1
  fi
}

ensure_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "ERROR: Please run this script with sudo."
    echo "Example: sudo ./bootstrap.sh"
    exit 1
  fi
}

install_base_packages() {
  log "Installing required base packages if missing"
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release openssl sed grep bash
}

install_docker_if_missing() {
  local need_docker="no"
  local need_compose="no"

  if ! command -v docker >/dev/null 2>&1; then
    need_docker="yes"
  fi

  if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
    need_compose="yes"
  fi

  if [ "$need_docker" = "no" ] && [ "$need_compose" = "no" ]; then
    log "Docker and docker compose plugin already installed"
    return
  fi

  log "Installing Docker and docker compose plugin"

  install -m 0755 -d /etc/apt/keyrings

  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  local arch
  arch="$(dpkg --print-architecture)"

  local codename
  codename="$(. /etc/os-release && echo "${VERSION_CODENAME:-}")"

  if [ -n "$codename" ]; then
    cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable
EOF
  fi

  apt-get update || true

  if ! apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    log "Docker CE install failed, falling back to Ubuntu packages"
    apt-get update
    apt-get install -y docker.io docker-compose-v2 || apt-get install -y docker.io
  fi

  systemctl enable docker
  systemctl restart docker

  if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker installation completed but 'docker' command is still unavailable."
    echo "Check: apt-cache policy docker-ce docker.io"
    exit 1
  fi

  log "Docker installation complete"
  docker --version

  if docker compose version >/dev/null 2>&1; then
    docker compose version
  else
    echo "ERROR: Docker installed but docker compose plugin is still unavailable."
    exit 1
  fi
}

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

get_env_value() {
  local key="$1"
  local value=""
  if [ -f ".env" ] && grep -q "^${key}=" .env; then
    value="$(grep "^${key}=" .env | tail -n1 | cut -d= -f2-)"
  fi
  printf '%s' "$value"
}

set_env_value() {
  local key="$1"
  local value="$2"
  local escaped
  escaped="$(escape_sed_replacement "$value")"

  if [ -f ".env" ] && grep -q "^${key}=" .env; then
    sed -i "s/^${key}=.*/${key}=${escaped}/" .env
  else
    if [ -f ".env" ] && [ -s ".env" ] && [ "$(tail -c 1 .env 2>/dev/null || true)" != "" ]; then
      echo >> .env
    fi
    echo "${key}=${value}" >> .env
  fi
}

normalize_env_file() {
  if [ -f ".env" ]; then
    sed -i 's/\r$//' .env
    if [ -s ".env" ] && [ "$(tail -c 1 .env 2>/dev/null || true)" != "" ]; then
      echo >> .env
    fi
  fi
}

is_valid_ip() {
  local ip="$1"
  if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    return 1
  fi

  IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
  for octet in "$o1" "$o2" "$o3" "$o4"; do
    if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
      return 1
    fi
  done

  return 0
}

prompt_for_ip() {
  local label="$1"
  local current_ip="$2"
  local user_input=""

  while true; do
    >&2 echo
    >&2 echo "Enter the IP address for ${label}."
    >&2 echo "Examples: 192.168.0.101 or 10.0.0.25"
    >&2 echo "Do not include http:// or a port."

    if [ -n "$current_ip" ]; then
      read -r -p "${label} IP [${current_ip}]: " user_input </dev/tty
      if [ -z "$user_input" ]; then
        user_input="$current_ip"
      fi
    else
      read -r -p "${label} IP: " user_input </dev/tty
    fi

    if is_valid_ip "$user_input"; then
      printf '%s' "$user_input"
      return 0
    fi

    >&2 echo "Invalid IP address format. Please enter an IPv4 address like 192.168.0.101"
  done
}

extract_ip_from_url() {
  local url="$1"
  local extracted=""

  if [[ "$url" =~ ^http://([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):19999/api/v1$ ]]; then
    extracted="${BASH_REMATCH[1]}"
  fi

  printf '%s' "$extracted"
}

build_netdata_url() {
  local ip="$1"
  printf 'http://%s:19999/api/v1' "$ip"
}

create_env_from_scratch() {
  local recipe_ip="$1"
  local chatbot_ip="$2"
  local colemanplex_ip="$3"
  local jwt_secret="$4"

  log "Creating .env from scratch"

  cat > .env <<EOF
JWT_SECRET=${jwt_secret}
OLLAMA_MODEL=llama3
NETDATA_RECIPE_SERVER_URL=$(build_netdata_url "$recipe_ip")
NETDATA_AI_CHATBOT_URL=$(build_netdata_url "$chatbot_ip")
NETDATA_COLEMANPLEX_URL=$(build_netdata_url "$colemanplex_ip")
FASTAPI_PORT=8000
ANYTHINGLLM_PORT=3001
OLLAMA_PORT=11434
EOF
}

ensure_env_exists_and_is_valid() {
  local recipe_ip=""
  local chatbot_ip=""
  local colemanplex_ip=""
  local jwt_secret=""

  if [ -f ".env" ]; then
    normalize_env_file

    recipe_ip="$(extract_ip_from_url "$(get_env_value "NETDATA_RECIPE_SERVER_URL")")"
    chatbot_ip="$(extract_ip_from_url "$(get_env_value "NETDATA_AI_CHATBOT_URL")")"
    colemanplex_ip="$(extract_ip_from_url "$(get_env_value "NETDATA_COLEMANPLEX_URL")")"
    jwt_secret="$(get_env_value "JWT_SECRET")"
  fi

  if [ -z "$jwt_secret" ]; then
    jwt_secret="$(openssl rand -hex 32)"
  fi

  recipe_ip="$(prompt_for_ip "recipe-server" "$recipe_ip")"
  chatbot_ip="$(prompt_for_ip "ai-chatbot" "$chatbot_ip")"
  colemanplex_ip="$(prompt_for_ip "colemanplex" "$colemanplex_ip")"

  create_env_from_scratch "$recipe_ip" "$chatbot_ip" "$colemanplex_ip" "$jwt_secret"
}

validate_required_env_values() {
  log "Validating required .env values"

  grep -q "^JWT_SECRET=" .env || { echo "ERROR: JWT_SECRET missing in .env"; exit 1; }
  grep -q "^OLLAMA_MODEL=" .env || { echo "ERROR: OLLAMA_MODEL missing in .env"; exit 1; }
  grep -q "^NETDATA_RECIPE_SERVER_URL=" .env || { echo "ERROR: NETDATA_RECIPE_SERVER_URL missing in .env"; exit 1; }
  grep -q "^NETDATA_AI_CHATBOT_URL=" .env || { echo "ERROR: NETDATA_AI_CHATBOT_URL missing in .env"; exit 1; }
  grep -q "^NETDATA_COLEMANPLEX_URL=" .env || { echo "ERROR: NETDATA_COLEMANPLEX_URL missing in .env"; exit 1; }

  local jwt_secret
  jwt_secret="$(get_env_value "JWT_SECRET")"
  local ollama_model
  ollama_model="$(get_env_value "OLLAMA_MODEL")"
  local recipe_url
  recipe_url="$(get_env_value "NETDATA_RECIPE_SERVER_URL")"
  local chatbot_url
  chatbot_url="$(get_env_value "NETDATA_AI_CHATBOT_URL")"
  local colemanplex_url
  colemanplex_url="$(get_env_value "NETDATA_COLEMANPLEX_URL")"

  [ -n "$jwt_secret" ] || { echo "ERROR: JWT_SECRET is blank in .env"; exit 1; }
  [ -n "$ollama_model" ] || { echo "ERROR: OLLAMA_MODEL is blank in .env"; exit 1; }
  [ -n "$recipe_url" ] || { echo "ERROR: NETDATA_RECIPE_SERVER_URL is blank in .env"; exit 1; }
  [ -n "$chatbot_url" ] || { echo "ERROR: NETDATA_AI_CHATBOT_URL is blank in .env"; exit 1; }
  [ -n "$colemanplex_url" ] || { echo "ERROR: NETDATA_COLEMANPLEX_URL is blank in .env"; exit 1; }
}

wait_for_url() {
  local name="$1"
  local url="$2"
  local max_attempts="${3:-30}"
  local sleep_seconds="${4:-2}"

  log "Waiting for ${name}"
  for ((i=1; i<=max_attempts; i++)); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo "${name} is responding."
      return 0
    fi
    sleep "$sleep_seconds"
  done

  echo "ERROR: ${name} did not become ready in time."
  return 1
}

main() {
  ensure_root

  log "Checking that script is running from repo root"
  if [ ! -f "docker-compose.yml" ] || [ ! -f "bootstrap.sh" ]; then
    echo "ERROR: Run this script from the ai-monitoring-agent repo root."
    exit 1
  fi

  install_base_packages
  install_docker_if_missing

  log "Checking required tools"
  require_cmd docker
  require_cmd bash
  require_cmd grep
  require_cmd sed
  require_cmd curl
  require_cmd openssl

  if ! docker compose version >/dev/null 2>&1; then
    echo "ERROR: docker compose plugin is required."
    exit 1
  fi

  log "Setting script permissions"
  chmod +x *.sh || true
  chmod +x scripts/*.sh || true

  ensure_env_exists_and_is_valid
  validate_required_env_values

  log "Building and starting containers"
  docker compose up -d --build

  local ollama_port
  ollama_port="$(get_env_value "OLLAMA_PORT")"
  if [ -z "$ollama_port" ]; then
    ollama_port="11434"
  fi
  wait_for_url "Ollama API" "http://localhost:${ollama_port}/api/tags" 30 2

  if [ "$PULL_OLLAMA_MODEL" = "yes" ]; then
    log "Pulling Ollama model"
    docker exec ollama ollama pull "$(get_env_value "OLLAMA_MODEL")"
  fi

  local fastapi_port
  fastapi_port="$(get_env_value "FASTAPI_PORT")"
  if [ -z "$fastapi_port" ]; then
    fastapi_port="8000"
  fi
  wait_for_url "FastAPI" "http://localhost:${fastapi_port}/health" 30 2

  log "Checking container status"
  docker compose ps

  local anythingllm_port
  anythingllm_port="$(get_env_value "ANYTHINGLLM_PORT")"
  if [ -z "$anythingllm_port" ]; then
    anythingllm_port="3001"
  fi

  log "Bootstrap complete"
  echo "AnythingLLM: http://localhost:${anythingllm_port}"
  echo "Ollama:      http://localhost:${ollama_port}"
  echo "FastAPI:     http://localhost:${fastapi_port}"
  echo
  echo "Configured Netdata endpoints:"
  echo "  recipe-server: $(get_env_value "NETDATA_RECIPE_SERVER_URL")"
  echo "  ai-chatbot:    $(get_env_value "NETDATA_AI_CHATBOT_URL")"
  echo "  colemanplex:   $(get_env_value "NETDATA_COLEMANPLEX_URL")"
  echo
  echo "Next steps:"
  echo "1. Open AnythingLLM"
  echo "2. Create your admin account"
  echo "3. Set provider to Ollama"
  echo "4. Use Ollama URL: http://ollama:11434 if inside the app config, or http://localhost:${ollama_port} from the host browser"
}

main "$@"
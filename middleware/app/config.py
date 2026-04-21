import os
from dotenv import load_dotenv

load_dotenv()

API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8000"))

ALLOWED_HOSTS = [
    host.strip() for host in os.getenv(
        "ALLOWED_HOSTS",
        "recipe-server,ai-chatbot,colemanplex"
    ).split(",")
]

NETDATA_HOSTS = {
    "recipe-server": os.getenv("NETDATA_RECIPE_SERVER_URL") or os.getenv("NETDATA_URL_RECIPE", ""),
    "ai-chatbot": os.getenv("NETDATA_AI_CHATBOT_URL") or os.getenv("NETDATA_URL_AI", ""),
    "colemanplex": os.getenv("NETDATA_COLEMANPLEX_URL") or os.getenv("NETDATA_URL_COLEMANPLEX", ""),
}
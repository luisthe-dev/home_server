# Home Server Base Infrastructure

A unified local stack powering databases, cache, search engines, and self-hosted AI models via Docker Compose.

---

## 🏗️ Architecture Overview

| Service | Port (Host) | Internal DNS | Purpose |
| :--- | :--- | :--- | :--- |
| **MySQL** | `3306` | `mysql:3306` | Relational database |
| **PostgreSQL** | `5432` | `postgres:5432` | Relational database (`/var/lib/postgresql/data`) |
| **Redis** | `6379` | `redis:6379` | Key-value store & cache |
| **Redis Insight**| `5540` | `redis-insight:5540` | Redis GUI management |
| **Raphael** | `11434` | `raphael:11434` | Ollama LLM runtime & automated persona builder |
| **SearxNG** | `1234` | `search:8080` | Privacy-respecting meta search engine |
| **Meilisearch** | `7700` | `meilisearch:7700` | Fast typo-tolerant search engine |

All services communicate over the internal bridge network: `servers`.

---

## 🚀 Quick Start

### 1. Configuration
Copy the template configuration and customize if desired:
```bash
cp .env.example .env
```

Key environment settings in `.env`:
- `BIND_IP`: Defaults to `127.0.0.1` (accessible only from the host). Change to `0.0.0.0` to allow local area network access.
- `OLLAMA_MODELS`: Comma-separated list of models to pull on startup (e.g. `llama3.1,gemma4,deepseek-r1,qwen3.5,qwen2.5-coder`).

### 2. Start Services
```bash
# Start all services in the background
docker compose up -d

# Check running status
docker compose ps

# View logs for a specific service (e.g., Raphael)
docker compose logs -f raphael
```

---

## 🤖 Raphael (Ollama Engine & Personas)

### Dynamic Model Loading
Models to download on container launch can be specified in two ways (in order of priority):
1. **Environment variable:** `OLLAMA_MODELS` in `.env` (comma-separated):
   ```env
   OLLAMA_MODELS=llama3.1,gemma4,deepseek-r1,qwen3.5,qwen2.5-coder
   ```
2. **External file:** [`raphael/models.txt`](raphael/models.txt) (one model per line).

### Custom Personas
Place Ollama `Modelfile` definitions inside `raphael/my_models/` using either `Modelfile.<alias>` or `<alias>.Modelfile`.

Example personas included:
- `raphael/my_models/Modelfile.coder` ➔ builds model persona `coder`
- `raphael/my_models/Modelfile.researcher` ➔ builds model persona `researcher`
- `raphael/my_models/Modelfile.reasoner` ➔ builds model persona `reasoner`

Personas are tracked with an MD5 hash cache (`raphael/hash_cache.json`). They are automatically recompiled only when their respective Modelfile changes.

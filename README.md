# AI Docker Compose Kit

This repository provides a **modular, multi-container AI environment** for local development, agent orchestration, and high-performance Retrieval-Augmented Generation (RAG).

It is designed as a **local AI infrastructure platform**—a “local brain”—where all services operate within a unified Docker network, enabling low-latency communication, shared context, and controlled execution.

---

## 🧠 Architecture Overview

The system is structured into four layers:

### 1. Core Infrastructure

Persistent data stores and inference runtime:

* PostgreSQL, Redis, MongoDB, MySQL
* Qdrant (vector DB), SurrealDB, Infinity
* MinIO (object storage), CouchDB
* Ollama (LLM runtime)

### 2. Application Layer

User-facing tools and orchestration systems:

* Open WebUI, Dify, Flowise
* AnythingLLM, RAGFlow, Open-NotebookLM
* n8n (automation), Gitea (code), SearXNG (search)
* Obsidian Remote (knowledge interface)

### 3. Agent Layer (Optional)

* **OpenClaw**: system-level AI agent with access to internal services

### 4. Execution Layer

* **Docker Sandbox** (recommended): isolated execution environment for agent tools
* Enforced **egress control via proxy allowlists**

---

## ⚙️ Installation

1. **Requirements**

   * Docker
   * NVIDIA Container Toolkit (optional, for GPU acceleration)

2. **Clone & Prepare**

   ```bash
   git clone <repo>
   cd ai-docker-stack
   mkdir obsidian_vault
   ```

3. **Configure Environment**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and change all credentials before exposing ports.

4. **Start Core + Apps**

   ```bash
   docker compose -f compose.yaml -f compose.apps.yaml up -d
   ```

5. **Optional: Add OpenClaw**

   ```bash
   docker compose -f compose.yaml -f compose.apps.yaml -f compose.openclaw.yaml up -d
   ```

6. **Optional: Dev Tools**

   ```bash
   docker compose -f compose.yaml -f compose.apps.yaml -f compose.dev.yaml up -d
   ```

---

## 🚀 Startup Behavior

* Core services must pass health checks before dependents start
* `ollama-init`:

  * waits for Ollama
  * pulls `${OLLAMA_BOOTSTRAP_MODEL}`
  * exits once complete
* All LLM-dependent services wait for model readiness

This prevents race conditions across the stack.

---

## 🔗 Internal Integration Matrix

All services communicate via internal Docker DNS:

* `open-webui` → `ollama`
* `dify` → `postgres`, `redis`, `qdrant`, `mongodb`, `couchdb`
* `flowise` → `postgres`, `qdrant`, `ollama`
* `n8n` → `postgres`, `redis`, `ollama`, `gitea`, `searxng`, `mercure`
* `anythingllm` → `ollama`, `qdrant`
* `ragflow` → `mysql`, `redis`, `minio`, `infinity`, `ollama`
* `open-notebooklm` → `surrealdb`, `qdrant`, `ollama`
* `obsidian-remote` → `couchdb`

---

## 🔐 Security Model

### Internal Access

* Services communicate freely within internal Docker networks

### External Egress

* **Deny-by-default**
* HTTPS allowed only via allowlist (recommended)

### Agent Execution

* OpenClaw executes tools through **Docker Sandbox**
* No direct host access
* No Docker socket exposure

---

## 🌐 Egress Policy (Recommended)

Example allowlist:

```text
github.com
api.github.com
raw.githubusercontent.com
pypi.org
files.pythonhosted.org
registry.npmjs.org
deb.debian.org
security.debian.org
```

All outbound traffic from agent execution should pass through a proxy enforcing this policy.

---

## 🧪 Verification

```bash
docker compose config >/tmp/stack.rendered.yml
docker compose ps
docker compose exec ollama ollama list
```

Quick health check:

```bash
docker compose exec n8n sh -lc \
'wget -qO- http://qdrant:6333/healthz && echo && wget -qO- http://ollama:11434/api/tags'
```

---

## 🧰 Component Breakdown

### Core Engine

* **Ollama** — local LLM runtime
* **Open WebUI** — primary UI

### Agentic Systems

* **Dify** — full-stack LLM app platform
* **Flowise** — visual LLM pipelines
* **OpenClaw** — system-level agent (optional)

### Dev & Analysis

* **Jupyter** — experimentation
* **Open-NotebookLM** — document reasoning
* **Gitea** — local Git hosting

### RAG & Search

* **AnythingLLM**, **RAGFlow**
* **Unstructured API** — document parsing
* **SearXNG** — privacy-first search

### Automation & Knowledge

* **n8n** — workflow orchestration
* **Obsidian Remote** — knowledge interface
* **Mercure** — real-time updates

### Storage

* PostgreSQL, MongoDB, Redis
* Qdrant, SurrealDB, Infinity
* MySQL, MinIO, CouchDB

---

## 🧠 Value Proposition: Local AI Infrastructure

This stack provides:

### Zero-Latency RAG

Internal networking eliminates external API overhead.

### Privacy-First Operation

All data, inference, and orchestration remain local.

### Unified Context

Every service shares access to:

* `obsidian_vault`
* local repositories (Gitea)
* internal vector memory (Qdrant)

### Agent-Orchestrated Workflows

With OpenClaw + n8n:

* trigger workflows from notes
* perform autonomous reasoning
* update codebases
* query local + external data (controlled)

---

## ⚠️ Design Principles

* **No Docker socket exposure**
* **No privileged containers**
* **Internal-first networking**
* **Explicit egress control**
* **Composable architecture via multiple compose files**

---

## 🧭 Future Direction

* Agent API layer (OpenClaw integration)
* Dynamic egress policies
* Model routing and optimization
* Dataset versioning via MinIO

---

## 🧩 Summary

This repository is not just a collection of tools.

It is a **local AI operating environment**:

* inference
* memory
* automation
* orchestration
* development

All running within a controlled, extensible Docker system.

---

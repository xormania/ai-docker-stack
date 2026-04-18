# AI Docker Compose Kit

This repository contains a high-intelligence, multi-container Docker environment designed for local AI development, autonomous agent management, and high-fidelity Retrieval-Augmented Generation (RAG). It integrates cutting-edge inference engines, vector databases, and automation tools into a single, cohesive network.

## Installation

1.  **System Requirements**: Ensure you have Docker and the NVIDIA Container Toolkit installed (for GPU-accelerated inference).
2.  **Clone & Prepare**: Clone this repository and create an `obsidian_vault` directory in the root to serve as the shared knowledge base.
3.  **Create Environment File**:
     ```bash
     cp .env.example .env
     ```
     Review `.env` and change all default credentials before exposing ports beyond localhost.
4.  **Docker Login**
    ```bash
    docker login
    ```
5.  **Deployment**:
    ```bash
    docker compose up -d
    ```
6.  **Access**: Services are mapped to specific ports (e.g., Open WebUI at `http://localhost:3000`).

### Startup Behavior

The stack now uses health-gated startup for core dependencies:
- Infrastructure services (`postgres`, `redis`, `qdrant`, `mysql`, `minio`, `couchdb`, `mongodb`) must be healthy before dependent services start.
- `ollama-init` waits for `ollama`, pulls `OLLAMA_BOOTSTRAP_MODEL` (default `qwen3.5:current`) once, and exits successfully.
- LLM clients (`open-webui`, `anythingllm`, `flowise`, `openhands`, `jupyter`) wait for `ollama-init` completion.

This prevents race conditions where agent and RAG services start before their backing stores and model endpoint are ready.

### Integration Matrix (Internal URLs)

- `open-webui` -> `ollama` via `OLLAMA_BASE_URL`
- `dify-api` / `dify-worker` -> `postgres`, `redis`, `qdrant`, `ollama`, `mongodb`, `couchdb`
- `flowise` -> `postgres`, `ollama`, `qdrant`
- `openhands` -> `ollama`, `gitea`, `mongodb` with feature-branch auto-commit controls
- `n8n` -> `postgres`, `redis`, `ollama`, `gitea`, `searxng`, `mercure`, `mongodb`, `couchdb`
- `anythingllm` -> `ollama`, `qdrant`
- `ragflow` -> `mysql`, `redis`, `minio`, `infinity`, `ollama`
- `open-notebooklm` -> `surrealdb`, `ollama`, `qdrant`
- `obsidian-remote` -> `couchdb` sync endpoint via `COUCHDB_URL`

### Verification Commands

1. Validate compose rendering and env interpolation:
    ```bash
    docker compose config >/tmp/stack.rendered.yml
    ```
2. Confirm service health status:
    ```bash
    docker compose ps
    ```
3. Confirm model bootstrap in Ollama:
    ```bash
    docker compose exec ollama ollama list
    ```
4. Quick API checks:
    ```bash
    docker compose exec n8n sh -lc 'wget -qO- http://qdrant:6333/healthz && echo && wget -qO- http://ollama:11434/api/tags'
    ```
5. Confirm OpenHands can resolve Gitea endpoint:
    ```bash
    docker compose exec openhands sh -lc 'wget -qO- http://gitea:3000 >/dev/null && echo ok'
    ```

---

## Component Breakdown

### Core Engine & Interfaces
* **Ollama**: The primary inference engine for running high-performance LLMs locally. It handles model loading and API serving. [GitHub](https://github.com/ollama/ollama)
* **Open WebUI**: A feature-rich, self-hosted web interface for interacting with Ollama. It serves as the main dashboard for daily chat and prompt engineering. [GitHub](https://github.com/open-webui/open-webui)

### Agentic Management Systems
* **Dify**: A comprehensive LLM application development platform. It manages the full lifecycle of AI apps, from prompt orchestration to operational observability. [GitHub](https://github.com/langgenius/dify)
* **Flowise**: A low-code, drag-and-drop tool for building complex, customized LLM flows and agentic chains using LangChain and LlamaIndex. [GitHub](https://github.com/FlowiseAI/Flowise)
* **OpenHands**: An autonomous AI software engineer capable of writing code, running commands, and managing complex development tasks within a sandbox. [GitHub](https://github.com/All-Hands-AI/OpenHands)

### Development & Analytical Tools
* **Jupyter Notebook**: A PyTorch-enabled environment for model fine-tuning, data science, and interactive Python development. [GitHub](https://github.com/jupyter/docker-stacks)
* **Open-NotebookLM**: A local alternative to Google's NotebookLM, allowing for source-grounded analysis and document-based insights. [GitHub](https://github.com/coille/open-notebook)
* **Gitea**: A lightweight, self-hosted Git service to manage your local code repositories and AI-generated scripts. [GitHub](https://github.com/go-gitea/gitea)

### RAG & Search Infrastructure
* **AnythingLLM**: A workspace-centric RAG application that simplifies document ingestion and vector storage management. [GitHub](https://github.com/Mintplex-Labs/anything-llm)
* **RAGFlow**: An advanced RAG system specializing in deep document understanding, particularly effective at parsing complex tables and layouts. [GitHub](https://github.com/infiniflow/ragflow)
* **Unstructured API**: A specialized service for pre-processing and cleaning "messy" data formats (PDFs, PPTXs, HTML) before they are embedded. [GitHub](https://github.com/Unstructured-IO/unstructured)
* **SearXNG**: A privacy-respecting metasearch engine that provides your LLMs and agents with real-time web context without external API keys. [GitHub](https://github.com/searxng/searxng)

### Automation & Knowledge Management
* **n8n**: A powerful workflow automation tool that connects various AI services and external APIs into event-driven pipelines. [GitHub](https://github.com/n8n-io/n8n)
* **Obsidian Remote**: A browser-based interface for your Obsidian vault, enabling real-time PKM management within the Docker network. [GitHub](https://github.com/sytone/obsidian-remote)
* **CouchDB**: The database backend for private, self-hosted Obsidian synchronization across your devices. [GitHub](https://github.com/apache/couchdb)
* **Mercure**: A real-time hub for pushing server-sent events (SSE) to modern web interfaces, ensuring instantaneous updates across the stack. [GitHub](https://github.com/dunglas/mercure)

### Data Persistence & Storage
* **PostgreSQL**: The primary relational database for n8n, Gitea, Dify, and Flowise. [GitHub](https://github.com/postgres/postgres)
* **MongoDB**: A NoSQL document store used for high-velocity logging and unstructured agentic state storage. [GitHub](https://github.com/mongodb/mongo)
* **Qdrant**: A high-performance vector database that stores and retrieves embeddings for RAG and agentic memory. [GitHub](https://github.com/qdrant/qdrant)
* **SurrealDB**: A multi-model database that powers the analytical capabilities of Open-NotebookLM. [GitHub](https://github.com/surrealdb/surrealdb)
* **Redis**: A key-value store used for high-speed caching and message brokering across the automation layer. [GitHub](https://github.com/redis/redis)
* **MySQL**: Relational storage specifically allocated for managing RAGFlow metadata. [GitHub](https://github.com/mysql/mysql-server)
* **MinIO**: An S3-compatible object storage server used for managing large datasets and binary assets. [GitHub](https://github.com/minio/minio)
* **Infinity**: An AI-native database optimized for ultra-fast hybrid search, including dense/sparse vectors and full-text indexing. [GitHub](https://github.com/infiniflow/infinity)

---

## Value Proposition: The "Local Brain" Ecosystem

The primary advantage of this "all-under-one-roof" architecture is **seamless context continuity**. In traditional setups, data is siloed between a note-taking app, a coding IDE, and an automation platform. In this stack, every major service—from your coding agent (OpenHands) to your automation workflows (n8n) and analytical tools (Jupyter)—has direct, simultaneous access to your `obsidian_vault` and local `Gitea` repositories.

By containerizing these services within a single Docker network:
1.  **Zero-Latency RAG**: Your vector database (Qdrant) and inference engine (Ollama) communicate over high-speed internal bridge networks, drastically reducing the time between data ingestion and retrieval.
2.  **Privacy-First Intelligence**: No data leaves your local network. Your internal searches (SearXNG), document parsing (Unstructured), and agentic logic are entirely self-contained.
3.  **Cross-Service Orchestration**: An n8n workflow can trigger an OpenHands coding task based on a new note in Obsidian, search the web via SearXNG for documentation, and commit the fix to Gitea—all without a single external API call.

This is more than a collection of tools; it is a locally-hosted Operating System for the AI age.

# Project: dhoch3-ai-services

## Project Overview
Containerized AI/ML service orchestration system running multiple AI image generation, training, and inference applications on a single workstation with centralized model storage and SMB output management.

---

## System Specifications

### Hardware
- **GPU**: NVIDIA RTX Pro 6000 (9GB VRAM)
- **OS**: Ubuntu 24.04 LTS
- **Type**: Single workstation (local network deployment)

### Pre-installed Software
- Docker (with BuildKit)
- CUDA Toolkit
- nvtop
- Traefik (reverse proxy - already configured)

---

## Services Architecture

### Containerized Services

| Service | Docker Image | Build Strategy | Port | Subdomain | Purpose |
|---------|-------------|----------------|------|-----------|---------|
| **ComfyUI** | [YanWenKun/ComfyUI-Docker cu128-megapak-pt28](https://github.com/YanWenKun/ComfyUI-Docker/tree/main/cu128-megapak-pt28/) | Pre-built | 8188 | comfyui.design-hoch-drei.de | AI image generation (existing, fresh start) |
| **Fooocus** | [lllyasviel/Fooocus](https://github.com/lllyasviel/Fooocus) | **Local build** | 7860 | fooocus.design-hoch-drei.de | AI image generation |
| **Forge** | [lllyasviel/stable-diffusion-webui-forge](https://github.com/lllyasviel/stable-diffusion-webui-forge) | **Local build** | 7861 | forge.design-hoch-drei.de | Stable Diffusion WebUI |
| **InvokeAI** | [InvokeAI Docker](https://github.com/invoke-ai/InvokeAI/tree/main/docker) | Pre-built | 9090 | invokeai.design-hoch-drei.de | AI image generation |
| **FluxGym** | [cocktailpeanut/fluxgym](https://github.com/cocktailpeanut/fluxgym) | **Local build** | 3000 | fluxgym.design-hoch-drei.de | Flux LoRA training |
| **AI Toolkit** | [ostris/ai-toolkit](https://github.com/ostris/ai-toolkit) | **Local build** | 8080 | ai-toolkit.design-hoch-drei.de | AI training tools |
| **Dockge** | [louislam/dockge](https://github.com/louislam/dockge) | Pre-built | 5001 | dockge.design-hoch-drei.de | Container management UI |

#### Build Strategy Rationale

**Local Builds (Fooocus, Forge, FluxGym, AI Toolkit)**:
- Better integration with local model storage paths
- Optimized for RTX Pro 6000 and CUDA toolkit
- No cloud platform bloat (RunPod images designed for ephemeral instances)
- Full control over dependencies and versions
- Smaller, customized images
- Consistent base CUDA/PyTorch versions across services

**Pre-built Images (ComfyUI, InvokeAI, Dockge)**:
- Well-maintained official/community images
- Production-ready and regularly updated
- ComfyUI megapak includes extensive node ecosystem
- InvokeAI official Docker is stable and optimized
- Dockge is lightweight management tool (no customization needed)

### Native Installation
| Service | Port | Access | Purpose |
|---------|------|--------|---------|
| **Ollama** | 11434 | localhost (accessible to all containers) | LLM inference engine |

**Note**: LM Studio was initially considered but skipped in favor of Ollama. LM Studio is primarily a desktop application and containerization would be complex. Ollama provides better Docker integration and native Linux support for LLM inference.

---

## Storage Architecture

### Local Model Storage
- **Path**: `/vol/service/cw/storage-models/models`
- **Purpose**: Centralized model storage shared across all AI services
- **Mount**: Read-only access for containers, persistent outside Docker
- **Access**: All AI applications mount this directory

### SMB Output Storage
- **Server**: `//192.168.0.6/ki_Daten`
- **Protocol**: SMB3
- **User**: `d3kiserver`
- **Structure**: Each application has dedicated output folder
  - `/ComfyUI/`
  - `/Fooocus/`
  - `/Forge/`
  - `/InvokeAI/`
  - `/FluxGym/`
  - `/AIToolkit/`

### Container Persistent Storage
- **Purpose**: Application configs, databases, temporary files
- **Location**: Docker volumes (managed by Docker)
- **Scope**: Per-service isolation

---

## Network Architecture

### Domain Structure
- **Base Domain**: `design-hoch-drei.de`
- **Pattern**: `{service}.design-hoch-drei.de`
- **Scope**: Local network only (no public internet exposure)
- **Routing**: Traefik reverse proxy with automatic subdomain routing

### Service Discovery
- All containers on shared Docker network
- Ollama accessible via `host.docker.internal:11434` or host network mode
- Inter-service communication via service names

---

## Deployment Strategy

### Version Control
- **Repository**: GitHub-based
- **Structure**: Docker Compose configuration with version pinning
- **Updates**: Manual via `git pull` + `docker-compose pull` + `docker-compose up -d`
- **Secrets**: `.env` file (git-ignored) for credentials

### Configuration Management
- **docker-compose.yml**: Service definitions, networks, volumes
- **dockerfiles/**: Custom Dockerfiles for locally-built services
  - `fooocus/Dockerfile`
  - `forge/Dockerfile`
  - `fluxgym/Dockerfile`
  - `ai-toolkit/Dockerfile`
  - `lmstudio/Dockerfile`
- **.env.example**: Template for required environment variables
- **.env**: Actual credentials (git-ignored, manually created)
- **scripts/**: Setup and build automation
  - `build-images.sh`: Build all local Docker images
  - `setup.sh`: Initial system setup

### Required Environment Variables (in .env)
```
SMB_SERVER=192.168.0.6
SMB_SHARE=ki_Daten
SMB_USER=d3kiserver
SMB_PASSWORD=<actual_password>
MODELS_PATH=/vol/service/cw/storage-models/models
DOMAIN=design-hoch-drei.de
```

---

## GPU Access
- All AI services require GPU passthrough
- NVIDIA Container Toolkit for Docker GPU support
- Resource allocation: Shared GPU access (no hard limits initially)

---

## Management & Monitoring

### Container Management
- **Tool**: Dockge (lightweight, web-based)
- **Features**: Start/stop containers, view logs, update services
- **Access**: dockge.design-hoch-drei.de

### Monitoring
- nvtop for GPU monitoring (already installed)
- Docker logs via Dockge interface
- Traefik dashboard (if enabled)

---

## Setup Requirements

### Initial Setup Scripts Should Include:
1. **Build Phase** (`build-images.sh`):
   - Build Fooocus Docker image from source
   - Build Forge Docker image from source
   - Build FluxGym Docker image from source
   - Build AI Toolkit Docker image from source
   - Build LM Studio Docker image from source
   - Tag images with version numbers

2. **Setup Phase** (`setup.sh`):
   - Ollama native installation
   - SMB mount configuration (system-level or per-container)
   - Docker network creation
   - Volume initialization
   - `.env` file template generation
   - Traefik label configuration for services
   - Model directory permissions setup
   - First-time service startup

### Post-Setup Manual Tasks:
1. Populate `.env` with actual credentials
2. Configure Ollama models (user-defined later)
3. Verify Traefik routing
4. Test SMB connectivity
5. Download initial AI models to shared storage
6. Rebuild images when upstream repositories update

---

## Security Considerations
- Local network only (no public exposure)
- Credentials in `.env` file (never committed)
- SMB authentication required
- Container isolation via Docker networks

---

## Future Considerations
- Orchestration tools: Not needed for single-server setup
- Backup strategy: TBD
- Model versioning: TBD
- Resource limits: May add CPU/memory caps if needed
- SSL/HTTPS: Not required for local network (optional via Traefik + Let's Encrypt)

---

## Success Criteria
✅ All services accessible via subdomains
✅ Shared model storage working across all services
✅ SMB output folders created and writable
✅ GPU accessible to all AI services
✅ Ollama accessible from containers
✅ Easy container management via Dockge
✅ Version-controlled configuration in Git
✅ Reproducible setup via scripts
✅ Local Docker images build successfully
✅ Custom images optimized for local hardware

---

## Project Structure
```
dhoch3-ai-services/
├── docker-compose.yml           # Main orchestration file
├── .env.example                 # Environment template
├── .env                         # Actual credentials (git-ignored)
├── .gitignore                   # Ignore .env, logs, temp files
├── README.md                    # Setup and usage documentation
├── dockerfiles/                 # Custom Dockerfiles
│   ├── fooocus/
│   │   └── Dockerfile
│   ├── forge/
│   │   └── Dockerfile
│   ├── fluxgym/
│   │   └── Dockerfile
│   ├── ai-toolkit/
│   │   └── Dockerfile
│   └── lmstudio/
│       └── Dockerfile
└── scripts/                     # Automation scripts
    ├── build-images.sh          # Build all local images
    ├── setup.sh                 # Initial system setup
    └── update.sh                # Update and rebuild services
```
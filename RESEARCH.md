# Service Configuration Research

## Research Summary

This document contains findings from researching Docker deployment requirements for all services in the dhoch3-ai-services project.

---

## 1. Fooocus

**Repository:** https://github.com/lllyasviel/Fooocus

### Key Requirements
- **Base Image:** Python 3.10+ with CUDA support
- **Dependencies:** 
  - PyTorch (CUDA-enabled)
  - Gradio for web UI
  - requirements_versions.txt for exact versions
- **GPU:** NVIDIA GPU with CUDA support required
- **Port:** 7860 (Gradio default)
- **Model Storage:** Configurable model paths
- **Installation Method:** 
  - Native: conda/venv with requirements.txt
  - Docker: Custom build recommended

### Docker Configuration Notes
- Requires CUDA runtime base image (nvidia/cuda:12.1.0-runtime-ubuntu22.04 or similar)
- Volume mounts needed for:
  - Model storage: `/vol/service/cw/storage-models/models`
  - Output: SMB mount to `//192.168.0.6/ki_Daten/fooocus`
- GPU passthrough via `--gpus all`
- Environment variables for model paths

---

## 2. Stable Diffusion WebUI Forge

**Repository:** https://github.com/lllyasviel/stable-diffusion-webui-forge

### Key Requirements
- **Base Image:** Python 3.10+ with CUDA support
- **Dependencies:**
  - PyTorch with CUDA
  - Gradio 4.x for UI
  - Extensive ControlNet support
  - requirements_versions.txt for dependencies
- **GPU:** NVIDIA GPU required, supports SDXL models
- **Port:** 7861 (to avoid conflict with Fooocus)
- **Model Storage:** Multiple model types (checkpoints, LoRA, VAE, ControlNet)
- **Features:**
  - Based on Stable Diffusion WebUI
  - Enhanced performance optimizations
  - ControlNet integration

### Docker Configuration Notes
- Similar base to Fooocus (CUDA runtime)
- Multiple volume mounts for different model types
- Shared model storage with other SD-based services
- Launch arguments for optimization (--xformers, --api, etc.)

---

## 3. FluxGym

**Repository:** https://github.com/cocktailpeanut/fluxgym

### Key Requirements
- **Base Image:** Python 3.10+ with CUDA 12.1+
- **Dependencies:**
  - PyTorch Nightly (CUDA 12.1 or 12.8 for RTX 50-series)
  - Kohya sd-scripts (sd3 branch)
  - Gradio for UI
  - bitsandbytes for quantization
- **GPU:** NVIDIA GPU, supports 12GB/16GB/20GB VRAM
- **Port:** 3000
- **Special Requirements:**
  - Clones kohya-ss/sd-scripts as subdirectory
  - Requires PyTorch nightly build
  - Auto-downloads models on first use

### Docker Configuration Notes
- Two-stage build: kohya-scripts dependencies + fluxgym app
- CUDA 12.1+ base image required
- PyTorch nightly installation: `pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121`
- For RTX 50-series: CUDA 12.8 + updated bitsandbytes
- Folder structure:
  ```
  /fluxgym
    app.py
    requirements.txt
    /sd-scripts (git submodule)
    /env
  ```
- Docker Compose support available in repo

---

## 4. AI Toolkit (Ostris)

**Repository:** https://github.com/ostris/ai-toolkit

### Key Requirements
- **Base Image:** Python 3.10+ with CUDA support
- **Dependencies:**
  - PyTorch with CUDA
  - Training-specific libraries
  - Gradio UI (from FluxGym fork)
- **GPU:** NVIDIA GPU required
- **Port:** 8080
- **Purpose:** AI model training toolkit

### Docker Configuration Notes
- Similar requirements to FluxGym
- Focus on training workflows
- Needs persistent storage for training outputs
- May share dependencies with FluxGym

---

## 5. LM Studio

**Documentation:** https://lmstudio.ai/docs/developer/core/headless

### Key Requirements
- **Type:** LLM inference server
- **Headless Mode:** Supports GUI-less operation
- **Port:** 1234 (default API server)
- **Features:**
  - OpenAI-compatible API endpoints
  - Just-In-Time (JIT) model loading
  - Auto-start on machine login
  - Model management via CLI

### Docker Configuration Notes
- **Challenge:** LM Studio is primarily a desktop application
- **Headless Mode:**
  - Can run without GUI
  - Start server on login: `lms server start`
  - JIT loading: models load on-demand via API calls
- **API Endpoints:**
  - `/v1/models` - List models
  - `/v1/chat/completions` - Chat inference
  - `/v1/embeddings` - Embeddings
- **Docker Strategy:**
  - May need to extract server components
  - Alternative: Use llama.cpp or similar as backend
  - Consider using LM Studio CLI in container

---

## 6. ComfyUI

**Repository:** https://github.com/YanWenKun/ComfyUI-Docker (cu128-megapak-pt28)

### Key Requirements
- **Pre-built Image:** YanWenKun/comfyui-docker:cu128-megapak-pt28
- **Base:** CUDA 12.8, PyTorch 2.8
- **Port:** 8188
- **Features:**
  - Mega-pack includes many extensions
  - Node-based workflow UI
  - Extensive model support

### Docker Configuration Notes
- **Use pre-built image** (well-maintained)
- Volume mounts:
  - Models: `/vol/service/cw/storage-models/models`
  - Output: SMB mount
  - Custom nodes: persistent volume
- GPU passthrough required
- May need custom_nodes configuration

---

## 7. InvokeAI

**Official Docker:** https://github.com/invoke-ai/InvokeAI

### Key Requirements
- **Pre-built Image:** Official InvokeAI Docker image
- **Port:** 9090
- **Features:**
  - Production-ready official image
  - Web-based UI
  - Model management
  - Workflow support

### Docker Configuration Notes
- **Use official image** (recommended)
- Well-documented Docker deployment
- Volume mounts for models and outputs
- Environment variables for configuration

---

## 8. Ollama

**Type:** Native Installation (not Docker)

### Key Requirements
- **Installation:** Native Linux binary
- **Port:** 11434 (localhost only)
- **Purpose:** LLM inference engine
- **Access:** Available to all Docker containers via host network

### Configuration Notes
- Install via official script: `curl -fsSL https://ollama.com/install.sh | sh`
- Systemd service for auto-start
- Model storage: `~/.ollama/models`
- Accessible from containers via `host.docker.internal:11434` or host IP

---

## 9. Dockge

**Repository:** https://github.com/louislam/dockge

### Key Requirements
- **Pre-built Image:** Official Dockge image
- **Port:** 5001
- **Purpose:** Docker Compose management UI
- **Features:**
  - Manage multiple compose stacks
  - Web-based interface
  - Real-time logs

### Docker Configuration Notes
- **Use official image**
- Needs Docker socket mount: `/var/run/docker.sock`
- Volume for compose files
- Traefik labels for subdomain routing

---

## Common Docker Patterns

### Base Images
- **AI/ML Services:** `nvidia/cuda:12.1.0-runtime-ubuntu22.04` or `nvidia/cuda:12.8.0-runtime-ubuntu22.04`
- **Python Version:** 3.10 or 3.11
- **PyTorch:** CUDA-enabled builds

### GPU Access
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

### Volume Mounts
- **Models:** `/vol/service/cw/storage-models/models:/models`
- **Output:** SMB mounts per service
- **Persistent data:** Named volumes

### Environment Variables
- `NVIDIA_VISIBLE_DEVICES=all`
- `CUDA_VISIBLE_DEVICES=0`
- Model path configurations

---

## Next Steps

1. Create Dockerfiles for local builds (Fooocus, Forge, FluxGym, AI Toolkit)
2. Determine LM Studio Docker strategy (or alternative)
3. Create docker-compose.yml with all services
4. Create build and setup scripts
5. Configure Traefik labels for subdomain routing


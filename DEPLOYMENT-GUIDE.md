# dhoch3-ai-services Deployment Guide

## Overview

This guide covers deploying dhoch3-ai-services to the production server with proper storage integration and Traefik reverse proxy.

---

## Prerequisites

### Server Requirements
- Ubuntu 24.04 LTS
- NVIDIA RTX Pro 6000 GPU (48GB VRAM)
- Docker with NVIDIA Container Toolkit
- Traefik reverse proxy (already configured)
- File server mounted at `/vol/service/cw`

### Network Requirements
- Domain: `design-hoch-drei.de`
- Traefik network: `base`
- SSL certificates via Let's Encrypt

---

## Storage Structure

The file server at `/vol/service/cw` has this structure:

```
/vol/service/cw/
├── dhoch3-ai-services/      # This project (git repository)
├── storage/                 # Service-specific data
│   ├── ComfyUI/
│   ├── Fooocus/
│   ├── Forge/
│   ├── InvokeAI/
│   ├── FluxGym/
│   └── AIToolkit/
├── storage-models/          # Shared model storage (READ-ONLY)
│   └── models/
│       ├── checkpoints/
│       ├── loras/
│       ├── vae/
│       ├── controlnet/
│       └── ...
└── storage-user/            # User data
    ├── input/
    ├── output/
    │   ├── ComfyUI/
    │   ├── Fooocus/
    │   ├── Forge/
    │   ├── InvokeAI/
    │   ├── FluxGym/
    │   └── AIToolkit/
    └── workflows/
```

**See:** `STORAGE-STRUCTURE.md` for detailed information.

---

## Pre-Deployment: Existing ComfyUI

⚠️ **IMPORTANT:** If you have an existing ComfyUI installation running, you must stop it first to avoid port conflicts.

**See:** `MIGRATION-FROM-OLD-COMFYUI.md` for detailed migration instructions.

**Quick stop:**
```bash
cd /vol/service/cw/ComfyUI-Docker
docker compose down
```

---

## Deployment Steps

### 1. Clone Repository

```bash
cd /vol/service/cw
git clone https://github.com/benjamin-bertram/dhoch3-ai-services.git
cd dhoch3-ai-services
```

### 2. Setup Storage Directories

```bash
# Run the setup script to create all necessary directories
sudo ./scripts/setup-storage-directories.sh
```

This creates:
- Service data directories in `storage/`
- User output directories in `storage-user/output/`
- Input directories in `storage-user/input/`

### 3. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with production values
nano .env
```

**Required settings:**

```bash
# Domain Configuration
DOMAIN=design-hoch-drei.de

# Storage Paths
MODELS_PATH=/vol/service/cw/storage-models/models
STORAGE_PATH=/vol/service/cw/storage
USER_STORAGE_PATH=/vol/service/cw/storage-user

# SMB Configuration (for remote access)
SMB_SERVER=192.168.0.6
SMB_SHARE=ki_Daten
SMB_USER=d3kiserver
SMB_PASSWORD=your_password_here

# Traefik Configuration
TRAEFIK_NETWORK=base
CERT_RESOLVER=letsencryptresolver
TRAEFIK_MIDDLEWARE=default@file

# GPU Configuration
NVIDIA_VISIBLE_DEVICES=all
CUDA_VISIBLE_DEVICES=0
```

### 4. Verify Traefik Network

```bash
# Check if Traefik network exists
docker network ls | grep base

# If not found, create it (should already exist)
docker network create base
```

### 5. Build Custom Images

```bash
# Build all custom images
./scripts/build-images.sh

# Or build individually
docker compose build fooocus
docker compose build forge
docker compose build fluxgym
docker compose build ai-toolkit
```

### 6. Deploy Services

```bash
# Deploy all services
docker compose up -d

# Or deploy individually
docker compose up -d comfyui
docker compose up -d fooocus
docker compose up -d forge
docker compose up -d invokeai
docker compose up -d fluxgym
docker compose up -d ai-toolkit
docker compose up -d dockge
```

### 7. Verify Deployment

```bash
# Check running containers
docker ps

# Check logs
docker compose logs -f forge
docker compose logs -f fooocus

# Check Traefik routes (via Traefik dashboard)
# Look for: comfyui, fooocus, forge, invokeai, fluxgym, ai-toolkit, dockge
```

---

## Service URLs

All services are accessible via HTTPS:

| Service | URL | Purpose |
|---------|-----|---------|
| ComfyUI | https://comfyui.design-hoch-drei.de | Node-based image generation |
| Fooocus | https://fooocus.design-hoch-drei.de | Simple image generation |
| Forge | https://forge.design-hoch-drei.de | Stable Diffusion WebUI |
| InvokeAI | https://invokeai.design-hoch-drei.de | Professional image generation |
| FluxGym | https://fluxgym.design-hoch-drei.de | Flux LoRA training |
| AI Toolkit | https://ai-toolkit.design-hoch-drei.de | AI training tools |
| Dockge | https://dockge.design-hoch-drei.de | Container management |

---

## Model Management

### Shared Model Storage

All services share models from `/vol/service/cw/storage-models/models/`:

```bash
# Models are mounted READ-ONLY to prevent accidental deletion
# Download new models manually to the shared storage

# Example: Add a new checkpoint
cd /vol/service/cw/storage-models/models/checkpoints
wget https://example.com/model.safetensors

# Example: Add a new LoRA
cd /vol/service/cw/storage-models/models/loras
wget https://example.com/lora.safetensors
```

### Model Organization

```
storage-models/models/
├── checkpoints/         # Stable Diffusion checkpoints
│   └── SD1.5/          # Organized by version
├── loras/              # LoRA models
├── vae/                # VAE models
├── controlnet/         # ControlNet models
├── diffusion_models/   # Flux and other diffusion models
│   └── FLUX1/
├── text_encoders/      # CLIP, T5, etc.
│   └── t5/
├── clip/               # CLIP models
├── upscale_models/     # Upscalers (ESRGAN, etc.)
└── ...                 # Many more categories
```

---

## Maintenance

### Update Services

```bash
cd /vol/service/cw/dhoch3-ai-services

# Pull latest code
git pull

# Rebuild images
./scripts/build-images.sh

# Restart services
docker compose up -d
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f forge

# Last 100 lines
docker compose logs --tail=100 forge
```

### Restart Service

```bash
# Restart specific service
docker compose restart forge

# Restart all services
docker compose restart
```

### Clean Up

```bash
# Remove stopped containers
docker compose down

# Remove containers and volumes (CAUTION!)
docker compose down -v

# Clean up old images
docker image prune -a
```

---

## Troubleshooting

### Service Not Accessible

**Check:**
1. Container is running: `docker ps | grep forge`
2. Traefik labels: `docker inspect dhoch3-forge | grep -A 20 Labels`
3. Network connection: `docker inspect dhoch3-forge | grep -A 10 Networks`
4. DNS resolution: `nslookup forge.design-hoch-drei.de`

### GPU Not Detected

**Check:**
1. NVIDIA drivers: `nvidia-smi`
2. Docker runtime: `docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi`
3. Container GPU access: `docker exec dhoch3-forge nvidia-smi`

### Model Not Found

**Check:**
1. Model storage mounted: `docker exec dhoch3-forge ls -la /models`
2. Model exists: `ls -la /vol/service/cw/storage-models/models/checkpoints`
3. Permissions: `ls -la /vol/service/cw/storage-models/models`

### Out of Disk Space

**Check:**
1. Output directories: `du -sh /vol/service/cw/storage-user/output/*`
2. Docker volumes: `docker system df`
3. Clean old outputs: `rm -rf /vol/service/cw/storage-user/output/*/old_files`

---

## Security

### Authentication

- Dockge uses `admin-auth@file` middleware (HTTP Basic Auth)
- AI services use `default@file` middleware
- Configure additional authentication in Traefik if needed

### Network Isolation

- Services communicate via internal `ai-services` network
- Only Traefik network is exposed externally
- Models are mounted read-only

### Backups

**Important directories to backup:**
- `/vol/service/cw/storage/` - Service configurations
- `/vol/service/cw/storage-user/` - User data and outputs
- `/vol/service/cw/dhoch3-ai-services/.env` - Environment configuration

**Optional:**
- `/vol/service/cw/storage-models/models/` - Models (can be re-downloaded)

---

## References

- **STORAGE-STRUCTURE.md** - Detailed storage organization
- **TRAEFIK-INTEGRATION.md** - Traefik configuration guide
- **RTX-5090-SETUP.md** - RTX 5090 compatibility fixes
- **README.md** - Project overview


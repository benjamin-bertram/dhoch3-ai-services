# 🏗️ Architecture

This document explains how the server, network, storage, and containers are connected.

---

## Server Overview

The AI server is a single workstation at IP `192.168.0.10` running Ubuntu Linux. It has an NVIDIA RTX PRO 6000 Blackwell GPU with 96 GB of VRAM — enough to run any current AI model.

The server connects to a NAS (network storage) at `192.168.0.6` for user-facing files (images, datasets, workflows).

---

## Network Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Office Network (192.168.0.x)                                 │
│                                                               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │ User PCs     │    │ AI Server    │    │ NAS          │    │
│  │              │◄──►│ 192.168.0.10 │◄──►│ 192.168.0.6  │    │
│  │ Browsers     │    │ GPU + Docker │    │ SMB Share    │    │
│  └──────────────┘    └──────────────┘    └──────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

- **Users** access services via their web browser at `https://<service>.design-hoch-drei.de`
- **The AI server** runs all Docker containers and processes GPU workloads
- **The NAS** stores user files (outputs, inputs, datasets) and is mounted on the server at `/mnt/nas`

---

## Docker Container Structure

All AI services run as Docker containers, orchestrated by a single `docker-compose.yml` file.

```
docker-compose.yml
├── comfyui        (pre-built image: yanwk/comfyui-boot:cu128-megapak)
├── fooocus        (custom Dockerfile: dockerfiles/fooocus/)
├── forge          (custom Dockerfile: dockerfiles/forge/)
├── invokeai       (pre-built image: ghcr.io/invoke-ai/invokeai:latest)
├── ai-toolkit     (custom Dockerfile: dockerfiles/ai-toolkit/)
└── dockge         (pre-built image: louislam/dockge:latest)
```

**Pre-built images** are downloaded from Docker Hub / GitHub Container Registry. No building required.

**Custom Dockerfiles** are built locally because these services need special CUDA 12.8 support for the Blackwell GPU.

---

## Networking Inside Docker

Two Docker networks connect the containers:

| Network | Purpose |
|---------|---------|
| `base` | External network shared with Traefik — enables HTTPS routing |
| `ai-services` | Internal network for container-to-container communication |

**Traefik** (the reverse proxy) is not part of this project — it runs separately. It reads Docker labels on each container to know which subdomain routes where.

Example: The label `traefik.http.routers.comfyui.rule=Host('comfyui.design-hoch-drei.de')` tells Traefik to send traffic for `comfyui.design-hoch-drei.de` to the ComfyUI container on port 8188.

---

## Storage Architecture

Storage is split into two systems:

### 1. Local NVMe (Fast — for AI models)
- **Path on server:** `/vol/service/cw/storage-models/models/`
- **Mounted in containers as:** `/models` or `/shared-models` (read-only)
- Contains: checkpoints, LoRAs, VAEs, ControlNets, embeddings, etc.
- **Why local?** AI models are large (2–20 GB each). Loading from NVMe is instant; loading from NAS would be slow.

### 2. NAS / SMB Share (Reliable — for user files)
- **NAS path:** `\\192.168.0.6\ki_Daten\storage-user\`
- **Mounted on server at:** `/mnt/nas/storage-user/`
- **Mounted in containers as:** various paths per service (see below)

| Folder on NAS | What It Contains |
|----------------|------------------|
| `storage-user/output/ComfyUI/` | Generated images from ComfyUI |
| `storage-user/output/Fooocus/` | Generated images from Fooocus |
| `storage-user/output/Forge/` | Generated images from Forge |
| `storage-user/output/InvokeAI/` | Generated images from InvokeAI |
| `storage-user/output/AIToolkit/` | Training outputs from AI Toolkit |
| `storage-user/input/` | Input images (shared across services) |
| `storage-user/workflows/` | Saved workflows |
| `storage-user/datasets/` | Training datasets for AI Toolkit |

---

## Model Symlink Strategy

Fooocus and Forge use different internal names for model folders than ComfyUI's standard. Instead of duplicating models, the containers use **symlinks** (shortcuts) created at startup by their entrypoint scripts:

**Forge example:**
| Forge expects | Symlink points to |
|---------------|-------------------|
| `/app/models/Stable-diffusion` | `/shared-models/checkpoints` |
| `/app/models/Lora` | `/shared-models/loras` |
| `/app/models/VAE` | `/shared-models/vae` |

**Fooocus example:**
Fooocus symlinks `checkpoints`, `loras`, `vae`, etc. from `/shared-models/` into `/app/models/`, but leaves internal directories (like `prompt_expansion`) untouched so Fooocus can manage them itself.

---

## CUDA / GPU Compatibility

The RTX PRO 6000 Blackwell uses compute capability **sm_120**, which requires:
- **CUDA 12.8+** (older CUDA versions don't know about Blackwell)
- **PyTorch with cu128** (compiled for CUDA 12.8)

All custom Dockerfiles are built on `nvidia/cuda:12.8.1-devel-ubuntu22.04` and install PyTorch from the `cu128` index. SageAttention (a performance optimization for Forge) is compiled from source targeting `sm_120`.

---

## Environment Variables

The `.env` file on the server stores configuration that varies per deployment:

| Variable | Example | Purpose |
|----------|---------|---------|
| `MODELS_PATH` | `/vol/service/cw/storage-models/models` | Where AI models live on the host |
| `USER_STORAGE_PATH` | `/mnt/nas/storage-user` | Where user files live (NAS mount) |
| `DOMAIN` | `design-hoch-drei.de` | Base domain for Traefik routing |
| `NVIDIA_VISIBLE_DEVICES` | `all` | Which GPUs containers can see |
| `CUDA_VISIBLE_DEVICES` | `0` | Which GPU to use (we have one) |


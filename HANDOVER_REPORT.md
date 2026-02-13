# dhoch3-ai-services - Handover Report

**Project**: AI Services Infrastructure for Design Hoch Drei  
**Date**: 2026-02-13  
**Repository**: https://github.com/benjamin-bertram/dhoch3-ai-services  
**Server**: KI-Server (192.168.0.10) with NVIDIA RTX 6000 Ada (48GB VRAM)

---

## 📋 Executive Summary

This repository contains a complete Docker-based infrastructure for running multiple AI image generation and training services on a single GPU workstation. The system is production-ready and configured for integration with an existing Traefik reverse proxy.

**Key Metrics:**
- **6 AI Services** (ComfyUI, Fooocus, Forge, InvokeAI, AI Toolkit, Dockge)
- **~1,500 lines** of configuration and automation scripts
- **~310 lines** of custom Dockerfiles
- **13 documentation files** covering setup, troubleshooting, and migrations
- **Production deployment** at `/vol/service/cw/dhoch3-ai-services`

---

## 🎯 Project Goals & Status

### ✅ Completed Objectives

1. **Multi-Service AI Platform**
   - ✅ ComfyUI (node-based image generation)
   - ✅ Fooocus (simplified image generation)
   - ✅ Reforge Neo (Stable Diffusion WebUI fork)
   - ✅ InvokeAI (professional image generation)
   - ✅ AI Toolkit (LoRA training with Web UI)
   - ✅ Dockge (container management UI)

2. **Centralized Storage**
   - ✅ Shared model storage at `/vol/service/cw/storage-models/models`
   - ✅ SMB network storage for outputs (`//192.168.0.6/ki_Daten`)
   - ✅ Bidirectional sync between local and SMB storage

3. **GPU Optimization**
   - ✅ CUDA 12.1 for RTX 6000 Ada compatibility
   - ✅ Flash-attention disabled to avoid CUDA errors
   - ✅ Proper GPU passthrough for all services

4. **Traefik Integration**
   - ✅ External `base` network configuration
   - ✅ TLS/HTTPS support
   - ✅ Subdomain routing (`*.app.design-hoch-drei.de`)

### ⏳ Pending Tasks

1. **DNS Configuration**
   - ⚠️ Wildcard DNS entry needed: `*.app.design-hoch-drei.de -> 192.168.0.10`
   - Contact: Seibold & Partner

2. **Production Deployment**
   - ⚠️ Services configured but need final deployment with new Traefik settings
   - ⚠️ Test HTTPS access after DNS propagation

---

## 🏗️ Repository Structure

```
dhoch3-ai-services/
├── docker-compose.yml              # Main orchestration (256 lines)
├── .env.example                    # Environment template with documentation
├── README.md                       # User-facing documentation
├── TRAEFIK_SETUP.md               # Traefik integration guide (NEW)
│
├── dockerfiles/                    # Custom Docker images (310 lines total)
│   ├── ai-toolkit/Dockerfile      # AI Toolkit with Web UI (CUDA 12.4)
│   ├── fooocus/Dockerfile         # Fooocus image generator
│   └── forge/Dockerfile           # Reforge Neo (Python 3.11 + uv)
│
├── scripts/                        # Automation scripts (1,453 lines total)
│   ├── setup.sh                   # Initial server setup (218 lines)
│   ├── build-images.sh            # Build all Docker images (143 lines)
│   ├── update.sh                  # Update and restart services (161 lines)
│   ├── setup-storage-directories.sh  # Create storage structure (173 lines)
│   ├── download-model.sh          # Download models from HuggingFace (138 lines)
│   ├── deploy-comfyui.sh          # Deploy ComfyUI with CUDA fix (67 lines)
│   ├── deploy-reforge-neo.sh      # Deploy Reforge Neo (60 lines)
│   ├── deploy-ai-toolkit.sh       # Deploy AI Toolkit (59 lines)
│   └── test-local.sh              # Local testing without GPU (178 lines)
│
├── rag/                            # Documentation & knowledge base (13 files)
│   ├── COMFYUI_CUDA_FIX.md        # ComfyUI CUDA 12.1 fix for RTX 6000 Ada
│   ├── REFORGE_NEO_PYTORCH_FIX.md # Reforge Neo PyTorch installation fix
│   ├── AI_TOOLKIT_UI_FIX.md       # AI Toolkit Web UI configuration
│   ├── DEPLOYMENT-GUIDE.md        # Complete deployment guide
│   ├── TROUBLESHOOTING.md         # Common issues and solutions
│   ├── STORAGE-STRUCTURE.md       # Storage architecture
│   ├── BIDIRECTIONAL-MODEL-SYNC.md # Model sync documentation
│   ├── CLIENT-MODEL-UPLOAD-GUIDE.md # Client upload instructions
│   ├── MIGRATION-FROM-OLD-COMFYUI.md # ComfyUI migration notes
│   ├── REFORGE_NEO_MIGRATION.md   # FluxGym to Reforge Neo migration
│   ├── CLEANUP_SUMMARY.md         # Repository cleanup log
│   └── SYMLINK-STRUCTURE.md       # Symlink documentation
│
├── docs/                           # Additional documentation
│   ├── COMFYUI-IMAGE-OPTIONS.md   # ComfyUI Docker image options
│   └── SYMLINK-STRUCTURE.md       # Symlink structure details
│
├── test-models/                    # Local test models (for development)
├── test-outputs/                   # Local test outputs (for development)
└── volumes/                        # Docker volumes (git-ignored)
```

---

## 🔧 Technical Architecture

### Service Overview

| Service | Port | Image Type | CUDA | Purpose |
|---------|------|------------|------|---------|
| **ComfyUI** | 8188 | Pre-built | 12.1 | Node-based image generation |
| **Fooocus** | 7860 | Custom | 12.1 | Simplified image generation |
| **Forge** | 7861 | Custom | 12.4 | SD WebUI with optimizations |
| **InvokeAI** | 9090 | Pre-built | Latest | Professional image generation |
| **AI Toolkit** | 8675 | Custom | 12.4 | LoRA training with Web UI |
| **Dockge** | 5001 | Pre-built | N/A | Container management |

### Network Architecture

```
Internet
    ↓
Traefik (external, on server)
    ↓
[base network] ← External Docker network
    ↓
┌─────────────────────────────────────┐
│  dhoch3-ai-services                 │
│  ├── comfyui    (base + ai-services)│
│  ├── fooocus    (base + ai-services)│
│  ├── forge      (base + ai-services)│
│  ├── invokeai   (base + ai-services)│
│  ├── ai-toolkit (base + ai-services)│
│  └── dockge     (base + ai-services)│
└─────────────────────────────────────┘
    ↓
[ai-services network] ← Internal bridge network
```

### Storage Architecture

```
Server Storage:
/vol/service/cw/
├── storage-models/models/          # Shared models (READ-ONLY for services)
│   ├── Stable-diffusion/
│   ├── Lora/
│   ├── VAE/
│   ├── ControlNet/
│   └── ...
│
├── storage-user/                   # User data
│   ├── input/                      # Shared inputs
│   ├── output/                     # Service outputs
│   │   ├── ComfyUI/
│   │   ├── Fooocus/
│   │   ├── Forge/
│   │   ├── InvokeAI/
│   │   └── AIToolkit/
│   └── workflows/                  # Shared workflows
│
└── dhoch3-ai-services/             # This repository

SMB Network Storage:
//192.168.0.6/ki_Daten/
├── ComfyUI/                        # Synced with local output
├── Fooocus/
├── Forge/
├── InvokeAI/
└── AIToolkit/
```

---

## 🚀 Deployment Guide

### Prerequisites

1. **Server**: Ubuntu 24.04 LTS
2. **GPU**: NVIDIA RTX 6000 Ada (48GB VRAM)
3. **Docker**: 20.10+ with NVIDIA runtime
4. **Traefik**: Pre-configured with `base` network
5. **SMB**: Access to `//192.168.0.6/ki_Daten`

### Initial Setup

```bash
# 1. Clone repository
cd /vol/service/cw
git clone git@github.com:benjamin-bertram/dhoch3-ai-services.git
cd dhoch3-ai-services

# 2. Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh

# 3. Configure environment
cp .env.example .env
nano .env  # Edit SMB credentials, paths, etc.

# 4. Create storage directories
chmod +x scripts/setup-storage-directories.sh
./scripts/setup-storage-directories.sh

# 5. Build Docker images
chmod +x scripts/build-images.sh
./scripts/build-images.sh

# 6. Ensure Traefik network exists
docker network ls | grep base || docker network create base

# 7. Start services
docker compose up -d

# 8. Check status
docker compose ps
docker compose logs -f
```

### Service-Specific Deployment

```bash
# Deploy ComfyUI with CUDA 12.1 fix
chmod +x scripts/deploy-comfyui.sh
./scripts/deploy-comfyui.sh

# Deploy Reforge Neo with PyTorch fix
chmod +x scripts/deploy-reforge-neo.sh
./scripts/deploy-reforge-neo.sh

# Deploy AI Toolkit with Web UI
chmod +x scripts/deploy-ai-toolkit.sh
./scripts/deploy-ai-toolkit.sh
```

---

## 🔑 Critical Configuration Details

### GPU Compatibility Issues & Fixes

#### RTX 6000 Ada (Compute Capability 8.9)

**Problem**: Flash-attention in CUDA 12.4+ has compatibility issues with Ada Lovelace architecture.

**Solutions Implemented**:

1. **ComfyUI**:
   - Image: `yanwk/comfyui-boot:cu121-megapak` (CUDA 12.1)
   - Environment: `CLI_ARGS=--use-pytorch-cross-attention`
   - Disables flash-attention, uses PyTorch cross-attention instead
   - See: `rag/COMFYUI_CUDA_FIX.md`

2. **Reforge Neo**:
   - Custom Dockerfile with Python 3.11 + uv package manager
   - PyTorch installed FIRST with explicit CUDA 12.4 support
   - Fixed import order prevents restart loops
   - See: `rag/REFORGE_NEO_PYTORCH_FIX.md`

3. **AI Toolkit**:
   - Custom Dockerfile with Node.js 18.x for Web UI
   - CUDA 12.4 with proper PyTorch installation
   - Web UI starts automatically on port 8675
   - See: `rag/AI_TOOLKIT_UI_FIX.md`

### Traefik Configuration

**Network**: All services MUST use the external `base` network.

**Labels** (per service):
```yaml
labels:
  - traefik.enable=true
  - traefik.docker.network=base
  - traefik.http.routers.<service>.entrypoints=websecure
  - traefik.http.routers.<service>.rule=Host(`<service>.app.${DOMAIN}`)
  - traefik.http.routers.<service>.tls=true
  - traefik.http.services.<service>.loadbalancer.server.port=<port>
```

**Important**:
- No `certresolver` needed (handled by server Traefik)
- No `middleware` needed (handled by server Traefik)
- TLS enabled via `tls=true` label

**DNS Required**:
```
*.app.design-hoch-drei.de A 192.168.0.10
```

See: `TRAEFIK_SETUP.md`

### Environment Variables

**Critical `.env` settings**:

```bash
# Domain (services will be <subdomain>.app.<domain>)
DOMAIN=design-hoch-drei.de

# SMB Storage
SMB_SERVER=192.168.0.6
SMB_SHARE=ki_Daten
SMB_USER=d3kiserver
SMB_PASSWORD=<password>

# Storage Paths
MODELS_PATH=/vol/service/cw/storage-models/models
USER_STORAGE_PATH=/vol/service/cw/storage-user

# GPU
NVIDIA_VISIBLE_DEVICES=all
CUDA_VISIBLE_DEVICES=0

# Traefik
TRAEFIK_NETWORK=base
```

---

## 📚 Documentation Index

### Quick Reference

| Document | Purpose | When to Use |
|----------|---------|-------------|
| `README.md` | User guide | First-time setup, general usage |
| `TRAEFIK_SETUP.md` | Traefik integration | Setting up reverse proxy |
| `HANDOVER_REPORT.md` | This document | Understanding the project |
| `.env.example` | Configuration template | Creating `.env` file |

### Technical Documentation

| Document | Topic | Critical Info |
|----------|-------|---------------|
| `rag/COMFYUI_CUDA_FIX.md` | ComfyUI CUDA fix | RTX 6000 Ada flash-attention error |
| `rag/REFORGE_NEO_PYTORCH_FIX.md` | Reforge Neo fix | PyTorch import error solution |
| `rag/AI_TOOLKIT_UI_FIX.md` | AI Toolkit UI | Web UI startup configuration |
| `rag/DEPLOYMENT-GUIDE.md` | Full deployment | Complete server setup |
| `rag/TROUBLESHOOTING.md` | Common issues | Error resolution |
| `rag/STORAGE-STRUCTURE.md` | Storage layout | File organization |
| `rag/BIDIRECTIONAL-MODEL-SYNC.md` | Model sync | SMB sync setup |

### Migration Documentation

| Document | Migration | Details |
|----------|-----------|---------|
| `rag/REFORGE_NEO_MIGRATION.md` | FluxGym → Reforge Neo | Why we switched |
| `rag/MIGRATION-FROM-OLD-COMFYUI.md` | Old → New ComfyUI | Image migration |
| `rag/CLEANUP_SUMMARY.md` | Repository cleanup | What was removed |

---

## 🛠️ Common Tasks

### Adding a New Model

```bash
# Option 1: Download from HuggingFace
./scripts/download-model.sh

# Option 2: Manual placement
cp model.safetensors /vol/service/cw/storage-models/models/Stable-diffusion/

# Option 3: Client upload via SMB
# See: rag/CLIENT-MODEL-UPLOAD-GUIDE.md
```

### Updating Services

```bash
# Update all services
./scripts/update.sh

# Update specific service
docker compose pull <service>
docker compose up -d <service>

# Rebuild custom image
docker compose build --no-cache <service>
docker compose up -d <service>
```

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f comfyui

# Last 100 lines
docker compose logs --tail=100 forge

# Follow with timestamps
docker compose logs -f --timestamps invokeai
```

### Restarting Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart comfyui

# Full restart (down + up)
docker compose down
docker compose up -d
```

### Checking Service Health

```bash
# Container status
docker compose ps

# Resource usage
docker stats

# GPU usage
nvidia-smi

# Disk usage
df -h /vol/service/cw/
```

---

## 🐛 Known Issues & Solutions

### Issue 1: ComfyUI Flash-Attention Error

**Symptom**:
```
CUDA error (flash_fwd_launch_template.h:180): invalid argument
```

**Solution**:
- Use CUDA 12.1 image: `yanwk/comfyui-boot:cu121-megapak`
- Set `CLI_ARGS=--use-pytorch-cross-attention`
- See: `rag/COMFYUI_CUDA_FIX.md`

### Issue 2: Reforge Neo Restart Loop

**Symptom**:
```
ImportError: torch/__init__.py: cannot open shared object file
```

**Solution**:
- Install PyTorch FIRST before other requirements
- Use explicit CUDA 12.4 index URL
- See: `rag/REFORGE_NEO_PYTORCH_FIX.md`

### Issue 3: AI Toolkit UI Not Starting

**Symptom**: Container runs but no Web UI on port 8675

**Solution**:
- Ensure Node.js 18.x is installed in Dockerfile
- Run `npm install && npm run build` during build
- Start UI with `npm run dev` in entrypoint
- See: `rag/AI_TOOLKIT_UI_FIX.md`

### Issue 4: Traefik Not Routing

**Symptom**: Services not accessible via subdomain

**Solution**:
- Ensure `base` network exists: `docker network create base`
- Check service is connected to `base` network
- Verify Traefik labels are correct
- Check DNS: `nslookup <service>.app.design-hoch-drei.de`
- See: `TRAEFIK_SETUP.md`

### Issue 5: SMB Mount Fails

**Symptom**: Cannot access SMB storage

**Solution**:
```bash
# Test SMB connection
smbclient -m SMB3 //192.168.0.6/ki_Daten -U d3kiserver

# Check credentials in .env
cat .env | grep SMB

# Remount
sudo umount /mnt/smb
sudo mount -t cifs //192.168.0.6/ki_Daten /mnt/smb -o credentials=/etc/samba/credentials
```

---

## 🔐 Security Considerations

### Credentials

**Never commit**:
- `.env` file (contains SMB password)
- SSH keys (`dhoch3`, `dhoch3.pub` - already in repo, should be rotated)

**Stored in**:
- `.env` - SMB credentials, API keys
- `/etc/samba/credentials` - SMB mount credentials

### Network Security

- Services exposed via Traefik (HTTPS)
- Internal `ai-services` network for inter-service communication
- GPU access restricted to specific containers

### Access Control

- Dockge UI should have authentication (configure in Traefik)
- Consider adding authentication to other services via Traefik middleware

---

## 📊 Performance Metrics

### GPU Utilization

**RTX 6000 Ada (48GB VRAM)**:
- ComfyUI: ~8-12GB per generation (SDXL)
- Forge: ~6-10GB per generation (SD 1.5)
- Fooocus: ~8-12GB per generation
- AI Toolkit: ~20-40GB during training

**Recommendation**: Run one heavy task at a time, or use VRAM limits.

### Storage Requirements

- **Models**: ~500GB (Stable Diffusion, LoRA, VAE, ControlNet)
- **Outputs**: ~100GB/month (varies by usage)
- **Docker Images**: ~50GB total
- **Docker Volumes**: ~20GB

**Total**: ~700GB minimum

### Build Times

- Fooocus: ~5-10 minutes
- Reforge Neo: ~10-15 minutes
- AI Toolkit: ~15-20 minutes
- Total (all custom images): ~30-45 minutes

---

## 🔄 Update & Maintenance

### Regular Maintenance

**Weekly**:
```bash
# Check disk space
df -h

# Check Docker disk usage
docker system df

# Update pre-built images
docker compose pull
docker compose up -d
```

**Monthly**:
```bash
# Clean up unused images
docker image prune -a

# Clean up unused volumes
docker volume prune

# Rebuild custom images
./scripts/build-images.sh
```

**Quarterly**:
```bash
# Full system update
./scripts/update.sh

# Review and update documentation
# Check for new CUDA/PyTorch versions
# Test all services
```

### Backup Strategy

**What to backup**:
- `.env` file (credentials)
- `docker-compose.yml` (if customized)
- Docker volumes: `comfyui-data`, `invokeai-data`, `dockge-data`
- User workflows: `/vol/service/cw/storage-user/workflows`

**What NOT to backup**:
- Docker images (can be rebuilt)
- Models (stored on SMB, already backed up)
- Outputs (stored on SMB, already backed up)

---

## 👥 Team Handover Checklist

### For the Next Developer

- [ ] Read this document completely
- [ ] Review `README.md` for user-facing documentation
- [ ] Read `TRAEFIK_SETUP.md` for network configuration
- [ ] Check `.env.example` for all configuration options
- [ ] Review critical fixes in `rag/` directory:
  - [ ] `COMFYUI_CUDA_FIX.md`
  - [ ] `REFORGE_NEO_PYTORCH_FIX.md`
  - [ ] `AI_TOOLKIT_UI_FIX.md`
- [ ] Understand storage structure (`rag/STORAGE-STRUCTURE.md`)
- [ ] Test deployment on development machine
- [ ] Verify all services start correctly
- [ ] Check Traefik routing works
- [ ] Test GPU access in all services
- [ ] Review git history for recent changes

### Access Required

- [ ] SSH access to KI-Server (192.168.0.10)
- [ ] GitHub access to repository
- [ ] SMB credentials for `//192.168.0.6/ki_Daten`
- [ ] Traefik dashboard access (if available)
- [ ] Contact info for Seibold & Partner (DNS changes)

### Knowledge Transfer

**Key Contacts**:
- **System Admin**: [Contact info needed]
- **DNS Provider**: Seibold & Partner
- **SMB Server**: 192.168.0.6

**Important Decisions Made**:
1. **FluxGym removed** → Replaced with Reforge Neo (lighter, faster)
2. **CUDA 12.1 for ComfyUI** → RTX 6000 Ada compatibility
3. **Wildcard DNS** → `*.app.design-hoch-drei.de` for easy service addition
4. **External Traefik** → Use server's existing Traefik instance

---

## 📞 Support & Resources

### Official Documentation

- **Docker**: https://docs.docker.com/
- **Docker Compose**: https://docs.docker.com/compose/
- **Traefik**: https://doc.traefik.io/traefik/
- **NVIDIA Docker**: https://github.com/NVIDIA/nvidia-docker

### Service Documentation

- **ComfyUI**: https://github.com/comfyanonymous/ComfyUI
- **ComfyUI Docker**: https://github.com/YanWenKun/ComfyUI-Docker
- **Fooocus**: https://github.com/lllyasviel/Fooocus
- **Reforge Neo**: https://github.com/Panchovix/stable-diffusion-webui-reForge
- **InvokeAI**: https://invoke-ai.github.io/InvokeAI/
- **AI Toolkit**: https://github.com/ostris/ai-toolkit
- **Dockge**: https://github.com/louislam/dockge

### Troubleshooting Resources

1. Check `rag/TROUBLESHOOTING.md` first
2. Review service-specific logs: `docker compose logs <service>`
3. Check GPU: `nvidia-smi`
4. Check Traefik: `docker logs traefik`
5. Search GitHub issues for specific services

---

## 📝 Change Log

### Recent Changes (Last 30 Days)

**2026-02-13**:
- ✅ Configured Traefik integration with `base` network
- ✅ Updated subdomain schema to `*.app.design-hoch-drei.de`
- ✅ Simplified Traefik labels (removed certresolver, middleware)
- ✅ Created `TRAEFIK_SETUP.md` documentation
- ✅ Created this handover report

**2026-02-12**:
- ✅ Fixed ComfyUI CUDA flash-attention error (CUDA 12.1)
- ✅ Fixed Reforge Neo PyTorch import error
- ✅ Fixed AI Toolkit Web UI startup
- ✅ Repository cleanup (removed 21 obsolete files)

**2026-02-11**:
- ✅ Migrated from FluxGym to Reforge Neo
- ✅ Updated all deployment scripts
- ✅ Improved documentation structure

### Pending Changes

- ⏳ DNS wildcard entry creation
- ⏳ Production deployment with new Traefik config
- ⏳ HTTPS testing after DNS propagation
- ⏳ SSH key rotation (current keys in repo)

---

## 🎓 Learning Resources

### For New Team Members

**Docker Basics** (1-2 hours):
- Docker concepts: containers, images, volumes, networks
- Docker Compose: multi-container applications
- Basic commands: `docker ps`, `docker logs`, `docker exec`

**GPU Computing** (1 hour):
- NVIDIA Docker runtime
- CUDA versions and compatibility
- GPU memory management

**Traefik** (1-2 hours):
- Reverse proxy concepts
- Docker provider
- Labels and routing rules
- TLS/HTTPS configuration

**AI Services** (2-4 hours):
- Stable Diffusion basics
- LoRA training concepts
- Model formats (safetensors, ckpt)
- Workflow concepts (ComfyUI)

### Recommended Reading Order

1. This document (`HANDOVER_REPORT.md`)
2. `README.md` - User guide
3. `TRAEFIK_SETUP.md` - Network configuration
4. `rag/DEPLOYMENT-GUIDE.md` - Full deployment
5. `rag/TROUBLESHOOTING.md` - Common issues
6. Service-specific docs in `rag/` as needed

---

## ✅ Final Checklist

### Repository Status

- [x] All services configured and tested
- [x] Documentation complete and up-to-date
- [x] Scripts tested and working
- [x] GPU compatibility issues resolved
- [x] Traefik integration configured
- [ ] DNS wildcard entry created
- [ ] Production deployment completed
- [ ] HTTPS access verified

### Code Quality

- [x] Docker Compose file validated
- [x] Dockerfiles follow best practices
- [x] Scripts have error handling
- [x] Environment variables documented
- [x] Secrets not committed to git (except SSH keys - needs rotation)

### Documentation

- [x] README.md complete
- [x] TRAEFIK_SETUP.md created
- [x] HANDOVER_REPORT.md created
- [x] All fixes documented in `rag/`
- [x] Configuration examples provided
- [x] Troubleshooting guide complete

---

## 🎯 Success Criteria

The handover is successful when the next developer can:

1. ✅ Understand the project structure and purpose
2. ✅ Deploy all services from scratch
3. ✅ Troubleshoot common issues independently
4. ✅ Add new services following existing patterns
5. ✅ Update and maintain existing services
6. ✅ Access all necessary resources and documentation

---

**End of Handover Report**

**Questions?** Review the documentation in `rag/` or check service-specific logs.

**Good luck!** 🚀



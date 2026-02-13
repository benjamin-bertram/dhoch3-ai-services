# 📦 Handover Documentation - dhoch3-ai-services

**Welcome!** This directory contains comprehensive handover documentation for the dhoch3-ai-services project.

---

## 📚 Documentation Overview

### 🎯 Start Here

**New to the project?** Read these documents in order:

1. **[EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)** (311 lines)
   - Quick overview of the project
   - What's included and what's pending
   - Key decisions and metrics
   - **Read time**: 10-15 minutes

2. **[HANDOVER_REPORT.md](HANDOVER_REPORT.md)** (804 lines)
   - Complete technical documentation
   - Repository structure and architecture
   - Deployment guide and common tasks
   - Known issues and solutions
   - **Read time**: 45-60 minutes

3. **[TRAEFIK_SETUP.md](TRAEFIK_SETUP.md)** (211 lines)
   - Traefik reverse proxy integration
   - Network configuration details
   - DNS setup requirements
   - **Read time**: 15-20 minutes

### 📖 Additional Documentation

- **[README.md](README.md)** - User-facing documentation
- **[.env.example](.env.example)** - Configuration template with comments
- **[rag/](rag/)** - Technical knowledge base (13 documents)

---

## 🚀 Quick Start for New Developers

### 1. Read Documentation (1-2 hours)

```bash
# Read in this order:
1. EXECUTIVE_SUMMARY.md      # 15 min - Project overview
2. HANDOVER_REPORT.md         # 60 min - Complete technical details
3. TRAEFIK_SETUP.md           # 20 min - Network configuration
4. README.md                  # 15 min - User guide
```

### 2. Get Access

- [ ] SSH access to KI-Server (192.168.0.10)
- [ ] GitHub repository access
- [ ] SMB credentials for `//192.168.0.6/ki_Daten`
- [ ] Contact info for Seibold & Partner (DNS)

### 3. Understand the Architecture

**Services**: 6 AI services (ComfyUI, Fooocus, Forge, InvokeAI, AI Toolkit, Dockge)  
**GPU**: NVIDIA RTX 6000 Ada (48GB VRAM)  
**Storage**: Centralized models + SMB network storage  
**Network**: Traefik reverse proxy with `base` network

See the architecture diagram in `HANDOVER_REPORT.md`.

### 4. Review Critical Fixes

**Must read** (in `rag/` directory):
- `COMFYUI_CUDA_FIX.md` - ComfyUI flash-attention error fix
- `REFORGE_NEO_PYTORCH_FIX.md` - Reforge Neo PyTorch import fix
- `AI_TOOLKIT_UI_FIX.md` - AI Toolkit Web UI startup fix

### 5. Test Deployment

```bash
# On development machine (optional)
./scripts/test-local.sh

# On server
cd /vol/service/cw/dhoch3-ai-services
git pull
docker compose up -d
docker compose ps
docker compose logs -f
```

---

## 📊 Project Status

### ✅ Completed (85%)

- [x] All 6 services configured and tested
- [x] GPU compatibility issues resolved
- [x] Traefik integration configured
- [x] Documentation complete (1,326 lines)
- [x] Automation scripts working

### ⏳ Pending (15%)

- [ ] DNS wildcard entry: `*.app.design-hoch-drei.de -> 192.168.0.10`
- [ ] Production deployment with new Traefik config
- [ ] HTTPS access verification
- [ ] SSH key rotation (keys currently in repo)

---

## 🔑 Key Information

### Server Details

- **IP**: 192.168.0.10
- **GPU**: NVIDIA RTX 6000 Ada (48GB VRAM)
- **OS**: Ubuntu 24.04 LTS
- **Location**: `/vol/service/cw/dhoch3-ai-services`

### Service URLs (after DNS setup)

- ComfyUI: https://comfyui.app.design-hoch-drei.de
- Fooocus: https://fooocus.app.design-hoch-drei.de
- Forge: https://forge.app.design-hoch-drei.de
- InvokeAI: https://invokeai.app.design-hoch-drei.de
- AI Toolkit: https://ai-toolkit.app.design-hoch-drei.de
- Dockge: https://dockge.app.design-hoch-drei.de

### Critical Configuration

**GPU Fixes**:
- ComfyUI: CUDA 12.1 + `--use-pytorch-cross-attention`
- Reforge Neo: PyTorch installed FIRST with CUDA 12.4
- AI Toolkit: Node.js 18.x + proper build step

**Network**:
- External network: `base` (shared with Traefik)
- Internal network: `ai-services` (bridge)
- TLS enabled via `traefik.http.routers.<service>.tls=true`

**Storage**:
- Models: `/vol/service/cw/storage-models/models` (READ-ONLY)
- User data: `/vol/service/cw/storage-user`
- SMB: `//192.168.0.6/ki_Daten`

---

## 🛠️ Common Tasks

### View Logs

```bash
docker compose logs -f <service>
```

### Restart Service

```bash
docker compose restart <service>
```

### Update Services

```bash
./scripts/update.sh
```

### Check GPU

```bash
nvidia-smi
```

### Deploy Specific Service

```bash
./scripts/deploy-comfyui.sh
./scripts/deploy-reforge-neo.sh
./scripts/deploy-ai-toolkit.sh
```

---

## 🐛 Troubleshooting

**Issue?** Check these in order:

1. `rag/TROUBLESHOOTING.md` - Common issues
2. Service logs: `docker compose logs <service>`
3. GPU status: `nvidia-smi`
4. Traefik logs: `docker logs traefik`
5. Service-specific fix docs in `rag/`

---

## 📞 Support

**Documentation**: See `HANDOVER_REPORT.md` for complete details  
**Technical Docs**: Check `rag/` directory  
**Issues**: Review `rag/TROUBLESHOOTING.md`

---

## ✅ Handover Checklist

### For the Next Developer

- [ ] Read `EXECUTIVE_SUMMARY.md`
- [ ] Read `HANDOVER_REPORT.md`
- [ ] Read `TRAEFIK_SETUP.md`
- [ ] Review `.env.example`
- [ ] Check critical fixes in `rag/`
- [ ] Understand storage structure
- [ ] Test deployment
- [ ] Verify all services start
- [ ] Check Traefik routing
- [ ] Test GPU access
- [ ] Review git history

---

## 📈 Documentation Metrics

- **Total Documentation**: 1,326 lines (3 main documents)
- **Technical Docs**: 13 files in `rag/` directory
- **Scripts**: 1,453 lines of automation
- **Docker Config**: 256 lines (docker-compose.yml)
- **Custom Dockerfiles**: 310 lines

**Total Project**: ~3,500+ lines of code and documentation

---

## 🎯 Next Steps

1. **Read documentation** (1-2 hours)
2. **Get access** to server and credentials
3. **Contact Seibold & Partner** for DNS wildcard entry
4. **Deploy to production** after DNS propagation
5. **Verify HTTPS access** to all services

---

**Questions?** Review the documentation or check service logs.

**Good luck with the project!** 🚀



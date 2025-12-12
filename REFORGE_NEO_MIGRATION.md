# Reforge Neo Migration Guide

## Overview

We've replaced the original Stable Diffusion WebUI Forge with **Reforge Neo** (sd-webui-forge-classic neo branch) due to persistent issues with the original Forge implementation.

## Why Reforge Neo?

### Problems with Original Forge:
- ❌ Continuous crashes with `libcusparseLt.so.0` errors
- ❌ Incompatibility issues with RTX 5090
- ❌ PyTorch nightly build complications
- ❌ xformers conflicts

### Benefits of Reforge Neo:
- ✅ **Python 3.11** - Specific version optimized for stability
- ✅ **uv Package Manager** - 10-100x faster than pip
- ✅ **SageAttention 2** - Better performance than xformers/FlashAttention
- ✅ **Lightweight** - Removed bloat, optimized codebase
- ✅ **Better RTX 5090 Support** - Latest PyTorch (2.9.1+cu130)
- ✅ **Active Development** - Regular updates and fixes

## What Changed?

### Dockerfile (`dockerfiles/forge/Dockerfile`)
**Before:**
- Base: `nvidia/cuda:12.4.1-devel-ubuntu22.04`
- Python: 3.10
- Repository: `lllyasviel/stable-diffusion-webui-forge`
- Package Manager: pip
- PyTorch: Nightly builds with manual overrides

**After:**
- Base: `nvidia/cuda:12.4.1-devel-ubuntu22.04` (same)
- Python: 3.11 (required by Reforge Neo)
- Repository: `Haoming02/sd-webui-forge-classic` (neo branch)
- Package Manager: uv (much faster)
- PyTorch: 2.9.1+cu130 (stable, via requirements.txt)
- Extras: SageAttention 2 installed

### Docker Compose (`docker-compose.yml`)
- Service name: `forge` (unchanged for compatibility)
- Comment updated to reflect "Reforge Neo"
- All other settings remain the same (ports, volumes, GPU config, Traefik labels)

### Environment Variables (`.env.example`)
- No changes needed
- All `FORGE_*` variables still work

### Build Scripts
- `scripts/build-images.sh` - No changes needed (still builds "forge")
- `scripts/deploy-reforge-neo.sh` - **NEW** deployment script

## Deployment Instructions

### On Your Server:

```bash
cd /vol/service/cw/dhoch3-ai-services

# Pull latest changes
git pull

# Make deployment script executable
chmod +x scripts/deploy-reforge-neo.sh

# Run deployment (this will take 10-15 minutes)
./scripts/deploy-reforge-neo.sh
```

### What the Script Does:
1. Stops old Forge container
2. Removes old Forge image
3. Builds new Reforge Neo image (with `--no-cache`)
4. Starts Reforge Neo container
5. Shows status

### Manual Deployment (Alternative):

```bash
cd /vol/service/cw/dhoch3-ai-services

# Stop and remove old container
docker compose stop forge
docker compose rm -f forge

# Remove old image
docker rmi dhoch3/forge:latest

# Build new image
docker compose build --no-cache forge

# Start container
docker compose up -d forge

# Check logs
docker compose logs -f forge
```

## Verification

### Check Container Status:
```bash
docker compose ps forge
```

Should show: `Up` and `healthy`

### Check Logs:
```bash
docker compose logs -f forge
```

Should show:
- Python 3.11 detected
- uv package manager in use
- SageAttention 2 loaded
- WebUI starting on port 7861

### Access WebUI:
- **Local**: http://192.168.0.10:7861
- **Domain**: http://forge.design-hoch-drei.de

## Features

### Reforge Neo Specific Features:
- **SageAttention** - Faster than xformers/FlashAttention
- **uv Package Manager** - Faster installations
- **Optimized Memory Management** - Better VRAM usage
- **Latest PyTorch** - torch==2.9.1+cu130, xformers==0.0.33
- **Removed Bloat** - No unused features

### Command Line Args (in Dockerfile):
```
--listen --port 7861 --api 
--skip-prepare-environment --skip-install 
--skip-python-version-check --skip-torch-cuda-test 
--skip-version-check --sage --uv
```

## Troubleshooting

### Build Fails:
```bash
# Clear Docker cache and rebuild
docker builder prune -a
docker compose build --no-cache forge
```

### Container Won't Start:
```bash
# Check logs for errors
docker compose logs forge

# Verify GPU access
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### Performance Issues:
- SageAttention should be automatically enabled
- Check logs for "Using SageAttention" message
- If not, check GPU compatibility

## References

- **Reforge Neo Repository**: https://github.com/Haoming02/sd-webui-forge-classic/tree/neo
- **Original Forge**: https://github.com/lllyasviel/stable-diffusion-webui-forge
- **uv Package Manager**: https://github.com/astral-sh/uv
- **SageAttention**: https://github.com/thu-ml/SageAttention

## Commit Message

```
feat: replace Forge with Reforge Neo

Replace original Stable Diffusion WebUI Forge with Reforge Neo
(sd-webui-forge-classic neo branch) for better stability and performance.

Changes:
- Updated Dockerfile to use Python 3.11 and uv package manager
- Installed SageAttention 2 for improved performance
- Switched to Haoming02/sd-webui-forge-classic (neo branch)
- Added deployment script for easy updates
- Updated documentation to reflect changes

Benefits:
- Better RTX 5090 compatibility
- Faster package installation with uv
- Improved performance with SageAttention 2
- More stable and lightweight codebase
- Active development and regular updates

Fixes: Original Forge crashes and compatibility issues
```


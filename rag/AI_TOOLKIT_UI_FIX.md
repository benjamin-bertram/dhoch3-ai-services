# AI Toolkit Web UI Fix

## Problem

AI Toolkit container was running but the Web UI was not accessible. The container was only keeping itself alive with `tail -f /dev/null` instead of starting the actual UI service.

## Solution

Updated the AI Toolkit Dockerfile and configuration to properly start the Web UI on container startup.

## Changes Made

### 1. `dockerfiles/ai-toolkit/Dockerfile`

**Key Updates:**
- ✅ **CUDA 12.4.1 devel** - Upgraded from 12.1 runtime to 12.4.1 devel for RTX 5090 support
- ✅ **Node.js 18.x** - Installed Node.js for the Web UI
- ✅ **PyTorch 2.x cu124** - Updated to CUDA 12.4 compatible PyTorch
- ✅ **UI Build** - Added `npm install` and `npm run build` in the `ui` directory
- ✅ **UI Startup** - Changed CMD to start the UI with `npm run start`
- ✅ **Port 8675** - Exposed correct UI port (instead of 8080)
- ✅ **Health Check** - Updated to check UI availability via curl

**Before:**
```dockerfile
CMD ["/entrypoint.sh"]  # Just kept container running with tail -f /dev/null
```

**After:**
```dockerfile
CMD ["/entrypoint.sh"]  # Starts the Web UI with npm run start
```

### 2. `docker-compose.yml`

**Changes:**
- Port mapping: `8080:8080` → `8675:8675`
- Traefik loadbalancer port: `8080` → `8675`
- Updated service comment to mention "Web UI"

### 3. `.env.example`

**Changes:**
- `AI_TOOLKIT_PORT=8080` → `AI_TOOLKIT_PORT=8675`

### 4. `README.md`

**Changes:**
- Updated AI Toolkit port from 8080 to 8675
- Enhanced service description: "AI model training tools" → "AI model training tools with Web UI (FLUX.1, SDXL, SD 1.5 LoRA training)"

### 5. `scripts/deploy-ai-toolkit.sh` (New)

Created deployment script for easy AI Toolkit updates:
- Stops and removes old container
- Rebuilds image with `--no-cache`
- Starts new container
- Shows logs and status

## Technical Details

### AI Toolkit UI

The AI Toolkit has a Node.js-based Web UI that provides:
- Visual interface for training configuration
- FLUX.1, SDXL, and SD 1.5 LoRA training
- Dataset management
- Training progress monitoring
- Model output management

### Requirements

- **Node.js**: Version 18 or higher
- **Python**: 3.10
- **CUDA**: 12.4.1 (for RTX 5090 support)
- **PyTorch**: 2.x with CUDA 12.4 support

### UI Startup

The UI is started with:
```bash
cd /ai-toolkit/ui
npm run start
```

This runs the UI on port 8675 by default.

## Deployment

### On Server

```bash
cd /vol/service/cw/dhoch3-ai-services

# Pull latest changes
git pull

# Make script executable
chmod +x scripts/deploy-ai-toolkit.sh

# Deploy AI Toolkit
./scripts/deploy-ai-toolkit.sh
```

### Manual Deployment

```bash
# Stop and remove old container
docker compose stop ai-toolkit
docker compose rm -f ai-toolkit

# Rebuild image
docker compose build --no-cache ai-toolkit

# Start container
docker compose up -d ai-toolkit

# Check logs
docker compose logs -f ai-toolkit
```

## Access

- **Local**: http://192.168.0.10:8675
- **Domain**: http://ai-toolkit.design-hoch-drei.de

## Verification

Check if the UI is running:

```bash
# Check container status
docker compose ps ai-toolkit

# Check logs
docker compose logs -f ai-toolkit

# Test UI endpoint
curl http://192.168.0.10:8675/
```

The UI should respond with the web interface.

## Benefits

✅ **Web UI Available** - No more manual docker exec commands needed  
✅ **Visual Training** - Easy-to-use interface for model training  
✅ **RTX 5090 Support** - CUDA 12.4.1 for latest GPU compatibility  
✅ **Faster Installation** - Node.js UI builds during image creation  
✅ **Better UX** - Access training tools via browser instead of CLI  

## Related Documentation

- **AI Toolkit Repository**: https://github.com/ostris/ai-toolkit
- **UI Documentation**: https://github.com/ostris/ai-toolkit/tree/main/ui
- **Training Guides**: Available in the AI Toolkit repository

---

**Status**: ✅ Ready for deployment


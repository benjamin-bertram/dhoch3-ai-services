# Local Testing Guide

This guide helps you test the dhoch3-ai-services infrastructure on your local development machine before deploying to production.

## Prerequisites

### Required
- Linux machine (Ubuntu 20.04+ recommended)
- NVIDIA GPU with drivers installed
- Docker and Docker Compose
- At least 16GB RAM (32GB+ recommended)
- 100GB+ free disk space

### Check Prerequisites

```bash
# Check NVIDIA drivers
nvidia-smi

# Check Docker
docker --version
docker compose version

# Check NVIDIA Docker runtime
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

## Local Testing Setup

### 1. Modify Configuration for Local Testing

Create a local `.env` file for testing:

```bash
cp .env.example .env.local
```

Edit `.env.local` with local settings:

```bash
# SMB Storage - SKIP for local testing (we'll use local directories)
SMB_SERVER=192.168.0.6
SMB_SHARE=ki_Daten
SMB_USER=d3kiserver
SMB_PASSWORD=  # Leave empty for local testing

# Model Storage - Use local directory
MODELS_PATH=./test-models

# Domain - Use localhost
DOMAIN=localhost

# Traefik - Disable for local testing
TRAEFIK_NETWORK=traefik_default

# Ports - Use localhost ports
COMFYUI_PORT=8188
FOOOCUS_PORT=7860
FORGE_PORT=7861
INVOKEAI_PORT=9090
FLUXGYM_PORT=3000
AI_TOOLKIT_PORT=8080
DOCKGE_PORT=5001

# GPU
NVIDIA_VISIBLE_DEVICES=all
CUDA_VISIBLE_DEVICES=0

# Docker
COMPOSE_PROJECT_NAME=dhoch3-ai-services
```

### 2. Create Local Test Directories

```bash
# Create local model storage
mkdir -p test-models/{Stable-diffusion,Lora,VAE,ControlNet}

# Create local output directories (instead of SMB)
mkdir -p test-outputs/{ComfyUI,Fooocus,Forge,InvokeAI,FluxGym,AIToolkit}

# Create volume directories
mkdir -p volumes/{comfyui,invokeai,dockge,dockge-stacks}
```

### 3. Create Local Testing Docker Compose

Create `docker-compose.local.yml`:

```bash
# This will be created in the next step
```

### 4. Test Individual Services

Start with one service at a time to verify each works:

#### Test ComfyUI (Pre-built image)
```bash
docker-compose --env-file .env.local up comfyui
```

Access: http://localhost:8188

#### Test Fooocus (Local build)
```bash
# Build the image first
docker build -t dhoch3-fooocus:latest ./dockerfiles/fooocus/

# Run it
docker-compose --env-file .env.local up fooocus
```

Access: http://localhost:7860

#### Test Forge (Local build)
```bash
docker build -t dhoch3-forge:latest ./dockerfiles/forge/
docker-compose --env-file .env.local up forge
```

Access: http://localhost:7861

### 5. Test GPU Access

Verify GPU is accessible in containers:

```bash
# Test GPU in ComfyUI container
docker exec -it dhoch3-comfyui nvidia-smi

# Test GPU in Fooocus container
docker exec -it dhoch3-fooocus nvidia-smi
```

### 6. Test Ollama

```bash
# Install Ollama locally
curl -fsSL https://ollama.com/install.sh | sh

# Pull a small test model
ollama pull llama2:7b

# Test it
ollama run llama2:7b "Hello, how are you?"

# Check it's accessible
curl http://localhost:11434/api/tags
```


## Automated Local Testing

### Quick Test (Recommended)

Run the automated test script:

```bash
./scripts/test-local.sh
```

This script will:
1. ✅ Check all prerequisites (NVIDIA drivers, Docker, GPU runtime)
2. ✅ Create local test environment and directories
3. ✅ Optionally build Docker images
4. ✅ Start ComfyUI as a test service
5. ✅ Verify GPU access in containers
6. ✅ Provide summary and next steps

### Manual Testing Steps

If you prefer manual testing:

```bash
# 1. Create local environment
cp .env.example .env.local
# Edit .env.local with local settings (see above)

# 2. Create test directories
mkdir -p test-models test-outputs/{ComfyUI,Fooocus,Forge,InvokeAI,FluxGym,AIToolkit}

# 3. Build one service (e.g., Fooocus)
docker build -t dhoch3-fooocus:latest ./dockerfiles/fooocus/

# 4. Start it
docker-compose -f docker-compose.local.yml --env-file .env.local up fooocus

# 5. Access it
# Open http://localhost:7860 in your browser
```

## Testing Checklist

### Basic Tests
- [ ] NVIDIA drivers working (`nvidia-smi`)
- [ ] Docker installed and running
- [ ] NVIDIA Docker runtime configured
- [ ] Can pull CUDA base image
- [ ] Can build local Dockerfiles
- [ ] Services start without errors
- [ ] GPU accessible in containers
- [ ] Web UIs accessible on localhost

### Service-Specific Tests

#### ComfyUI (Pre-built)
```bash
docker-compose -f docker-compose.local.yml up -d comfyui
# Access: http://localhost:8188
# Test: Load a workflow, verify GPU is detected
```

#### Fooocus (Local build)
```bash
docker build -t dhoch3-fooocus:latest ./dockerfiles/fooocus/
docker-compose -f docker-compose.local.yml up -d fooocus
# Access: http://localhost:7860
# Test: Generate an image (will download models on first run)
```

#### Forge (Local build)
```bash
docker build -t dhoch3-forge:latest ./dockerfiles/forge/
docker-compose -f docker-compose.local.yml up -d forge
# Access: http://localhost:7861
# Test: Check settings show GPU, try txt2img
```

#### InvokeAI (Pre-built)
```bash
docker-compose -f docker-compose.local.yml up -d invokeai
# Access: http://localhost:9090
# Test: Complete initial setup, verify GPU detected
```

#### Dockge (Management UI)
```bash
docker-compose -f docker-compose.local.yml up -d dockge
# Access: http://localhost:5001
# Test: View running containers, check stack management
```

### GPU Tests

```bash
# Test GPU in running container
docker exec dhoch3-comfyui nvidia-smi

# Check GPU memory usage
watch -n 1 nvidia-smi

# Test CUDA in container
docker exec dhoch3-fooocus python -c "import torch; print(torch.cuda.is_available())"
```

## Common Local Testing Issues

### Issue: "NVIDIA driver not found"
**Solution**: Install NVIDIA drivers for your GPU
```bash
# Ubuntu
sudo ubuntu-drivers autoinstall
sudo reboot
```

### Issue: "docker: Error response from daemon: could not select device driver"
**Solution**: Install NVIDIA Container Toolkit
```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### Issue: "Port already in use"
**Solution**: Change ports in `.env.local`
```bash
COMFYUI_PORT=8189  # Instead of 8188
FOOOCUS_PORT=7862  # Instead of 7860
```

### Issue: "Out of memory" during build
**Solution**: Build one service at a time, or increase Docker memory limit
```bash
# Build individually
docker build -t dhoch3-fooocus:latest ./dockerfiles/fooocus/
# Wait for completion, then build next
docker build -t dhoch3-forge:latest ./dockerfiles/forge/
```

### Issue: Services start but web UI not accessible
**Solution**: Check logs and wait longer (first start downloads models)
```bash
docker-compose -f docker-compose.local.yml logs -f [service-name]
```

## Performance Notes

### First Run
- Services will download models on first run (can take 10-60 minutes)
- ComfyUI megapak image is ~20GB
- Each service may download 2-10GB of models

### Disk Space Requirements
- Docker images: ~30-50GB
- Models (if downloaded): 20-100GB depending on what you test
- Outputs: Varies based on usage

### RAM Requirements
- Minimum: 16GB (can test 1-2 services)
- Recommended: 32GB (can run 3-4 services simultaneously)
- Optimal: 64GB (can run all services)

### GPU Requirements
- Minimum: 8GB VRAM (can test basic functionality)
- Recommended: 12GB+ VRAM (can generate images)
- Optimal: 24GB+ VRAM (can train models with FluxGym)

## What to Test Before Production

1. **Build Process**: All Dockerfiles build successfully
2. **Service Startup**: All services start without errors
3. **GPU Access**: GPU is detected in all AI services
4. **Web UIs**: All web interfaces are accessible
5. **Basic Functionality**: Can generate a test image in at least one service
6. **Logs**: No critical errors in logs
7. **Resource Usage**: Monitor RAM and VRAM usage

## Cleaning Up After Testing

```bash
# Stop all services
docker-compose -f docker-compose.local.yml down

# Remove test data (optional)
rm -rf test-models test-outputs volumes

# Remove Docker images (optional, will need to rebuild)
docker rmi dhoch3-fooocus:latest dhoch3-forge:latest dhoch3-fluxgym:latest dhoch3-ai-toolkit:latest

# Clean up Docker system (optional, frees disk space)
docker system prune -a
```

## Next Steps After Local Testing

Once local testing is successful:

1. ✅ Commit your changes to git
2. ✅ Push to repository
3. ✅ Deploy to production server
4. ✅ Configure production `.env` with real SMB credentials
5. ✅ Run `./scripts/setup.sh` on production
6. ✅ Run `./scripts/build-images.sh` on production
7. ✅ Start services with `docker-compose up -d`
8. ✅ Verify Traefik routing works with subdomains

---

**Happy Testing! 🚀**


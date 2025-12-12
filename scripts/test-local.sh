#!/bin/bash
# Local Testing Script for dhoch3-ai-services
# Tests infrastructure on local development machine

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}dhoch3-ai-services - Local Testing${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd "$PROJECT_ROOT"

# ============================================
# 1. Check Prerequisites
# ============================================
echo -e "${BLUE}[1/6] Checking prerequisites...${NC}"

# Check NVIDIA drivers
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}Error: nvidia-smi not found. Install NVIDIA drivers first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ NVIDIA drivers installed${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker installed${NC}"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose installed${NC}"

# Check NVIDIA Docker runtime
if ! docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo -e "${YELLOW}Warning: NVIDIA Docker runtime may not be configured${NC}"
else
    echo -e "${GREEN}✓ NVIDIA Docker runtime working${NC}"
fi

echo ""

# ============================================
# 2. Create Local Test Environment
# ============================================
echo -e "${BLUE}[2/6] Setting up local test environment...${NC}"

# Create .env.local if not exists
if [ ! -f ".env.local" ]; then
    cat > .env.local << 'EOF'
# Local Testing Configuration
SMB_SERVER=192.168.0.6
SMB_SHARE=ki_Daten
SMB_USER=d3kiserver
SMB_PASSWORD=

MODELS_PATH=./test-models
DOMAIN=localhost
TRAEFIK_NETWORK=traefik_default

COMFYUI_PORT=8188
FOOOCUS_PORT=7860
FORGE_PORT=7861
INVOKEAI_PORT=9090
FLUXGYM_PORT=3000
AI_TOOLKIT_PORT=8080
DOCKGE_PORT=5001

NVIDIA_VISIBLE_DEVICES=all
CUDA_VISIBLE_DEVICES=0

COMPOSE_PROJECT_NAME=dhoch3-ai-services
EOF
    echo -e "${GREEN}✓ Created .env.local${NC}"
else
    echo -e "${GREEN}✓ .env.local already exists${NC}"
fi

# Create test directories
mkdir -p test-models/{Stable-diffusion,Lora,VAE,ControlNet}
mkdir -p test-outputs/{ComfyUI,Fooocus,Forge,InvokeAI,FluxGym,AIToolkit}
mkdir -p volumes/{comfyui,invokeai,dockge,dockge-stacks}

echo -e "${GREEN}✓ Created test directories${NC}"
echo ""

# ============================================
# 3. Build Local Images
# ============================================
echo -e "${BLUE}[3/6] Building Docker images...${NC}"
echo -e "${YELLOW}This may take 10-30 minutes depending on your internet speed${NC}"
echo ""

# Ask user if they want to build all or test with pre-built only
read -p "Build all local images? (y/n, 'n' will only test pre-built services): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./scripts/build-images.sh --continue-on-error
else
    echo -e "${YELLOW}Skipping local builds, will only test pre-built services${NC}"
fi

echo ""

# ============================================
# 4. Test Individual Services
# ============================================
echo -e "${BLUE}[4/6] Testing services individually...${NC}"
echo ""

# Test ComfyUI (pre-built)
echo -e "${YELLOW}Testing ComfyUI (pre-built image)...${NC}"
docker-compose -f docker-compose.local.yml --env-file .env.local up -d comfyui

echo "Waiting for ComfyUI to start..."
sleep 10

if curl -s http://localhost:8188 > /dev/null; then
    echo -e "${GREEN}✓ ComfyUI is running on http://localhost:8188${NC}"
else
    echo -e "${YELLOW}⚠ ComfyUI may still be starting, check logs: docker-compose -f docker-compose.local.yml logs comfyui${NC}"
fi

echo ""

# ============================================
# 5. Test GPU Access
# ============================================
echo -e "${BLUE}[5/6] Testing GPU access in containers...${NC}"

if docker exec dhoch3-comfyui nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ GPU accessible in ComfyUI container${NC}"
else
    echo -e "${RED}✗ GPU not accessible in containers${NC}"
fi

echo ""

# ============================================
# 6. Summary
# ============================================
echo -e "${BLUE}[6/6] Test Summary${NC}"
echo ""
echo -e "${GREEN}✓ Local testing environment ready!${NC}"
echo ""
echo -e "${BLUE}Running services:${NC}"
docker-compose -f docker-compose.local.yml ps
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Access ComfyUI: http://localhost:8188"
echo "2. Check logs: docker-compose -f docker-compose.local.yml logs -f"
echo "3. Start more services: docker-compose -f docker-compose.local.yml up -d [service]"
echo "4. Stop all: docker-compose -f docker-compose.local.yml down"
echo ""
echo -e "${BLUE}Available services to test:${NC}"
echo "  - comfyui (pre-built, already running)"
echo "  - fooocus (local build)"
echo "  - forge (local build)"
echo "  - invokeai (pre-built)"
echo "  - dockge (pre-built)"
echo ""


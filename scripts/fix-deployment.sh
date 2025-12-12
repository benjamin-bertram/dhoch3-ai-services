#!/bin/bash

# Fix deployment issues on server
# Run this script to fix all identified issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================="
echo "Fixing dhoch3-ai-services Deployment"
echo "========================================="
echo ""

# ============================================
# 1. Create model symlinks
# ============================================
echo -e "${BLUE}[1/5] Creating model symlinks...${NC}"

MODEL_PATH="/vol/service/cw/storage-models/models"
SMB_MODELS_DIR="/vol/service/cw/storage-user/models"

if [ -d "$MODEL_PATH" ]; then
    echo "Creating symlinks from $SMB_MODELS_DIR to $MODEL_PATH"
    
    for model_type in checkpoints loras vae controlnet upscale_models embeddings clip diffusion_models text_encoders unet style_models clip_vision gligen hypernetworks; do
        SERVER_DIR="${MODEL_PATH}/${model_type}"
        SMB_LINK="${SMB_MODELS_DIR}/${model_type}"
        
        if [ -d "$SERVER_DIR" ]; then
            # Remove existing symlink if it exists
            [ -L "$SMB_LINK" ] && rm "$SMB_LINK"
            
            # Create symlink
            if [ ! -e "$SMB_LINK" ]; then
                ln -s "$SERVER_DIR" "$SMB_LINK"
                echo -e "  ${GREEN}✓${NC} Linked: models/${model_type}"
            fi
        fi
    done
    
    echo -e "${GREEN}✓${NC} Model symlinks created"
else
    echo -e "${RED}Error: Model path not found: $MODEL_PATH${NC}"
    exit 1
fi

echo ""

# ============================================
# 2. Stop all containers
# ============================================
echo -e "${BLUE}[2/5] Stopping containers...${NC}"
docker compose down
echo -e "${GREEN}✓${NC} Containers stopped"
echo ""

# ============================================
# 3. Rebuild Forge image (fix CUDA library issue)
# ============================================
echo -e "${BLUE}[3/5] Rebuilding Forge image...${NC}"
echo "This will fix the libcusparseLt.so.0 error"
docker compose build --no-cache forge
echo -e "${GREEN}✓${NC} Forge image rebuilt"
echo ""

# ============================================
# 4. Rebuild AI-Toolkit image (fix startup command)
# ============================================
echo -e "${BLUE}[4/5] Rebuilding AI-Toolkit image...${NC}"
echo "This will fix the missing config_file_list error"
docker compose build --no-cache ai-toolkit
echo -e "${GREEN}✓${NC} AI-Toolkit image rebuilt"
echo ""

# ============================================
# 5. Start all containers
# ============================================
echo -e "${BLUE}[5/5] Starting containers...${NC}"
docker compose up -d
echo -e "${GREEN}✓${NC} Containers started"
echo ""

# ============================================
# Wait for containers to start
# ============================================
echo -e "${BLUE}Waiting 30 seconds for containers to initialize...${NC}"
sleep 30
echo ""

# ============================================
# Check container status
# ============================================
echo "========================================="
echo -e "${BLUE}Container Status:${NC}"
echo "========================================="
docker compose ps
echo ""

# ============================================
# Check Traefik network
# ============================================
echo "========================================="
echo -e "${BLUE}Traefik Network Status:${NC}"
echo "========================================="
docker network inspect traefik_default --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "No containers on traefik network"
echo ""

# ============================================
# Show access URLs
# ============================================
echo "========================================="
echo -e "${GREEN}Deployment Fixed!${NC}"
echo "========================================="
echo ""
echo "Access services:"
echo "  ComfyUI:   http://localhost:8188"
echo "  Fooocus:   http://localhost:7860"
echo "  Forge:     http://localhost:7861"
echo "  InvokeAI:  http://localhost:9090"
echo "  FluxGym:   http://localhost:3000"
echo "  Dockge:    http://localhost:5001"
echo ""
echo "Check logs:"
echo "  docker compose logs -f [service-name]"
echo ""
echo "For domain access, ensure:"
echo "  1. DNS points to this server"
echo "  2. Traefik is configured correctly"
echo "  3. Containers are on traefik network"
echo ""


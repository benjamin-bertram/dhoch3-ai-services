#!/bin/bash
# dhoch3-ai-services - System Setup Script
# Installs Ollama, configures Docker networks, sets up SMB mounts, and initializes environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}dhoch3-ai-services - System Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root for system-level operations
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Warning: Some operations may require sudo privileges${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

# ============================================
# 1. Check Prerequisites
# ============================================
echo -e "${BLUE}[1/7] Checking prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found${NC}"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose found${NC}"

# Check NVIDIA Docker runtime
if ! docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo -e "${YELLOW}Warning: NVIDIA Docker runtime may not be properly configured${NC}"
else
    echo -e "${GREEN}✓ NVIDIA Docker runtime working${NC}"
fi

echo ""

# ============================================
# 2. Install Ollama
# ============================================
echo -e "${BLUE}[2/7] Installing Ollama...${NC}"

if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓ Ollama already installed${NC}"
    ollama --version
else
    echo -e "${YELLOW}Installing Ollama...${NC}"
    curl -fsSL https://ollama.com/install.sh | $SUDO sh

    if command -v ollama &> /dev/null; then
        echo -e "${GREEN}✓ Ollama installed successfully${NC}"
    else
        echo -e "${RED}Error: Ollama installation failed${NC}"
        exit 1
    fi
fi

# Start Ollama service
if systemctl is-active --quiet ollama; then
    echo -e "${GREEN}✓ Ollama service is running${NC}"
else
    echo -e "${YELLOW}Starting Ollama service...${NC}"
    $SUDO systemctl start ollama
    $SUDO systemctl enable ollama
    echo -e "${GREEN}✓ Ollama service started and enabled${NC}"
fi

echo ""

# ============================================
# 3. Create .env file if not exists
# ============================================
echo -e "${BLUE}[3/7] Setting up environment configuration...${NC}"

if [ ! -f "$PROJECT_ROOT/.env" ]; then
    if [ -f "$PROJECT_ROOT/.env.example" ]; then
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        echo -e "${GREEN}✓ Created .env from .env.example${NC}"
        echo -e "${YELLOW}⚠ Please edit .env and configure your settings (SMB password, etc.)${NC}"
    else
        echo -e "${RED}Error: .env.example not found${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

echo ""

# ============================================
# 4. Create Docker networks
# ============================================
echo -e "${BLUE}[4/7] Creating Docker networks...${NC}"

# Check if Traefik network exists
if docker network inspect traefik_default &> /dev/null; then
    echo -e "${GREEN}✓ Traefik network already exists${NC}"
else
    echo -e "${YELLOW}Creating Traefik network...${NC}"
    docker network create traefik_default
    echo -e "${GREEN}✓ Traefik network created${NC}"
fi

echo ""

# ============================================
# 5. Verify model storage path
# ============================================
echo -e "${BLUE}[5/7] Verifying model storage...${NC}"

MODEL_PATH="/vol/service/cw/storage-models/models"
if [ -d "$MODEL_PATH" ]; then
    echo -e "${GREEN}✓ Model storage path exists: $MODEL_PATH${NC}"
    echo -e "  $(du -sh $MODEL_PATH 2>/dev/null || echo 'Size: Unknown')"
else
    echo -e "${YELLOW}Warning: Model storage path not found: $MODEL_PATH${NC}"
    echo -e "${YELLOW}Please ensure the path is correct in your .env file${NC}"
fi

echo ""



# ============================================
# 6. Test SMB connectivity
# ============================================
echo -e "${BLUE}[6/7] Testing SMB connectivity...${NC}"

# Source .env to get SMB settings
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"

    if command -v smbclient &> /dev/null; then
        # Check if SMB password is set
        if [ -z "$SMB_PASSWORD" ]; then
            echo -e "${YELLOW}⚠ SMB_PASSWORD not set in .env file${NC}"
            echo -e "${YELLOW}Skipping SMB connectivity test${NC}"
        else
            echo -e "${YELLOW}Testing SMB connection to //${SMB_SERVER}/${SMB_SHARE}...${NC}"
            # Use password from environment variable to avoid interactive prompt
            if smbclient -m SMB3 "//${SMB_SERVER}/${SMB_SHARE}" -U "${SMB_USER}%${SMB_PASSWORD}" -c "ls" &> /dev/null; then
                echo -e "${GREEN}✓ SMB connection successful${NC}"
            else
                echo -e "${YELLOW}⚠ Could not connect to SMB share${NC}"
                echo -e "${YELLOW}Please verify SMB credentials in .env file${NC}"
                echo -e "${YELLOW}Server: ${SMB_SERVER}, Share: ${SMB_SHARE}, User: ${SMB_USER}${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠ smbclient not installed, skipping SMB test${NC}"
        echo -e "${YELLOW}Install with: sudo apt-get install smbclient${NC}"
    fi
else
    echo -e "${YELLOW}⚠ .env file not found, skipping SMB test${NC}"
fi

echo ""

# ============================================
# 7. Summary and Next Steps
# ============================================
echo -e "${BLUE}[7/7] Setup Summary${NC}"
echo ""
echo -e "${GREEN}✓ Setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Edit .env file and configure your settings:"
echo "   - SMB_PASSWORD (required)"
echo "   - Verify MODELS_PATH"
echo "   - Verify DOMAIN settings"
echo ""
echo "2. Build Docker images:"
echo "   ./scripts/build-images.sh"
echo ""
echo "3. Start services:"
echo "   docker-compose up -d"
echo ""
echo "4. Check service status:"
echo "   docker-compose ps"
echo ""
echo "5. View logs:"
echo "   docker-compose logs -f [service-name]"
echo ""
echo -e "${BLUE}Available services:${NC}"
echo "  - comfyui    (http://comfyui.design-hoch-drei.de)"
echo "  - fooocus    (http://fooocus.design-hoch-drei.de)"
echo "  - forge      (http://forge.design-hoch-drei.de)"
echo "  - invokeai   (http://invokeai.design-hoch-drei.de)"
echo "  - fluxgym    (http://fluxgym.design-hoch-drei.de)"
echo "  - ai-toolkit (http://ai-toolkit.design-hoch-drei.de)"
echo "  - dockge     (http://dockge.design-hoch-drei.de)"
echo ""
echo -e "${BLUE}Ollama (native):${NC}"
echo "  - Access: http://localhost:11434"
echo "  - Pull models: ollama pull <model-name>"
echo "  - List models: ollama list"
echo ""

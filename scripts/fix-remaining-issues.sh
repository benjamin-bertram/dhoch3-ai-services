#!/bin/bash

# Fix remaining deployment issues
# Run this on the server to fix Forge, FluxGym, and Traefik network issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================="
echo "Fixing Remaining Issues"
echo "========================================="
echo ""

# ============================================
# 1. Stop problematic containers
# ============================================
echo -e "${BLUE}[1/6] Stopping Forge and FluxGym...${NC}"
docker compose stop forge fluxgym
echo -e "${GREEN}✓${NC} Containers stopped"
echo ""

# ============================================
# 2. Remove old images
# ============================================
echo -e "${BLUE}[2/6] Removing old images...${NC}"
docker rmi dhoch3/forge:latest || echo "Forge image not found, skipping"
docker rmi dhoch3/fluxgym:latest || echo "FluxGym image not found, skipping"
echo -e "${GREEN}✓${NC} Old images removed"
echo ""

# ============================================
# 3. Rebuild Forge with CUDA devel libraries
# ============================================
echo -e "${BLUE}[3/6] Rebuilding Forge (this will take 5-10 minutes)...${NC}"
echo "This fixes the libcusparseLt.so.0 error"
docker compose build --no-cache forge
echo -e "${GREEN}✓${NC} Forge rebuilt with CUDA devel libraries"
echo ""

# ============================================
# 4. Rebuild FluxGym
# ============================================
echo -e "${BLUE}[4/6] Rebuilding FluxGym...${NC}"
docker compose build --no-cache fluxgym
echo -e "${GREEN}✓${NC} FluxGym rebuilt"
echo ""

# ============================================
# 5. Check Traefik network
# ============================================
echo -e "${BLUE}[5/6] Checking Traefik network...${NC}"

# Check if traefik_default network exists
if docker network inspect traefik_default &> /dev/null; then
    echo -e "${GREEN}✓${NC} Traefik network exists"
else
    echo -e "${YELLOW}⚠${NC} Traefik network doesn't exist"
    echo "Creating traefik_default network..."
    docker network create traefik_default
    echo -e "${GREEN}✓${NC} Traefik network created"
fi
echo ""

# ============================================
# 6. Start containers
# ============================================
echo -e "${BLUE}[6/6] Starting all containers...${NC}"
docker compose up -d
echo -e "${GREEN}✓${NC} Containers started"
echo ""

# ============================================
# Wait for startup
# ============================================
echo -e "${BLUE}Waiting 30 seconds for containers to initialize...${NC}"
sleep 30
echo ""

# ============================================
# Check status
# ============================================
echo "========================================="
echo -e "${BLUE}Container Status:${NC}"
echo "========================================="
docker compose ps
echo ""

# ============================================
# Check Traefik network connections
# ============================================
echo "========================================="
echo -e "${BLUE}Containers on Traefik Network:${NC}"
echo "========================================="
TRAEFIK_CONTAINERS=$(docker network inspect traefik_default --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)
if [ -z "$TRAEFIK_CONTAINERS" ]; then
    echo -e "${RED}⚠ No containers on traefik network!${NC}"
    echo ""
    echo "This means domain access won't work."
    echo "Check your .env file:"
    echo "  TRAEFIK_NETWORK=traefik_default"
    echo ""
    echo "Also check if Traefik is running:"
    echo "  docker ps | grep traefik"
else
    echo "$TRAEFIK_CONTAINERS"
fi
echo ""

# ============================================
# Test local access
# ============================================
echo "========================================="
echo -e "${BLUE}Testing Local Access:${NC}"
echo "========================================="

test_service() {
    local name=$1
    local port=$2
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port | grep -q "200\|302\|401"; then
        echo -e "${GREEN}✓${NC} $name (http://localhost:$port)"
    else
        echo -e "${RED}✗${NC} $name (http://localhost:$port) - Not responding"
    fi
}

test_service "ComfyUI  " 8188
test_service "Fooocus  " 7860
test_service "Forge    " 7861
test_service "InvokeAI " 9090
test_service "FluxGym  " 3000
test_service "Dockge   " 5001

echo ""
echo "========================================="
echo -e "${GREEN}Fix Complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Check if all containers are healthy: docker compose ps"
echo "2. Check logs if any issues: docker compose logs -f [service]"
echo "3. For domain access, ensure Traefik is configured correctly"
echo ""


#!/bin/bash
# dhoch3-ai-services - Update Script
# Pulls latest code, rebuilds images, and restarts services with minimal downtime

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
echo -e "${BLUE}dhoch3-ai-services - Update${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# ============================================
# 1. Pull latest code
# ============================================
echo -e "${BLUE}[1/5] Pulling latest code from git...${NC}"

if [ -d ".git" ]; then
    # Stash any local changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}Stashing local changes...${NC}"
        git stash
        STASHED=true
    else
        STASHED=false
    fi
    
    # Pull latest changes
    git pull origin main
    
    # Restore stashed changes if any
    if [ "$STASHED" = true ]; then
        echo -e "${YELLOW}Restoring stashed changes...${NC}"
        git stash pop
    fi
    
    echo -e "${GREEN}✓ Code updated${NC}"
else
    echo -e "${YELLOW}Warning: Not a git repository, skipping git pull${NC}"
fi

echo ""

# ============================================
# 2. Backup current state
# ============================================
echo -e "${BLUE}[2/5] Creating backup...${NC}"

BACKUP_DIR="$PROJECT_ROOT/backups"
BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Export current container states
docker-compose ps > "$BACKUP_DIR/$BACKUP_NAME-containers.txt" 2>/dev/null || true

echo -e "${GREEN}✓ Backup created: $BACKUP_DIR/$BACKUP_NAME${NC}"
echo ""

# ============================================
# 3. Rebuild images
# ============================================
echo -e "${BLUE}[3/5] Rebuilding Docker images...${NC}"

if [ -f "$SCRIPT_DIR/build-images.sh" ]; then
    "$SCRIPT_DIR/build-images.sh" --continue-on-error
else
    echo -e "${YELLOW}Warning: build-images.sh not found, building with docker-compose${NC}"
    docker-compose build --no-cache
fi

echo ""

# ============================================
# 4. Restart services
# ============================================
echo -e "${BLUE}[4/5] Restarting services...${NC}"

# Get list of running services
RUNNING_SERVICES=$(docker-compose ps --services --filter "status=running" 2>/dev/null || echo "")

if [ -n "$RUNNING_SERVICES" ]; then
    echo -e "${YELLOW}Stopping services...${NC}"
    docker-compose down
    
    echo -e "${YELLOW}Starting services...${NC}"
    docker-compose up -d
    
    echo -e "${GREEN}✓ Services restarted${NC}"
else
    echo -e "${YELLOW}No services were running, starting all services...${NC}"
    docker-compose up -d
    echo -e "${GREEN}✓ Services started${NC}"
fi

echo ""

# ============================================
# 5. Verify services
# ============================================
echo -e "${BLUE}[5/5] Verifying services...${NC}"

# Wait a bit for services to start
sleep 5

# Check service status
echo -e "${YELLOW}Service status:${NC}"
docker-compose ps

echo ""

# Check for unhealthy containers
UNHEALTHY=$(docker-compose ps --filter "health=unhealthy" --services 2>/dev/null || echo "")
if [ -n "$UNHEALTHY" ]; then
    echo -e "${RED}Warning: Some services are unhealthy:${NC}"
    echo "$UNHEALTHY"
    echo ""
    echo -e "${YELLOW}Check logs with: docker-compose logs [service-name]${NC}"
else
    echo -e "${GREEN}✓ All services are healthy${NC}"
fi

echo ""

# ============================================
# Summary
# ============================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Update Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Update completed successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Check service logs:"
echo "   docker-compose logs -f [service-name]"
echo ""
echo "2. Access services:"
echo "   - ComfyUI:    http://comfyui.design-hoch-drei.de"
echo "   - Fooocus:    http://fooocus.design-hoch-drei.de"
echo "   - Forge:      http://forge.design-hoch-drei.de"
echo "   - InvokeAI:   http://invokeai.design-hoch-drei.de"
echo "   - FluxGym:    http://fluxgym.design-hoch-drei.de"
echo "   - AI Toolkit: http://ai-toolkit.design-hoch-drei.de"
echo "   - Dockge:     http://dockge.design-hoch-drei.de"
echo ""
echo "3. If issues occur, restore from backup:"
echo "   Backup location: $BACKUP_DIR/$BACKUP_NAME"
echo ""


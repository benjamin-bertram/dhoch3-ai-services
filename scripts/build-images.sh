#!/bin/bash
# dhoch3-ai-services - Build All Local Docker Images
# This script builds all locally-defined Docker images with proper error handling

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
echo -e "${BLUE}dhoch3-ai-services - Build Images${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Check if BuildKit is enabled
if [ -z "$DOCKER_BUILDKIT" ]; then
    export DOCKER_BUILDKIT=1
    echo -e "${YELLOW}Enabling Docker BuildKit${NC}"
fi

# Array of services to build
declare -a SERVICES=("fooocus" "forge" "fluxgym" "ai-toolkit")

# Build counter
TOTAL=${#SERVICES[@]}
SUCCESS=0
FAILED=0

# Function to build a single service
build_service() {
    local service=$1
    local dockerfile_path="$PROJECT_ROOT/dockerfiles/$service"
    
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${BLUE}Building: $service${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    
    if [ ! -d "$dockerfile_path" ]; then
        echo -e "${RED}Error: Dockerfile directory not found: $dockerfile_path${NC}"
        return 1
    fi
    
    if [ ! -f "$dockerfile_path/Dockerfile" ]; then
        echo -e "${RED}Error: Dockerfile not found: $dockerfile_path/Dockerfile${NC}"
        return 1
    fi
    
    # Build the image
    if docker build \
        --tag "dhoch3/$service:latest" \
        --tag "dhoch3/$service:$(date +%Y%m%d)" \
        --file "$dockerfile_path/Dockerfile" \
        "$dockerfile_path"; then
        echo -e "${GREEN}✓ Successfully built: $service${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to build: $service${NC}"
        return 1
    fi
}

# Build all services
for service in "${SERVICES[@]}"; do
    if build_service "$service"; then
        ((SUCCESS++))
    else
        ((FAILED++))
        if [ "$1" != "--continue-on-error" ]; then
            echo -e "${RED}Build failed. Use --continue-on-error to continue building other images.${NC}"
            exit 1
        fi
    fi
    echo ""
done

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Build Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total:   $TOTAL"
echo -e "${GREEN}Success: $SUCCESS${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed:  $FAILED${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All images built successfully!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Copy .env.example to .env and configure your settings"
    echo "2. Run: ./scripts/setup.sh"
    echo "3. Run: docker-compose up -d"
    exit 0
else
    echo -e "${RED}Some images failed to build${NC}"
    exit 1
fi


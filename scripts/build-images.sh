#!/bin/bash
# dhoch3-ai-services - Build All Local Docker Images
# This script builds all locally-defined Docker images with proper error handling

# Note: We don't use 'set -e' here because we want to continue building
# other images even if one fails, and show a summary at the end

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
SKIPPED=0

# Function to build a single service
build_service() {
    local service=$1
    local dockerfile_path="$PROJECT_ROOT/dockerfiles/$service"

    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${BLUE}Building: $service${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    # Check if image already exists
    if docker images "dhoch3/$service:latest" --format "{{.Repository}}:{{.Tag}}" | grep -q "dhoch3/$service:latest"; then
        echo -e "${YELLOW}⚠ Image dhoch3/$service:latest already exists${NC}"
        read -p "Rebuild? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}ℹ Skipping $service (already built)${NC}"
            return 2  # Return 2 to indicate "skipped"
        fi
    fi

    if [ ! -d "$dockerfile_path" ]; then
        echo -e "${RED}Error: Dockerfile directory not found: $dockerfile_path${NC}"
        return 1
    fi

    if [ ! -f "$dockerfile_path/Dockerfile" ]; then
        echo -e "${RED}Error: Dockerfile not found: $dockerfile_path/Dockerfile${NC}"
        return 1
    fi

    # Build the image (single tag to avoid duplicates)
    if docker build \
        --tag "dhoch3/$service:latest" \
        --file "$dockerfile_path/Dockerfile" \
        "$dockerfile_path"; then
        echo -e "${GREEN}✓ Successfully built: $service${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to build: $service${NC}"
        return 1
    fi
}

# Build all services (always continue on error to build all images)
echo -e "${YELLOW}Building all services (will continue even if one fails)...${NC}"
echo -e "${BLUE}Note: Each service will only be built once (tagged as 'latest')${NC}"
echo ""

for service in "${SERVICES[@]}"; do
    build_result=$?
    build_service "$service"
    build_result=$?

    if [ $build_result -eq 0 ]; then
        ((SUCCESS++))
    elif [ $build_result -eq 2 ]; then
        ((SKIPPED++))
    else
        ((FAILED++))
        echo -e "${YELLOW}⚠ Continuing with next service...${NC}"
    fi
    echo ""
done

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Build Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total:    $TOTAL"
echo -e "${GREEN}Success:  $SUCCESS${NC}"
if [ $SKIPPED -gt 0 ]; then
    echo -e "${BLUE}Skipped:  $SKIPPED${NC}"
fi
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed:   $FAILED${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All images built successfully!${NC}"
    echo ""
    echo -e "${BLUE}Built images:${NC}"
    docker images | grep "dhoch3/" | head -10
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Copy .env.example to .env and configure your settings"
    echo "2. Run: ./scripts/setup.sh"
    echo "3. Run: docker-compose up -d"
    exit 0
else
    echo -e "${RED}⚠ Some images failed to build${NC}"
    echo ""
    echo -e "${YELLOW}Successfully built images:${NC}"
    docker images | grep "dhoch3/" | head -10
    echo ""
    echo -e "${RED}Please check the error messages above and fix the Dockerfiles.${NC}"
    exit 1
fi


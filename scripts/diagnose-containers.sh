#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================="
echo "Container Health Diagnostics"
echo "========================================="
echo ""

# Check if docker compose is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Get all container names
CONTAINERS=$(docker compose ps --format '{{.Name}}' 2>/dev/null)

if [ -z "$CONTAINERS" ]; then
    echo -e "${RED}No containers found. Is docker-compose running?${NC}"
    exit 1
fi

echo -e "${BLUE}Checking container status...${NC}"
echo ""

for container in $CONTAINERS; do
    echo "========================================="
    echo -e "${YELLOW}Container: $container${NC}"
    echo "========================================="
    
    # Get container status
    STATUS=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)
    RESTART_COUNT=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null)
    
    echo "Status: $STATUS"
    echo "Health: $HEALTH"
    echo "Restart Count: $RESTART_COUNT"
    echo ""
    
    # Show last 30 lines of logs
    echo -e "${BLUE}Last 30 log lines:${NC}"
    docker logs --tail 30 "$container" 2>&1
    echo ""
    
    # If container is restarting, show exit code
    if [ "$STATUS" = "restarting" ]; then
        EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' "$container" 2>/dev/null)
        echo -e "${RED}Exit Code: $EXIT_CODE${NC}"
        echo ""
    fi
    
    echo ""
done

echo "========================================="
echo -e "${BLUE}Checking Traefik connectivity...${NC}"
echo "========================================="

# Check if containers are on traefik network
echo ""
echo "Containers on traefik network:"
docker network inspect traefik_default --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "Traefik network not found"
echo ""

# Check Traefik labels
echo "========================================="
echo -e "${BLUE}Checking Traefik labels...${NC}"
echo "========================================="
echo ""

for container in $CONTAINERS; do
    echo -e "${YELLOW}$container:${NC}"
    docker inspect "$container" --format='{{range $key, $value := .Config.Labels}}{{if eq (index (split $key ".") 0) "traefik"}}  {{$key}}: {{$value}}{{println}}{{end}}{{end}}' 2>/dev/null
    echo ""
done

echo "========================================="
echo -e "${BLUE}Checking port bindings...${NC}"
echo "========================================="
echo ""

for container in $CONTAINERS; do
    echo -e "${YELLOW}$container:${NC}"
    docker port "$container" 2>/dev/null || echo "  No port bindings"
    echo ""
done

echo "========================================="
echo -e "${BLUE}Checking volume mounts...${NC}"
echo "========================================="
echo ""

for container in $CONTAINERS; do
    echo -e "${YELLOW}$container:${NC}"
    docker inspect "$container" --format='{{range .Mounts}}  {{.Source}} -> {{.Destination}} ({{.Type}}){{println}}{{end}}' 2>/dev/null
    echo ""
done

echo "========================================="
echo "Diagnostics complete!"
echo "========================================="


#!/bin/bash

# Deploy Reforge Neo Script
# This script rebuilds and deploys the Reforge Neo container

set -e

echo "========================================="
echo "Deploying Reforge Neo"
echo "========================================="

# Navigate to project root
cd "$(dirname "$0")/.."

echo ""
echo "Step 1: Stopping old Forge container..."
docker compose stop forge || true
docker compose rm -f forge || true

echo ""
echo "Step 2: Removing old Forge image..."
docker rmi dhoch3/forge:latest || true

echo ""
echo "Step 3: Building Reforge Neo image (this may take 10-15 minutes)..."
docker compose build --no-cache forge

echo ""
echo "Step 4: Starting Reforge Neo container..."
docker compose up -d forge

echo ""
echo "Step 5: Waiting for container to start (60 seconds)..."
sleep 60

echo ""
echo "Step 6: Checking container status..."
docker compose ps forge

echo ""
echo "Step 7: Showing recent logs..."
docker compose logs --tail=50 forge

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Monitor logs with:"
echo "  docker compose logs -f forge"
echo ""
echo "Check if it's running:"
echo "  docker compose ps forge"
echo "  curl http://192.168.0.10:7861/"
echo ""
echo "Access Reforge Neo at:"
echo "  - Local: http://192.168.0.10:7861"
echo "  - Domain: http://forge.design-hoch-drei.de"
echo ""


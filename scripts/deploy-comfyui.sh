#!/bin/bash

# Deploy ComfyUI Script
# This script rebuilds and deploys the ComfyUI container with CUDA 12.4

set -e

echo "========================================="
echo "Deploying ComfyUI with CUDA 12.4"
echo "========================================="

# Navigate to project root
cd "$(dirname "$0")/.."

echo ""
echo "Step 1: Stopping old ComfyUI container..."
docker compose stop comfyui || true
docker compose rm -f comfyui || true

echo ""
echo "Step 2: Removing old ComfyUI image..."
docker rmi yanwk/comfyui-boot:cu128-megapak || true
docker rmi yanwk/comfyui-boot:cu128-megapak-pt28 || true

echo ""
echo "Step 3: Pulling new ComfyUI image (CUDA 12.4)..."
docker pull yanwk/comfyui-boot:cu124-megapak

echo ""
echo "Step 4: Starting ComfyUI container..."
docker compose up -d comfyui

echo ""
echo "Step 5: Waiting for container to start (30 seconds)..."
sleep 30

echo ""
echo "Step 6: Checking container status..."
docker compose ps comfyui

echo ""
echo "Step 7: Showing recent logs..."
docker compose logs --tail=50 comfyui

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Monitor logs with:"
echo "  docker compose logs -f comfyui"
echo ""
echo "Check if it's running:"
echo "  docker compose ps comfyui"
echo "  curl http://192.168.0.10:8188/"
echo ""
echo "Access ComfyUI at:"
echo "  - Local: http://192.168.0.10:8188"
echo "  - Domain: http://comfyui.design-hoch-drei.de"
echo ""
echo "This version uses CUDA 12.4 which should fix the"
echo "flash-attention error on RTX 6000 Ada (compute capability 8.9)"
echo ""


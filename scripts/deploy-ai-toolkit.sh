#!/bin/bash

# AI Toolkit Deployment Script
# Rebuilds and restarts AI Toolkit with Web UI

set -e

echo "========================================="
echo "AI Toolkit Deployment"
echo "========================================="
echo ""

# Check if running in correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo "📦 Stopping AI Toolkit container..."
docker compose stop ai-toolkit || true

echo "🗑️  Removing old AI Toolkit container..."
docker compose rm -f ai-toolkit || true

echo "🔨 Building AI Toolkit image with Web UI..."
docker compose build --no-cache ai-toolkit

echo "🚀 Starting AI Toolkit..."
docker compose up -d ai-toolkit

echo ""
echo "⏳ Waiting for AI Toolkit to start (60 seconds)..."
sleep 60

echo ""
echo "📊 Checking AI Toolkit status..."
docker compose ps ai-toolkit

echo ""
echo "📋 AI Toolkit logs (last 30 lines):"
docker compose logs --tail=30 ai-toolkit

echo ""
echo "========================================="
echo "✅ AI Toolkit Deployment Complete!"
echo "========================================="
echo ""
echo "Access AI Toolkit:"
echo "  - Local: http://192.168.0.10:8675"
echo "  - Domain: http://ai-toolkit.design-hoch-drei.de"
echo ""
echo "Check logs:"
echo "  docker compose logs -f ai-toolkit"
echo ""
echo "Check status:"
echo "  docker compose ps ai-toolkit"
echo ""


#!/bin/bash
# Rebuild ONLY Forge with PyTorch Nightly for RTX 5090 support

echo "========================================="
echo "Rebuilding Forge with PyTorch Nightly"
echo "========================================="
echo ""

echo "📋 What's being fixed:"
echo "   - RTX 5090 requires CUDA compute capability sm_120"
echo "   - Stable PyTorch only supports up to sm_90"
echo "   - Solution: Use PyTorch NIGHTLY builds with sm_120 support"
echo ""
echo "Changes:"
echo "   ✓ PyTorch 2.6.0+cu124 → PyTorch Nightly (2.7.0+)"
echo "   ✓ xformers stable → xformers nightly (compatible)"
echo "   ✓ Flash Attention compatibility fixed"
echo "   ✓ torchaudio from PyPI (not available in nightly cu124)"
echo ""

read -p "This will rebuild Forge (~20-25 minutes). Continue? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "========================================="
echo "Starting Forge Rebuild"
echo "========================================="
echo ""

# Stop and remove container
echo "1️⃣ Stopping and removing old Forge container..."
sudo docker compose -f docker-compose.local.yml stop forge
sudo docker compose -f docker-compose.local.yml rm -f forge
echo "✓ Container removed"
echo ""

# Remove old image
echo "2️⃣ Removing old Forge image..."
sudo docker rmi dhoch3/forge:latest 2>/dev/null || echo "   (Forge image not found)"
echo "✓ Old image removed"
echo ""

# Build Forge
echo "3️⃣ Building Forge with PyTorch Nightly..."
echo "   This will take approximately 20-25 minutes."
echo "   Installing PyTorch nightly + xformers nightly..."
echo ""
sudo docker compose -f docker-compose.local.yml build --no-cache forge

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Forge build successful!"
    echo ""
else
    echo ""
    echo "❌ Forge build failed!"
    echo "Check the error messages above."
    exit 1
fi

# Start service
echo "4️⃣ Starting Forge..."
sudo docker compose -f docker-compose.local.yml up -d forge
echo "✓ Forge started"
echo ""

echo "========================================="
echo "✅ Rebuild Complete!"
echo "========================================="
echo ""
echo "📊 Service Status:"
sudo docker compose -f docker-compose.local.yml ps | grep -E "(NAME|forge)"
echo ""
echo "🔍 Monitor startup:"
echo "   sudo docker compose -f docker-compose.local.yml logs -f forge"
echo ""
echo "🌐 Access point (after initialization):"
echo "   Forge: http://localhost:7861"
echo ""
echo "⏱️  Wait 3-5 minutes for Forge to fully initialize."
echo ""
echo "✅ Expected in logs:"
echo "   - PyTorch version: 2.7.0+ (nightly)"
echo "   - CUDA capability: sm_120 supported"
echo "   - No xformers compatibility warnings"
echo "   - No Flash Attention import errors"
echo "   - 'Running on local URL: http://0.0.0.0:7861'"


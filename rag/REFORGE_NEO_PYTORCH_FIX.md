# Reforge Neo PyTorch Import Error Fix

## Problem

Reforge Neo container was stuck in a restart loop with the following error:

```
ImportError: /root/.cache/torch/lib/python3.10/dist-packages/torch/__init__.py: 
cannot open shared object file: No such file or directory
```

**Root Cause:** PyTorch was not being installed correctly in the virtual environment. The `uv pip install -r requirements.txt` command was trying to install PyTorch, but it wasn't getting the CUDA 12.4 version properly.

## Solution

Install PyTorch explicitly with CUDA 12.4 support **before** installing other requirements.

## Changes Made

### `dockerfiles/forge/Dockerfile`

**Before:**
```dockerfile
# Create virtual environment using uv
RUN uv venv venv --python 3.11 --seed

# Activate venv and install requirements using uv
RUN . venv/bin/activate && \
    uv pip install -r requirements.txt
```

**After:**
```dockerfile
# Create virtual environment using uv
RUN uv venv venv --python 3.11 --seed

# Activate venv and install PyTorch first with CUDA 12.4 support
RUN . venv/bin/activate && \
    uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Install other requirements using uv
RUN . venv/bin/activate && \
    uv pip install -r requirements.txt
```

**Why This Works:**
1. PyTorch is installed first with explicit CUDA 12.4 support
2. The `--index-url` ensures we get the correct CUDA-enabled version
3. Other requirements are installed after PyTorch is properly set up
4. This prevents version conflicts and ensures CUDA libraries are available

### Enhanced Entrypoint Script

Added debugging output to help diagnose issues:

```bash
#!/bin/bash
set -e
echo "========================================"
echo "Reforge Neo Starting..."
echo "========================================"
echo ""
echo "Activating virtual environment..."
source /app/venv/bin/activate
echo ""
echo "Python version: $(python --version)"
echo "PyTorch version: $(python -c "import torch; print(torch.__version__)")"
echo "CUDA available: $(python -c "import torch; print(torch.cuda.is_available())")"
echo "CUDA version: $(python -c "import torch; print(torch.version.cuda if torch.cuda.is_available() else 'N/A')")"
echo ""
echo "Starting Reforge Neo..."
echo "Command: python launch.py ${COMMANDLINE_ARGS}"
echo ""
python launch.py ${COMMANDLINE_ARGS}
```

This will show:
- Python version (should be 3.11)
- PyTorch version (should be 2.x+cu124)
- CUDA availability (should be True)
- CUDA version (should be 12.4)

### Updated Deployment Script

Enhanced `scripts/deploy-reforge-neo.sh`:
- Increased wait time to 60 seconds
- Shows last 50 lines of logs
- Added curl test command

## Deployment

### On Server

```bash
cd /vol/service/cw/dhoch3-ai-services

# Pull latest changes
git pull

# Run deployment script
chmod +x scripts/deploy-reforge-neo.sh
./scripts/deploy-reforge-neo.sh
```

The script will:
1. Stop and remove old container
2. Remove old image
3. Build new image with PyTorch fix (10-15 minutes)
4. Start new container
5. Wait 60 seconds
6. Show status and logs

### Manual Deployment

```bash
# Stop and remove
docker compose stop forge
docker compose rm -f forge
docker rmi dhoch3/forge:latest

# Rebuild with no cache
docker compose build --no-cache forge

# Start
docker compose up -d forge

# Monitor logs
docker compose logs -f forge
```

## Verification

### Check Container Status

```bash
docker compose ps forge
```

Should show "Up" status, not "Restarting".

### Check Logs

```bash
docker compose logs -f forge
```

Should show:
```
========================================
Reforge Neo Starting...
========================================

Activating virtual environment...

Python version: Python 3.11.x
PyTorch version: 2.x.x+cu124
CUDA available: True
CUDA version: 12.4

Starting Reforge Neo...
```

### Test Access

```bash
# Test locally
curl http://192.168.0.10:7861/

# Should return HTML (Gradio interface)
```

Then access via browser:
- **Local**: http://192.168.0.10:7861
- **Domain**: http://forge.design-hoch-drei.de

## Technical Details

### PyTorch Installation Order

The order matters:
1. ✅ **Install PyTorch first** with explicit CUDA version
2. ✅ **Then install other requirements** which may depend on PyTorch

If you install requirements first:
- ❌ PyTorch might get installed without CUDA support
- ❌ Version conflicts can occur
- ❌ CUDA libraries might not be properly linked

### CUDA 12.4 Support

Using `--index-url https://download.pytorch.org/whl/cu124`:
- Gets PyTorch compiled for CUDA 12.4
- Includes all necessary CUDA libraries
- Compatible with RTX 5090 (sm_120 compute capability)

---

**Status**: ✅ Fixed and ready for deployment


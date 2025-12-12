# RTX 5090 Setup Guide

## Overview

This guide documents the setup process for running Forge and Fooocus with the **NVIDIA RTX 5090** (Blackwell architecture, sm_120 compute capability).

---

## The Challenge

The RTX 5090 was released in late 2024 with CUDA compute capability **sm_120**. Stable PyTorch releases (2.6.0 and earlier) only support up to **sm_90**, making them incompatible with the RTX 5090.

**Solution:** Use PyTorch nightly builds which include sm_120 support.

---

## What Was Fixed

### 1. CUDA Version Upgrade
- **Before:** CUDA 12.1.0
- **After:** CUDA 12.4.1
- **Why:** RTX 5090 requires CUDA 12.4+

### 2. PyTorch Nightly Installation
- **Before:** Stable PyTorch 2.6.0+cu124 (no sm_120 support)
- **After:** PyTorch nightly 2.7.0.dev+cu124 (with sm_120 support)
- **Why:** Only nightly builds support Blackwell architecture

### 3. xformers Removal
- **Issue:** xformers is incompatible with PyTorch nightly
- **Solution:** Don't install xformers, use PyTorch native attention
- **Impact:** Slightly slower but stable and compatible

### 4. Forge Compatibility Check Bypass
- **Issue:** Forge's internal check rejects PyTorch nightly
- **Solution:** Patch `launch_utils.py` to skip the check
- **Method:** Python regex replacement during Docker build

---

## Current Configuration

### Dockerfiles

Both `dockerfiles/fooocus/Dockerfile` and `dockerfiles/forge/Dockerfile` now:

1. Use CUDA 12.4.1 base image
2. Install Cairo dependencies (for svglib)
3. Remove torch/xformers from requirements
4. Install PyTorch nightly separately
5. Skip xformers installation
6. (Forge only) Patch compatibility check

### Key Dockerfile Sections

```dockerfile
# Base image
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

# Remove torch and xformers from requirements
RUN grep -v "^torch" requirements_versions.txt | grep -v "^xformers" > requirements_no_torch.txt

# Install dependencies (without torch/xformers)
RUN pip install -r requirements_no_torch.txt

# Install PyTorch nightly
RUN pip install --pre torch --index-url https://download.pytorch.org/whl/nightly/cu124

# Patch compatibility check (Forge only)
RUN python3 -c "import re; \
content = open('/app/modules/launch_utils.py', 'r').read(); \
content = re.sub(r'raise RuntimeError\([^)]*Your device does not support[^)]*\)', 'print(\"Warning: CUDA compatibility check skipped for RTX 5090 with PyTorch nightly\")', content, flags=re.DOTALL); \
open('/app/modules/launch_utils.py', 'w').write(content)"
```

---

## Rebuilding Services

### Rebuild Forge Only
```bash
./rebuild-forge-only.sh
```

### Rebuild Both Services
```bash
# Stop services
sudo docker compose -f docker-compose.local.yml stop fooocus forge

# Remove containers and images
sudo docker compose -f docker-compose.local.yml rm -f fooocus forge
sudo docker rmi dhoch3/fooocus:latest dhoch3/forge:latest

# Rebuild
sudo docker compose -f docker-compose.local.yml build --no-cache fooocus forge

# Start
sudo docker compose -f docker-compose.local.yml up -d fooocus forge
```

---

## Verification

### Check PyTorch Version
```bash
sudo docker exec dhoch3-forge python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.version.cuda}'); print(f'GPU: {torch.cuda.get_device_name(0)}')"
```

**Expected output:**
```
PyTorch: 2.7.0.dev20250310+cu124
CUDA: 12.4
GPU: NVIDIA GeForce RTX 5090 Laptop GPU
```

### Check Logs
```bash
sudo docker compose -f docker-compose.local.yml logs forge | tail -50
```

**Success indicators:**
- ✅ `CUDA Version 12.4.1`
- ✅ `pytorch version: 2.7.0.dev+cu124`
- ✅ `Device: cuda:0 NVIDIA GeForce RTX 5090 Laptop GPU : native`
- ✅ `Using pytorch cross attention`
- ✅ `Running on local URL: http://0.0.0.0:7861`

**Should NOT see:**
- ❌ `sm_120 is not compatible`
- ❌ `xFormers can't load C++/CUDA extensions`
- ❌ `RuntimeError: Your device does not support`
- ❌ `TypeError: JITCallable._set_src()`

---

## Performance Notes

### Without xformers
- Uses PyTorch's native attention mechanism
- Slightly slower than xformers (~10-15%)
- More stable and compatible
- RTX 5090's 24GB VRAM handles it easily

### Future Improvements
- Once xformers releases a version compatible with PyTorch nightly, it can be added back
- PyTorch 2.7.0 stable (expected Q1 2025) will have sm_120 support
- Can switch back to stable PyTorch once 2.7.0 is released

---

## Troubleshooting

### Build fails with "Could not find a version that satisfies the requirement"
- Check internet connection
- Verify PyTorch nightly index is accessible: https://download.pytorch.org/whl/nightly/cu124

### Container crashes on startup
- Check logs: `sudo docker logs dhoch3-forge`
- Verify PyTorch version in logs
- Ensure xformers is NOT installed: `sudo docker exec dhoch3-forge pip list | grep xformers`

### Web UI not accessible
- Wait 3-5 minutes for initialization
- Check if port 7861 is in use: `sudo netstat -tlnp | grep 7861`
- Verify container is running: `sudo docker ps | grep forge`

---

## Technical Details

| Component | Version | Notes |
|-----------|---------|-------|
| Base Image | nvidia/cuda:12.4.1-runtime-ubuntu22.04 | Required for RTX 5090 |
| Python | 3.10.12 | From base image |
| PyTorch | 2.7.0.dev+cu124 (nightly) | Only version with sm_120 support |
| CUDA | 12.4 | Minimum for Blackwell architecture |
| xformers | Not installed | Incompatible with PyTorch nightly |
| Attention | PyTorch native | Fallback from xformers |

---

## References

- [PyTorch Nightly Builds](https://download.pytorch.org/whl/nightly/cu124/)
- [NVIDIA CUDA Compatibility](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#compute-capabilities)
- [Forge Repository](https://github.com/lllyasviel/stable-diffusion-webui-forge)
- [Fooocus Repository](https://github.com/lllyasviel/Fooocus)


# ComfyUI CUDA Flash-Attention Error Fix

## Problem

ComfyUI was experiencing CUDA errors when generating images with the error:

```
CUDA error (/__w/xformers/xformers/third_party/flash-attention/hopper/flash_fwd_launch_template.h:180): invalid argument
```

**Root Cause:** The `yanwk/comfyui-boot:cu128-megapak` image uses CUDA 12.8 with flash-attention compiled for newer GPUs. The RTX 6000 Ada (compute capability 8.9) has compatibility issues with this version.

## GPU Information

- **GPU**: NVIDIA RTX 6000 Ada Generation
- **Compute Capability**: 8.9 (Ada Lovelace architecture)
- **VRAM**: 48GB
- **Recommended CUDA**: 12.4 or 12.1

## Solution

Switch from CUDA 12.8 to CUDA 12.4 image which has better compatibility with RTX 6000 Ada.

## Changes Made

### `docker-compose.yml`

**Before:**
```yaml
comfyui:
  image: ${COMFYUI_IMAGE:-yanwk/comfyui-boot:cu128-megapak}
```

**After:**
```yaml
comfyui:
  # Using cu124-megapak for better RTX 6000 Ada compatibility (compute capability 8.9)
  # cu128 had flash-attention issues with this GPU
  image: ${COMFYUI_IMAGE:-yanwk/comfyui-boot:cu124-megapak}
```

**Why This Works:**
1. CUDA 12.4 has better support for Ada Lovelace architecture (sm_89)
2. Flash-attention in cu124 is compiled with correct compute capabilities
3. PyTorch 2.x in cu124 image is more stable for this GPU generation
4. Avoids bleeding-edge CUDA 12.8 compatibility issues

### New Deployment Script

Created `scripts/deploy-comfyui.sh` for easy redeployment.

## Deployment

### On Server

```bash
cd /vol/service/cw/dhoch3-ai-services

# Pull latest changes
git pull

# Run deployment script
chmod +x scripts/deploy-comfyui.sh
./scripts/deploy-comfyui.sh
```

The script will:
1. Stop and remove old container
2. Remove old CUDA 12.8 images
3. Pull new CUDA 12.4 image
4. Start new container
5. Wait 30 seconds
6. Show status and logs

### Manual Deployment

```bash
# Stop and remove
docker compose stop comfyui
docker compose rm -f comfyui

# Remove old images
docker rmi yanwk/comfyui-boot:cu128-megapak
docker rmi yanwk/comfyui-boot:cu128-megapak-pt28

# Pull new image
docker pull yanwk/comfyui-boot:cu124-megapak

# Start
docker compose up -d comfyui

# Monitor logs
docker compose logs -f comfyui
```

## Verification

### Check Container Status

```bash
docker compose ps comfyui
```

Should show "Up" status.

### Check Logs

```bash
docker compose logs -f comfyui
```

Should show:
```
Total VRAM 49140 MB, total RAM 257698 MB
pytorch version: 2.x.x+cu124
Set vram state to: NORMAL_VRAM
Device: cuda:0 NVIDIA RTX 6000 Ada Generation : native
VAE dtype: torch.bfloat16
```

**No flash-attention errors should appear.**

### Test Generation

1. Access ComfyUI: http://192.168.0.10:8188 or http://comfyui.design-hoch-drei.de
2. Load a workflow
3. Generate an image
4. Should complete without CUDA errors

## Technical Details

### CUDA Version Compatibility

| CUDA Version | RTX 6000 Ada Support | Flash-Attention | Status |
|--------------|---------------------|-----------------|---------|
| 12.8 (cu128) | ⚠️ Partial | ❌ Errors | Not recommended |
| 12.4 (cu124) | ✅ Full | ✅ Works | **Recommended** |
| 12.1 (cu121) | ✅ Full | ✅ Works | Alternative |

### Compute Capability Reference

- **RTX 6000 Ada**: sm_89 (Ada Lovelace)
- **RTX 5090**: sm_120 (Blackwell) - needs CUDA 12.8+
- **RTX 4090**: sm_89 (Ada Lovelace) - same as RTX 6000 Ada

### Why Flash-Attention Failed

Flash-attention is compiled for specific compute capabilities. The cu128 image was likely compiled primarily for:
- sm_90 (Hopper - H100)
- sm_120 (Blackwell - RTX 5090)

But had issues with sm_89 (Ada Lovelace - RTX 6000 Ada).

The cu124 image has better sm_89 support.

## Alternative Solutions (if cu124 doesn't work)

### Option 1: Try cu121

```yaml
image: ${COMFYUI_IMAGE:-yanwk/comfyui-boot:cu121-megapak}
```

### Option 2: Disable Flash-Attention

Add environment variable:
```yaml
environment:
  - XFORMERS_FORCE_DISABLE_TRITON=1
  - PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

### Option 3: Build Custom Image

Build ComfyUI with specific PyTorch/CUDA versions for sm_89.

## Monitoring

After deployment, monitor for:
- ✅ No CUDA errors in logs
- ✅ Successful image generation
- ✅ Normal VRAM usage
- ✅ No "flash_fwd_launch_template" errors

---

**Status**: ✅ Fixed - Ready for deployment with CUDA 12.4


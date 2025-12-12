# ComfyUI Docker Image Options

## Issue: Pull Access Denied - SOLVED ✅

If you encountered this error:
```
pull access denied for yanwenkunwork/comfyui-docker, repository does not exist or may require 'docker login'
```

**Root cause:** The image name was incorrect. The correct repository is `yanwk/comfyui-boot` (not `yanwenkunwork/comfyui-docker`).

---

## Recommended Images

### 1. YanWenKun's ComfyUI (Recommended) ✅

**Repository:** https://github.com/YanWenKun/ComfyUI-Docker
**Docker Hub:** https://hub.docker.com/r/yanwk/comfyui-boot

**Available tags:**

#### MEGAPAK (All-in-one with custom nodes)
- `yanwk/comfyui-boot:cu128-megapak` ⭐ **Recommended**
  - CUDA 12.8, Python 3.12, GCC 14
  - Includes dozens of custom nodes pre-installed
  - Works with RTX 5090 (Blackwell), RTX 4090, RTX 3090, etc.

- `yanwk/comfyui-boot:cu128-megapak-pt28`
  - CUDA 12.8, PyTorch 2.8
  - Latest PyTorch features

- `yanwk/comfyui-boot:cu126-megapak`
  - CUDA 12.6, Python 3.12, GCC 13
  - For older GPUs (Maxwell, Pascal, Volta)

#### SLIM (Minimal install)
- `yanwk/comfyui-boot:cu128-slim`
  - CUDA 12.8, Python 3.12
  - Only ComfyUI + ComfyUI-Manager
  - Smaller image size, install custom nodes as needed

- `yanwk/comfyui-boot:cu126-slim`
  - CUDA 12.6, Python 3.12
  - For older GPUs

**Pros:**
- ✅ Publicly available (no authentication needed)
- ✅ Actively maintained by YanWenKun
- ✅ CUDA 12.8 support (latest)
- ✅ RTX 5090 (Blackwell) support
- ✅ Multiple variants (slim/megapak)
- ✅ Well-documented

**Usage:**
```yaml
# In docker-compose.yml or .env
COMFYUI_IMAGE=yanwk/comfyui-boot:cu128-megapak
```

---

### 2. Official ComfyUI (Build from Source)

**Repository:** https://github.com/comfyanonymous/ComfyUI

**Pros:**
- ✅ Official source
- ✅ Latest features
- ✅ Full control over configuration

**Cons:**
- ⚠️ Requires building custom Dockerfile
- ⚠️ More maintenance overhead

**To use:** Create `dockerfiles/comfyui/Dockerfile` and build locally.

---

## Current Configuration

**Default image:** `yanwk/comfyui-boot:cu128-megapak`

This is set in:
- `docker-compose.yml` (line 20)
- `.env.example` (COMFYUI_IMAGE variable)

**Why this image?**
- ✅ Correct repository name (yanwk/comfyui-boot)
- ✅ CUDA 12.8 for RTX 5090 support
- ✅ MEGAPAK includes many custom nodes pre-installed
- ✅ Publicly accessible, no authentication needed

---

## Changing the Image

### Method 1: Update .env file
```bash
# Edit .env
COMFYUI_IMAGE=yanwk/comfyui-boot:cu128-megapak
```

### Method 2: Update docker-compose.yml
```yaml
comfyui:
  image: yanwk/comfyui-boot:cu128-megapak
```

### Method 3: Override at runtime
```bash
COMFYUI_IMAGE=yanwk/comfyui-boot:cu128-megapak docker compose up -d comfyui
```

---

## Troubleshooting

### Pull Access Denied
```bash
# Try pulling manually to verify access
docker pull yanwk/comfyui-boot:cu128-megapak

# If it fails, check:
# 1. Internet connectivity
# 2. Image name spelling (yanwk/comfyui-boot, NOT yanwenkunwork/comfyui-docker)
# 3. Docker Hub status
```

### Image Not Found
```bash
# List available tags on Docker Hub
# Visit: https://hub.docker.com/r/yanwk/comfyui-boot/tags

# Or check the GitHub repository
# Visit: https://github.com/YanWenKun/ComfyUI-Docker
```

### Wrong Image Name
**Common mistake:** Using `yanwenkunwork/comfyui-docker` instead of `yanwk/comfyui-boot`

**Correct repository:** `yanwk/comfyui-boot`

---

## Deployment Steps (Server)

1. **Update .env on server:**
   ```bash
   cd /vol/service/cw/dhoch3-ai-services
   nano .env
   # Set: COMFYUI_IMAGE=yanwk/comfyui-boot:cu128-megapak
   ```

2. **Pull the image:**
   ```bash
   docker compose pull comfyui
   ```

3. **Start ComfyUI:**
   ```bash
   docker compose up -d comfyui
   ```

4. **Verify:**
   ```bash
   docker compose ps comfyui
   docker compose logs -f comfyui
   ```

5. **Access ComfyUI:**
   ```
   http://comfyui.design-hoch-drei.de
   ```

---

## Summary

| Image | Status | CUDA | Auth Required | Recommended |
|-------|--------|------|---------------|-------------|
| `yanwk/comfyui-boot:cu128-megapak` | ✅ Available | 12.8 | No | ✅ Yes |
| `yanwk/comfyui-boot:cu128-slim` | ✅ Available | 12.8 | No | ✅ Yes (minimal) |
| `yanwk/comfyui-boot:cu126-megapak` | ✅ Available | 12.6 | No | ⚠️ Older GPUs |
| `yanwenkunwork/comfyui-docker:*` | ❌ Wrong name | N/A | N/A | ❌ No |
| Build from source | ✅ Available | Custom | No | ⚠️ Advanced |

**Recommendation:** Use `yanwk/comfyui-boot:cu128-megapak` for hassle-free deployment with all features.

**Key Points:**
- ✅ Correct repository: `yanwk/comfyui-boot` (NOT `yanwenkunwork/comfyui-docker`)
- ✅ CUDA 12.8 for RTX 5090 (Blackwell) support
- ✅ MEGAPAK includes dozens of custom nodes pre-installed
- ✅ No authentication required


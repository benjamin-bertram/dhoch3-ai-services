# 🔧 Building & Updating

How to build Docker images, update services, and deploy changes.

---

## Which Services Need Building?

| Service | Image Type | Needs `docker compose build`? |
|---------|-----------|-------------------------------|
| ComfyUI | Pre-built (`yanwk/comfyui-boot`) | ❌ No — just `docker compose pull comfyui` |
| Fooocus | Custom Dockerfile | ✅ Yes |
| Reforge Neo (Forge) | Custom Dockerfile | ✅ Yes |
| InvokeAI | Pre-built (`ghcr.io/invoke-ai/invokeai`) | ❌ No — just `docker compose pull invokeai` |
| AI Toolkit | Custom Dockerfile | ✅ Yes |
| Dockge | Pre-built (`louislam/dockge`) | ❌ No — just `docker compose pull dockge` |

---

## Building Custom Images

Custom images must be built when:
- Setting up the server for the first time
- A Dockerfile has been changed
- You want to update the underlying AI application (e.g., new Fooocus version)

```bash
# SSH into the server
ssh user@192.168.0.10
cd /vol/service/cw/dhoch3-ai-services

# Build all custom images
docker compose build

# Build a specific service
docker compose build fooocus
docker compose build forge
docker compose build ai-toolkit

# Build with no cache (forces a full rebuild — slower but clean)
docker compose build --no-cache forge
```

> ⏱️ **Build times:** First build takes 20–40 minutes per service (downloads PyTorch, CUDA libraries, etc.). Subsequent builds are faster thanks to Docker's layer caching.

---

## Updating Pre-Built Images

For services that use pre-built images (ComfyUI, InvokeAI, Dockge):

```bash
# Pull the latest image
docker compose pull comfyui

# Restart with the new image
docker compose up -d comfyui
```

---

## Updating the Project Code

When changes have been pushed to the Git repository:

```bash
# SSH into the server
ssh user@192.168.0.10
cd /vol/service/cw/dhoch3-ai-services

# Pull latest code
git pull

# If docker-compose.yml changed: restart affected services
docker compose up -d

# If a Dockerfile changed: rebuild and restart
docker compose build forge
docker compose up -d forge
```

---

## Modifying a Dockerfile

The custom Dockerfiles are in the `dockerfiles/` directory:

```
dockerfiles/
├── fooocus/Dockerfile
├── forge/Dockerfile
└── ai-toolkit/Dockerfile
```

### Common Modifications

**Update the AI application to a newer version:**
The Dockerfiles clone from GitHub during build. To get the latest version, rebuild with no cache:
```bash
docker compose build --no-cache fooocus
docker compose up -d fooocus
```

**Change CUDA version:**
Edit the `FROM` line in the Dockerfile:
```dockerfile
# Current (CUDA 12.8 for Blackwell)
FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

# Example: upgrade to a future CUDA version
FROM nvidia/cuda:12.9.0-devel-ubuntu22.04
```

**Add a Python package:**
Add a `RUN pip install <package>` line in the Dockerfile, then rebuild.

### After Modifying a Dockerfile

```bash
# Rebuild the image
docker compose build <service-name>

# Restart with the new image
docker compose up -d <service-name>

# Verify it's running
docker compose ps
docker compose logs -f <service-name>
```

---

## Cleaning Up Old Images

Docker keeps old images around. Over time, this wastes disk space.

```bash
# See how much disk Docker is using
docker system df

# Remove unused images, containers, and build cache
docker system prune -a

# Remove only build cache
docker builder prune -a
```

> ⚠️ `docker system prune -a` removes ALL unused images. Only run this if you're okay with rebuilding custom images afterwards.

---

## Full Update Workflow

Here's the complete process for updating everything:

```bash
# 1. SSH into the server
ssh user@192.168.0.10
cd /vol/service/cw/dhoch3-ai-services

# 2. Pull latest project code
git pull

# 3. Pull latest pre-built images
docker compose pull

# 4. Rebuild custom images (if Dockerfiles changed)
docker compose build

# 5. Restart all services with new images
docker compose up -d

# 6. Verify
docker compose ps
docker compose logs --tail 20
```


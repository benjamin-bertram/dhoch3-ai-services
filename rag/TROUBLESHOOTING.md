# Troubleshooting Guide

## Current Status (2025-12-12)

### ✅ Reforge Neo Deployed

**Change:** Replaced original Forge with Reforge Neo (sd-webui-forge-classic neo branch)

**Improvements:**
- Python 3.11 (specific version required by Reforge Neo)
- `uv` package manager for faster installation
- SageAttention 2 support for better performance
- Lighter weight and more optimized than original Forge
- Better compatibility with RTX 5090

**Repository:** https://github.com/Haoming02/sd-webui-forge-classic (neo branch)

**Status:** ✅ Fixed in commit (pending rebuild)

---

### Issue 2: AI-Toolkit Container Restarting ❌

**Error:**
```
run.py: error: the following arguments are required: config_file_list
```

**Cause:** AI-Toolkit is a training toolkit, not a web service. The default CMD tries to run training without config files.

**Fix:** Changed CMD to keep container running with informative message. Training jobs run via `docker exec`.

**Status:** ✅ Fixed in commit (pending rebuild)

**Usage:**
```bash
# Run training job
docker exec dhoch3-ai-toolkit python run.py /config/my-config.yaml
```

---

### Issue 3: Model Symlinks Not Created ❌

**Error:** `/vol/service/cw/storage-user/models/` directory is empty

**Cause:** Setup script wasn't run or symlinks weren't created

**Fix:** Run `./scripts/fix-deployment.sh` or manually create symlinks:

```bash
cd /vol/service/cw/storage-user/models
ln -s /vol/service/cw/storage-models/models/checkpoints checkpoints
ln -s /vol/service/cw/storage-models/models/loras loras
ln -s /vol/service/cw/storage-models/models/vae vae
# ... etc
```

**Status:** ⚠️ Needs manual fix on server

---

### Issue 4: Containers Not on Traefik Network ❌

**Error:** Domain access doesn't work, only `localhost:port` works

**Cause:** Containers are not connected to the `traefik_default` network

**Fix:** Ensure `.env` file has correct `TRAEFIK_NETWORK` setting:

```bash
# In .env file
TRAEFIK_NETWORK=traefik_default
```

Then restart containers:
```bash
docker compose down
docker compose up -d
```

**Status:** ⚠️ Needs verification on server

---

### Issue 5: FluxGym Running on Wrong Port ⚠️

**Observed:** FluxGym logs show `Running on local URL: http://127.0.0.1:7860`

**Expected:** Should run on `http://0.0.0.0:3000`

**Cause:** Unknown - Dockerfile specifies correct port

**Fix:** Check FluxGym logs after rebuild

**Status:** ⚠️ Needs investigation

---

## Quick Fix Commands

### On Server:

```bash
cd /vol/service/cw/dhoch3-ai-services

# Pull latest changes
git pull

# Make scripts executable
chmod +x scripts/fix-deployment.sh

# Run automated fix
sudo ./scripts/fix-deployment.sh
```

This will:
1. ✅ Create model symlinks
2. ✅ Stop all containers
3. ✅ Rebuild Forge image (fix CUDA library)
4. ✅ Rebuild AI-Toolkit image (fix startup command)
5. ✅ Start all containers
6. ✅ Show status

---

## Manual Verification

After running the fix script, verify:

### 1. Check Container Status
```bash
docker compose ps
```

All containers should show "Up" status (not "Restarting")

### 2. Check Model Symlinks
```bash
ls -la /vol/service/cw/storage-user/models/
```

Should show symlinks like:
```
lrwxrwxrwx checkpoints -> /vol/service/cw/storage-models/models/checkpoints
lrwxrwxrwx loras -> /vol/service/cw/storage-models/models/loras
lrwxrwxrwx vae -> /vol/service/cw/storage-models/models/vae
```

### 3. Check Traefik Network
```bash
docker network inspect traefik_default --format '{{range .Containers}}{{.Name}} {{end}}'
```

Should show all dhoch3 containers

### 4. Test Local Access
```bash
curl http://localhost:8188  # ComfyUI
curl http://localhost:7860  # Fooocus
curl http://localhost:7861  # Forge
curl http://localhost:9090  # InvokeAI
curl http://localhost:3000  # FluxGym
curl http://localhost:5001  # Dockge
```

### 5. Check Logs
```bash
docker compose logs -f forge      # Should not show libcusparseLt error
docker compose logs -f ai-toolkit # Should show "Container will stay running"
docker compose logs -f fooocus    # Should show "App started successful"
```

---

## Common Issues

### Container Keeps Restarting

**Check logs:**
```bash
docker logs dhoch3-[service-name] --tail 50
```

**Common causes:**
- Missing storage directories
- Port already in use
- GPU not accessible
- Missing dependencies

### Can't Access via Domain

**Check:**
1. DNS points to server IP
2. Traefik is running: `docker ps | grep traefik`
3. Containers on traefik network
4. `.env` has correct `DOMAIN` setting

### GPU Not Working

**Test GPU access:**
```bash
docker exec dhoch3-fooocus nvidia-smi
```

Should show GPU information

---

## Traefik Network Issues (Domain Access Not Working)

### Problem
Containers can be accessed via `http://192.168.0.10:port` but NOT via domain names like `comfyui.design-hoch-drei.de`

### Diagnosis

**Check if containers are on traefik network:**
```bash
docker network inspect traefik_default --format '{{range .Containers}}{{.Name}} {{end}}'
```

**If output is empty**, containers are not connected to Traefik!

### Root Causes

1. **Traefik network doesn't exist**
   ```bash
   docker network ls | grep traefik
   ```

   **Fix:**
   ```bash
   docker network create traefik_default
   docker compose down
   docker compose up -d
   ```

2. **Wrong network name in .env**
   ```bash
   grep TRAEFIK_NETWORK .env
   ```

   Should show: `TRAEFIK_NETWORK=traefik_default`

   **Fix:**
   ```bash
   echo "TRAEFIK_NETWORK=traefik_default" >> .env
   docker compose down
   docker compose up -d
   ```

3. **Traefik is not running**
   ```bash
   docker ps | grep traefik
   ```

   If no output, Traefik is not running. This is a separate service that needs to be started.

4. **DNS not pointing to server**
   ```bash
   nslookup comfyui.design-hoch-drei.de
   ```

   Should resolve to your server IP (192.168.0.10)

### Complete Fix for Traefik Network

```bash
# 1. Ensure network exists
docker network create traefik_default 2>/dev/null || echo "Network already exists"

# 2. Update .env
echo "TRAEFIK_NETWORK=traefik_default" >> .env

# 3. Restart containers
docker compose down
docker compose up -d

# 4. Verify containers are on network
docker network inspect traefik_default --format '{{range .Containers}}{{.Name}} {{end}}'
```

**Expected output:** Should list all dhoch3 containers

---

## Getting Help

If issues persist:

1. Run diagnostics:
   ```bash
   ./scripts/diagnose-containers.sh > /tmp/diagnostics.txt
   ```

2. Share the output with support

3. Include:
   - Container logs
   - `docker compose ps` output
   - `.env` file (redact passwords)
   - Traefik network inspection output


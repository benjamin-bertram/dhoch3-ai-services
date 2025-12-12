# Migration from Old ComfyUI Installation

## Overview

You have an existing ComfyUI installation in `/vol/service/cw/ComfyUI-Docker/`. This guide helps you safely migrate to the new dhoch3-ai-services setup.

---

## Port Conflicts

### The Problem

Both installations use the same ports:
- **Old ComfyUI:** Port 8188
- **New ComfyUI:** Port 8188

**You MUST stop the old service before starting the new one.**

---

## Migration Options

### Option 1: Complete Migration (Recommended)

Stop the old ComfyUI and fully migrate to the new setup.

**Advantages:**
- ✅ Clean, unified service management
- ✅ All services in one docker-compose.yml
- ✅ Consistent Traefik integration
- ✅ Better organization

**Steps:**

```bash
# 1. Stop old ComfyUI
cd /vol/service/cw/ComfyUI-Docker
docker compose down

# 2. (Optional) Disable auto-start
# Edit docker-compose.yml and change restart: always to restart: "no"

# 3. Deploy new services
cd /vol/service/cw/dhoch3-ai-services
docker compose up -d
```

---

### Option 2: Run Both (Different Ports)

Keep both installations but use different ports.

**Advantages:**
- ✅ Can test new setup without affecting old one
- ✅ Gradual migration
- ✅ Fallback option

**Steps:**

```bash
# 1. Change new ComfyUI port in .env
echo "COMFYUI_PORT=8189" >> .env

# 2. Update Traefik subdomain to avoid conflicts
echo "COMFYUI_SUBDOMAIN=comfyui-new" >> .env

# 3. Deploy new services
docker compose up -d

# Now you have:
# - Old ComfyUI: http://server:8188 or https://comfyui.design-hoch-drei.de
# - New ComfyUI: http://server:8189 or https://comfyui-new.design-hoch-drei.de
```

---

### Option 3: Disable ComfyUI in New Setup

Use the new setup for other services, keep old ComfyUI.

**Steps:**

```bash
# 1. Edit docker-compose.yml and comment out ComfyUI service
# Or use docker compose profiles

# 2. Deploy only the services you want
docker compose up -d fooocus forge invokeai fluxgym ai-toolkit dockge

# ComfyUI won't be started, no port conflict
```

---

## Recommended Migration Path

### Phase 1: Preparation

```bash
# 1. Backup old ComfyUI data (if needed)
cd /vol/service/cw/ComfyUI-Docker
docker compose exec comfyui tar -czf /backup/comfyui-data.tar.gz /app/ComfyUI

# 2. Note any custom nodes or configurations
docker compose exec comfyui ls -la /app/ComfyUI/custom_nodes

# 3. Document any important workflows
# Copy from old ComfyUI's output directory
```

### Phase 2: Setup New Services

```bash
# 1. Setup storage directories
cd /vol/service/cw/dhoch3-ai-services
sudo ./scripts/setup-storage-directories.sh

# 2. Configure environment
cp .env.example .env
nano .env  # Update all settings

# 3. Build images (don't start yet)
./scripts/build-images.sh
```

### Phase 3: Migration

```bash
# 1. Stop old ComfyUI
cd /vol/service/cw/ComfyUI-Docker
docker compose down

# 2. Start new services
cd /vol/service/cw/dhoch3-ai-services
docker compose up -d

# 3. Verify new ComfyUI is running
docker ps | grep comfyui
curl -I https://comfyui.design-hoch-drei.de

# 4. Test functionality
# Open https://comfyui.design-hoch-drei.de in browser
# Load a workflow and test
```

### Phase 4: Cleanup (Optional)

```bash
# Only after confirming new setup works!

# 1. Remove old ComfyUI containers
cd /vol/service/cw/ComfyUI-Docker
docker compose down -v

# 2. Archive old installation
cd /vol/service/cw
mv ComfyUI-Docker ComfyUI-Docker.backup

# 3. Clean up old images
docker image prune -a
```

---

## Data Migration

### Custom Nodes

If you have custom nodes in the old installation:

```bash
# 1. List custom nodes
docker exec OLD_COMFYUI_CONTAINER ls -la /app/ComfyUI/custom_nodes

# 2. Copy to new installation
# Option A: Copy to storage directory
cp -r /vol/service/cw/storage/ComfyUI/custom_nodes/* \
      /vol/service/cw/storage/ComfyUI-new/custom_nodes/

# Option B: Install via ComfyUI Manager in new installation
# (Recommended - ensures compatibility)
```

### Workflows

```bash
# Old workflows are in old output directory
# Copy to new storage-user directory
cp -r /vol/service/cw/OLD_OUTPUT_PATH/workflows/* \
      /vol/service/cw/storage-user/workflows/
```

### Models

**No migration needed!** Both installations use the same model storage:
- `/vol/service/cw/storage-models/models/`

All models are automatically available in the new installation.

---

## Troubleshooting

### Port Already in Use

**Error:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:8188: bind: address already in use
```

**Solution:**
```bash
# Find what's using port 8188
sudo lsof -i :8188
sudo netstat -tulpn | grep 8188

# Stop the old service
cd /vol/service/cw/ComfyUI-Docker
docker compose down
```

### Old Service Auto-Starts

If the old ComfyUI keeps starting automatically:

```bash
# 1. Check if it's set to auto-restart
cd /vol/service/cw/ComfyUI-Docker
docker compose ps

# 2. Disable auto-restart
docker update --restart=no OLD_COMFYUI_CONTAINER

# Or edit docker-compose.yml
# Change: restart: always
# To:     restart: "no"
```

### Traefik Route Conflict

If both services try to use the same domain:

```bash
# Option 1: Stop old service completely
cd /vol/service/cw/ComfyUI-Docker
docker compose down

# Option 2: Change new service subdomain
# In .env:
COMFYUI_SUBDOMAIN=comfyui-new

# Then restart
docker compose up -d comfyui
```

---

## Rollback Plan

If something goes wrong with the new setup:

```bash
# 1. Stop new services
cd /vol/service/cw/dhoch3-ai-services
docker compose down

# 2. Restart old ComfyUI
cd /vol/service/cw/ComfyUI-Docker
docker compose up -d

# 3. Verify old service is working
curl -I https://comfyui.design-hoch-drei.de
```

---

## Testing Checklist

Before fully migrating, test these in the new installation:

- [ ] ComfyUI web interface loads
- [ ] Models are visible and loadable
- [ ] Can generate images
- [ ] Custom nodes work (if migrated)
- [ ] Workflows load correctly
- [ ] Outputs save to correct directory
- [ ] HTTPS access via Traefik works
- [ ] GPU is detected and used

---

## Quick Command Reference

### Check What's Running

```bash
# List all containers
docker ps -a

# Check port usage
sudo lsof -i :8188
sudo netstat -tulpn | grep 8188

# Check Traefik routes
docker exec traefik_container traefik healthcheck
```

### Stop Old ComfyUI

```bash
cd /vol/service/cw/ComfyUI-Docker
docker compose down
```

### Start New Services

```bash
cd /vol/service/cw/dhoch3-ai-services
docker compose up -d
```

### View Logs

```bash
# New ComfyUI
docker compose logs -f comfyui

# All new services
docker compose logs -f
```

---

## Recommendation

**For production deployment:**

1. ✅ **Stop old ComfyUI** completely
2. ✅ **Deploy all new services** together
3. ✅ **Test thoroughly** before removing old installation
4. ✅ **Keep old installation** as backup for 1-2 weeks
5. ✅ **Remove old installation** after confirming everything works

This gives you a clean migration with a safety net.

---

## Summary

| Scenario | Action | Port | Domain |
|----------|--------|------|--------|
| **Complete Migration** | Stop old, start new | 8188 | comfyui.design-hoch-drei.de |
| **Side-by-side Testing** | Run both | 8188 (old), 8189 (new) | comfyui.design-hoch-drei.de (old), comfyui-new.design-hoch-drei.de (new) |
| **Skip ComfyUI** | Don't deploy ComfyUI | N/A | N/A |

**Recommended:** Complete Migration for production.


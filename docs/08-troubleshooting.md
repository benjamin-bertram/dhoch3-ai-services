# 🐛 Troubleshooting

Common problems and how to fix them.

---

## Service Won't Start

**Check the logs first — they almost always tell you what's wrong:**
```bash
docker compose logs <service-name>
```

### "No GPU detected" or CUDA Errors
```bash
# Verify GPU is visible on the host
nvidia-smi

# Verify GPU is accessible from Docker
docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi

# If Docker can't see the GPU, restart Docker
sudo systemctl restart docker
```

### Container Keeps Restarting
```bash
# Check the last 100 lines of logs
docker compose logs --tail 100 <service-name>

# Common causes:
# - Port conflict: another service is using the same port
# - Out of GPU memory: another service is using all VRAM
# - Corrupted data volume: remove and recreate

# Check if the port is already in use
ss -tlnp | grep <port-number>
```

### Out of GPU Memory
Only one AI service can actively use the GPU at a time for generation. If you get OOM (Out of Memory) errors:
```bash
# Check what's using GPU memory
nvidia-smi

# Stop other services that are using VRAM
docker compose stop <other-service>
```

---

## NAS / SMB Issues

### Generated Images Not Appearing on NAS
```bash
# Check if NAS is mounted
mount | grep nas

# If not mounted:
sudo mount -a

# Check the mount point has content
ls /mnt/nas/storage-user/

# Check the specific output directory
ls /mnt/nas/storage-user/output/Forge/
```

### "Permission denied" Writing to NAS
```bash
# Check permissions on the mount
ls -la /mnt/nas/storage-user/

# Re-mount with correct permissions
sudo umount /mnt/nas
sudo mount -a
```

### NAS Not Reachable
```bash
# Test network connectivity
ping 192.168.0.6

# Test SMB access
smbclient -m SMB3 //192.168.0.6/ki_Daten -U d3kiserver
```

---

## Model Issues

### Models Not Showing in a Service

**ComfyUI:** Models should appear immediately. Click the refresh button in the model dropdown.

**Fooocus / Forge:** Models are symlinked at container startup. Restart the service:
```bash
docker compose restart fooocus
# or
docker compose restart forge
```

**InvokeAI:** Models must be imported through InvokeAI's model manager. Browse to `/shared-models/` inside the UI.

### Model Loading Errors
Usually caused by corrupted or incomplete downloads:
```bash
# Check file size (should be several GB for checkpoints)
ls -lh /vol/service/cw/storage-models/models/checkpoints/

# Re-download if the file is too small
```

---

## AI Toolkit Issues

### "Error saving settings"
The database needs to be initialized after a fresh build:
```bash
docker exec dhoch3-ai-toolkit sh -c "cd /ai-toolkit/ui && npx prisma db push"
```

### Training Fails Immediately
Check that datasets are in the right place:
```bash
# Check inside the container
docker exec dhoch3-ai-toolkit ls -la /ai-toolkit/datasets/
```

---

## Build Failures

### "No space left on device"
```bash
# Check disk space
df -h

# Clean up Docker cache
docker system prune -a
docker builder prune -a
```

### Build Hangs or Takes Forever
```bash
# Cancel with Ctrl+C, then rebuild with no cache
docker compose build --no-cache <service-name>
```

### CUDA / PyTorch Version Mismatch
If you see errors about CUDA or sm_120 not being supported, make sure the Dockerfile uses:
- Base image: `nvidia/cuda:12.8.1-devel-ubuntu22.04` (or newer)
- PyTorch index: `https://download.pytorch.org/whl/cu128`

---

## Traefik / Access Issues

### Can't Access a Service via Browser

1. **Check the service is running:** `docker compose ps`
2. **Check Traefik can see it:** The service must be on the `base` network
3. **Check the Traefik labels** in `docker-compose.yml`
4. **Check DNS:** The subdomain must resolve to the server's IP
5. **Try direct access:** `http://192.168.0.10:<port>` (bypasses Traefik)

### SSL Certificate Issues
Traefik handles SSL certificates. If you see certificate warnings, check the Traefik configuration (separate from this project).

---

## Nuclear Options

When nothing else works:

```bash
# Stop everything and remove containers (keeps data)
docker compose down

# Remove all volumes (⚠️ DELETES service data like ComfyUI custom nodes)
docker compose down -v

# Full cleanup — remove everything Docker-related
docker system prune -a --volumes

# Rebuild and restart from scratch
docker compose build --no-cache
docker compose up -d
```

> ⚠️ `docker compose down -v` removes Docker volumes. This deletes service-specific data (like installed ComfyUI custom nodes or InvokeAI's internal database). Models and user files on the NAS are NOT affected.

---

## Getting Help

1. **Check the logs** — `docker compose logs -f <service-name>`
2. **Check this documentation** — especially [05 — Daily Operations](05-daily-operations.md)
3. **Check the service's GitHub** — see [03 — Services](03-services.md) for links
4. **Contact the system administrator**


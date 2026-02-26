# 🎮 Daily Operations

Common tasks for managing the AI services day-to-day.

> **Tip:** You can also use **Dockge** at [dockge.design-hoch-drei.de](https://dockge.design-hoch-drei.de) to start, stop, and restart services visually — no command line needed!

---

## Connecting to the Server

```bash
ssh user@192.168.0.10
cd /vol/service/cw/dhoch3-ai-services
```

All `docker compose` commands below must be run from this directory.

---

## Checking Service Status

```bash
# See which services are running
docker compose ps

# Example output:
# NAME              STATUS          PORTS
# dhoch3-comfyui    Up 2 hours      8188/tcp
# dhoch3-fooocus    Up 2 hours      7860/tcp
# dhoch3-forge      Up 2 hours      7861/tcp
# ...
```

---

## Starting and Stopping Services

```bash
# Start all services
docker compose up -d

# Stop all services (keeps data intact)
docker compose down

# Restart all services
docker compose restart

# Start a single service
docker compose up -d comfyui

# Stop a single service
docker compose stop forge

# Restart a single service
docker compose restart fooocus
```

> **Important:** `docker compose down` stops containers but does NOT delete your data, models, or images. Those are stored on the NAS and local drives.

---

## Viewing Logs

Logs show you what a service is doing, and are the first place to look when something goes wrong.

```bash
# View logs for all services (live, press Ctrl+C to stop)
docker compose logs -f

# View logs for a specific service
docker compose logs -f comfyui

# View the last 50 lines of logs
docker compose logs --tail 50 forge

# View logs without following (just dump and exit)
docker compose logs fooocus
```

---

## Checking GPU Usage

```bash
# See GPU memory usage and running processes
nvidia-smi

# Watch GPU usage live (updates every second, Ctrl+C to stop)
watch -n 1 nvidia-smi
```

---

## Checking Disk Space

```bash
# Server disk usage
df -h /vol/service/cw/

# NAS usage
df -h /mnt/nas/

# Docker disk usage (images, containers, volumes)
docker system df
```

---

## Accessing a Service's Terminal

Sometimes you need to look inside a running container:

```bash
# Open a shell inside a container
docker exec -it dhoch3-comfyui bash
docker exec -it dhoch3-fooocus bash
docker exec -it dhoch3-forge bash
docker exec -it dhoch3-invokeai bash
docker exec -it dhoch3-ai-toolkit bash

# Run a single command inside a container
docker exec dhoch3-forge ls /app/models/

# Exit the container shell
exit
```

---

## Service Names Reference

Use these names with `docker compose` commands:

| Service | Container Name | Compose Service Name |
|---------|---------------|---------------------|
| ComfyUI | `dhoch3-comfyui` | `comfyui` |
| Fooocus | `dhoch3-fooocus` | `fooocus` |
| Reforge Neo | `dhoch3-forge` | `forge` |
| InvokeAI | `dhoch3-invokeai` | `invokeai` |
| AI Toolkit | `dhoch3-ai-toolkit` | `ai-toolkit` |
| Dockge | `dhoch3-dockge` | `dockge` |

Use the **Compose Service Name** (right column) with `docker compose` commands:
```bash
docker compose restart forge       # ✅ correct
docker compose restart dhoch3-forge  # ❌ wrong
```

Use the **Container Name** (middle column) with `docker exec`:
```bash
docker exec -it dhoch3-forge bash   # ✅ correct
```

---

## Quick Reference Card

| What You Want | Command |
|---------------|---------|
| Start everything | `docker compose up -d` |
| Stop everything | `docker compose down` |
| Restart one service | `docker compose restart <name>` |
| See what's running | `docker compose ps` |
| View logs | `docker compose logs -f <name>` |
| Check GPU | `nvidia-smi` |
| Check disk | `df -h` |
| Go inside a container | `docker exec -it <container-name> bash` |


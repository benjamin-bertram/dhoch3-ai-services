# dhoch3-ai-services

AI image generation and training platform for **Design Hoch Drei**, running six containerized services on a single GPU workstation with shared model storage and NAS-backed user files.

---

## Services

| Service | URL | Purpose |
|---------|-----|---------|
| **ComfyUI** | [comfyui.design-hoch-drei.de](https://comfyui.design-hoch-drei.de) | Node-based AI image generation |
| **Fooocus** | [fooocus.design-hoch-drei.de](https://fooocus.design-hoch-drei.de) | Simple one-click image generation |
| **Reforge Neo** | [forge.design-hoch-drei.de](https://forge.design-hoch-drei.de) | Classic Stable Diffusion interface |
| **InvokeAI** | [invokeai.design-hoch-drei.de](https://invokeai.design-hoch-drei.de) | Professional image generation & editing |
| **AI Toolkit** | [ai-toolkit.design-hoch-drei.de](https://ai-toolkit.design-hoch-drei.de) | LoRA model training (FLUX, SDXL, SD 1.5) |
| **Dockge** | [dockge.design-hoch-drei.de](https://dockge.design-hoch-drei.de) | Visual container management |

## Quick Start

```bash
cd /vol/service/cw/dhoch3-ai-services
docker compose up -d        # Start all services
docker compose ps           # Check status
docker compose logs -f      # View logs
```

## Hardware

- **GPU:** NVIDIA RTX PRO 6000 Blackwell (96 GB VRAM, sm_120)
- **CUDA:** 12.8 (required for Blackwell architecture)
- **Server:** `192.168.0.10` · **NAS:** `192.168.0.6` (`ki_Daten`)

## 📖 Documentation

Full documentation is in the [`docs/`](docs/) folder:

| Document | Contents |
|----------|----------|
| [01 — Overview](docs/01-overview.md) | What this project does, architecture diagram |
| [02 — Architecture](docs/02-architecture.md) | Server structure, networking, storage layout |
| [03 — Services](docs/03-services.md) | Each service explained, GitHub links |
| [04 — Getting Started](docs/04-getting-started.md) | Setting up the server from scratch |
| [05 — Daily Operations](docs/05-daily-operations.md) | Starting, stopping, checking services |
| [06 — Storage & Models](docs/06-storage-and-models.md) | NAS setup, model management |
| [07 — Building & Updating](docs/07-building-and-updating.md) | Rebuilding images, deploying changes |
| [08 — Troubleshooting](docs/08-troubleshooting.md) | Common problems and solutions |

## Project Structure

```
dhoch3-ai-services/
├── docker-compose.yml        # Service orchestration
├── .env                      # Server-specific configuration
├── dockerfiles/              # Custom Dockerfiles
│   ├── fooocus/Dockerfile
│   ├── forge/Dockerfile
│   └── ai-toolkit/Dockerfile
├── docs/                     # Full documentation
└── scripts/                  # Utility scripts
```

---

*Internal project — Design Hoch Drei*

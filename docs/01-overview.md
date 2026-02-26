# 🎨 dhoch3-ai-services — Project Overview

## What Is This?

This project runs **six AI services** on a single powerful server at Design Hoch Drei. It lets designers generate images with AI, train custom models, and manage everything through simple web interfaces — no command line needed for daily use.

All services are accessible through your browser at `https://<service>.design-hoch-drei.de`.

---

## The Services at a Glance

| Service | What It Does | URL |
|---------|-------------|-----|
| **ComfyUI** | Node-based AI image generation (most flexible) | [comfyui.design-hoch-drei.de](https://comfyui.design-hoch-drei.de) |
| **Fooocus** | Simple, one-click AI image generation | [fooocus.design-hoch-drei.de](https://fooocus.design-hoch-drei.de) |
| **Reforge Neo** | Classic Stable Diffusion interface with advanced controls | [forge.design-hoch-drei.de](https://forge.design-hoch-drei.de) |
| **InvokeAI** | Professional AI image generation and editing | [invokeai.design-hoch-drei.de](https://invokeai.design-hoch-drei.de) |
| **AI Toolkit** | Train your own AI models (LoRAs) | [ai-toolkit.design-hoch-drei.de](https://ai-toolkit.design-hoch-drei.de) |
| **Dockge** | Visual management dashboard for all services | [dockge.design-hoch-drei.de](https://dockge.design-hoch-drei.de) |

---

## How It All Fits Together

```
┌─────────────────────────────────────────────────────────────────────┐
│  Your Computer (Browser)                                            │
│  https://comfyui.design-hoch-drei.de                               │
│  https://fooocus.design-hoch-drei.de                               │
│  https://forge.design-hoch-drei.de       ... etc.                  │
└────────────────────────┬────────────────────────────────────────────┘
                         │  HTTPS (encrypted)
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Traefik (Reverse Proxy)                                            │
│  Routes each subdomain to the correct service                      │
└────────────────────────┬────────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
   ┌──────────┐   ┌──────────┐   ┌──────────┐   ... (6 services)
   │ ComfyUI  │   │ Fooocus  │   │  Forge   │
   │ Container│   │ Container│   │ Container│
   └────┬─────┘   └────┬─────┘   └────┬─────┘
        │               │               │
        └───────────────┼───────────────┘
                        ▼
           ┌─────────────────────────┐
           │  Shared Model Storage   │
           │  (Local NVMe — fast)    │
           └─────────────────────────┘
                        │
                        ▼
           ┌─────────────────────────┐
           │  NAS (Network Storage)  │
           │  Outputs, Inputs,       │
           │  Datasets, Workflows    │
           └─────────────────────────┘
```

---

## Key Concepts

### 🐳 Docker Containers
Each AI service runs inside its own isolated "container" — think of it like a virtual computer. If one service crashes, the others keep running. Containers are managed with **Docker Compose**.

### 🗂️ Shared Models
All services share the same AI models (stored on the server's fast local drive). You download a model once, and ComfyUI, Fooocus, Forge, and InvokeAI can all use it.

### 📁 NAS Storage (Network Drive)
Your generated images, input images, training datasets, and workflows are stored on the office NAS. You can access them from any computer via the network share at `\\192.168.0.6\ki_Daten\`.

### 🔀 Traefik (Reverse Proxy)
Traefik is a service that runs separately on the server. It receives all web traffic and directs it to the right AI service based on the subdomain (e.g., `comfyui.` goes to ComfyUI, `forge.` goes to Forge).

---

## Hardware

| Component | Details |
|-----------|---------|
| **GPU** | NVIDIA RTX PRO 6000 Blackwell — 96 GB VRAM |
| **Architecture** | Blackwell (sm_120) — requires CUDA 12.8+ |
| **Server IP** | `192.168.0.10` |
| **NAS IP** | `192.168.0.6` (Share: `ki_Daten`) |
| **Domain** | `design-hoch-drei.de` |

---

## Documentation Index

| Document | Contents |
|----------|----------|
| [02 — Architecture](02-architecture.md) | Server structure, networking, how containers connect |
| [03 — Services](03-services.md) | Detailed info on each service, links to GitHub repos |
| [04 — Getting Started](04-getting-started.md) | How to set up the server from scratch |
| [05 — Daily Operations](05-daily-operations.md) | Starting, stopping, and checking services |
| [06 — Storage & Models](06-storage-and-models.md) | NAS setup, model management, syncing |
| [07 — Building & Updating](07-building-and-updating.md) | How to rebuild images, update services |
| [08 — Troubleshooting](08-troubleshooting.md) | Common problems and how to fix them |


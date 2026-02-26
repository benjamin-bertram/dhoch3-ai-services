# 🧩 Services

Detailed information about each AI service, what it does, and how to use it.

---

## ComfyUI — Node-Based Image Generation

| | |
|---|---|
| **URL** | [comfyui.design-hoch-drei.de](https://comfyui.design-hoch-drei.de) |
| **Port** | 8188 |
| **Image** | `yanwk/comfyui-boot:cu128-megapak` (pre-built) |
| **GitHub** | [github.com/comfyanonymous/ComfyUI](https://github.com/comfyanonymous/ComfyUI) |
| **Docker Image Repo** | [github.com/YanWenKun/ComfyUI-Docker](https://github.com/YanWenKun/ComfyUI-Docker) |

**What it does:** ComfyUI uses a visual node editor where you connect building blocks to create image generation workflows. It's the most flexible tool — you can build complex pipelines, chain models, and automate tasks.

**Best for:** Advanced users who want full control, automation, and custom workflows.

**Models:** Mounted directly at `/root/ComfyUI/models` — all shared models are available immediately.

**Outputs:** Saved to NAS at `storage-user/output/ComfyUI/`.

---

## Fooocus — Simple Image Generation

| | |
|---|---|
| **URL** | [fooocus.design-hoch-drei.de](https://fooocus.design-hoch-drei.de) |
| **Port** | 7860 |
| **Image** | Custom build (`dockerfiles/fooocus/Dockerfile`) |
| **GitHub** | [github.com/lllyasviel/Fooocus](https://github.com/lllyasviel/Fooocus) |

**What it does:** Fooocus is the easiest tool to use. Type a description, click generate, get an image. It handles all the technical details automatically.

**Best for:** Beginners and quick image generation without technical knowledge.

**Models:** Shared models are symlinked from `/shared-models/` into `/app/models/` at container startup. Internal Fooocus models (prompt expansion, inpainting, etc.) are managed separately.

**Outputs:** Saved to NAS at `storage-user/output/Fooocus/`.

---

## Reforge Neo (Forge) — Classic Stable Diffusion Interface

| | |
|---|---|
| **URL** | [forge.design-hoch-drei.de](https://forge.design-hoch-drei.de) |
| **Port** | 7861 |
| **Image** | Custom build (`dockerfiles/forge/Dockerfile`) |
| **GitHub** | [github.com/Haoming02/sd-webui-forge-classic](https://github.com/Haoming02/sd-webui-forge-classic) (neo branch) |

**What it does:** Reforge Neo is a fork of Stable Diffusion WebUI Forge with performance optimizations. It provides the classic Stable Diffusion interface with tabs for txt2img, img2img, and extras. Includes SageAttention 2 for faster generation.

**Best for:** Users familiar with Stable Diffusion WebUI who want a traditional interface with good performance.

**Models:** Shared models are symlinked with name translation (e.g., `checkpoints` → `Stable-diffusion`, `loras` → `Lora`) at container startup.

**Outputs:** Saved to NAS at `storage-user/output/Forge/`.

---

## InvokeAI — Professional Image Generation

| | |
|---|---|
| **URL** | [invokeai.design-hoch-drei.de](https://invokeai.design-hoch-drei.de) |
| **Port** | 9090 |
| **Image** | `ghcr.io/invoke-ai/invokeai:latest` (pre-built) |
| **GitHub** | [github.com/invoke-ai/InvokeAI](https://github.com/invoke-ai/InvokeAI) |

**What it does:** InvokeAI is a professional-grade tool with a clean, modern interface. It supports both a simple generation mode and a node-based canvas for advanced workflows. Good for inpainting and outpainting.

**Best for:** Users who want a polished interface with professional editing features.

**Models:** Shared models are available at `/shared-models/` inside the container. Use InvokeAI's model manager to import models from this path.

**Outputs:** Saved to NAS at `storage-user/output/InvokeAI/`.

---

## AI Toolkit — Model Training

| | |
|---|---|
| **URL** | [ai-toolkit.design-hoch-drei.de](https://ai-toolkit.design-hoch-drei.de) |
| **Port** | 8675 |
| **Image** | Custom build (`dockerfiles/ai-toolkit/Dockerfile`) |
| **GitHub** | [github.com/ostris/ai-toolkit](https://github.com/ostris/ai-toolkit) |

**What it does:** AI Toolkit lets you train custom AI models (LoRAs) on your own images. You can teach the AI to generate specific styles, objects, or people. Supports FLUX.1, SDXL, and SD 1.5 training.

**Best for:** Training custom models on your own data.

**Settings in the UI:**
- **Training Folder Path:** `outputs`
- **Dataset Folder Path:** `datasets`

**Training data:** Place your training images in `\\192.168.0.6\ki_Daten\storage-user\datasets\` on the NAS.

**Outputs:** Training results saved to NAS at `storage-user/output/AIToolkit/`.

> **Note:** After a fresh build, you must initialize the database:
> ```bash
> docker exec dhoch3-ai-toolkit sh -c "cd /ai-toolkit/ui && npx prisma db push"
> ```

---

## Dockge — Container Management UI

| | |
|---|---|
| **URL** | [dockge.design-hoch-drei.de](https://dockge.design-hoch-drei.de) |
| **Port** | 5001 |
| **Image** | `louislam/dockge:latest` (pre-built) |
| **GitHub** | [github.com/louislam/dockge](https://github.com/louislam/dockge) |

**What it does:** Dockge is a visual dashboard for managing Docker containers. You can start, stop, restart, and view logs of all services without using the command line.

**Best for:** Non-technical users who need to manage services visually.

---

## Ollama — LLM Inference (Native)

| | |
|---|---|
| **URL** | `http://192.168.0.10:11434` (API only, no web UI) |
| **Installation** | Native Linux binary (not Docker) |
| **Website** | [ollama.com](https://ollama.com) |
| **GitHub** | [github.com/ollama/ollama](https://github.com/ollama/ollama) |

**What it does:** Ollama runs large language models (LLMs) locally. It provides an API that other applications can use for text generation, chat, and AI-powered features.

**Note:** Ollama runs natively on the server, not in a Docker container. It's accessible from containers via `http://host.docker.internal:11434`.


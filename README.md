# dhoch3-ai-services

Containerized AI/ML service orchestration system running multiple AI image generation, training, and inference applications on a single workstation with centralized model storage and SMB output management.

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/benjamin-bertram/dhoch3.git
cd dhoch3

# 2. Run setup script
./scripts/setup.sh

# 3. Configure environment
cp .env.example .env
nano .env  # Edit with your settings

# 4. Build Docker images
./scripts/build-images.sh

# 5. Start services
docker-compose up -d

# 6. Check status
docker-compose ps
```

## 📋 Table of Contents

- [Overview](#overview)
- [System Requirements](#system-requirements)
- [Services](#services)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Updating](#updating)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)

## 🎯 Overview

This project orchestrates 7 AI/ML services plus a container management UI:

- **ComfyUI** - Node-based AI image generation
- **Fooocus** - Simplified AI image generation
- **Forge** - Stable Diffusion WebUI with optimizations
- **InvokeAI** - Professional AI image generation
- **FluxGym** - Flux LoRA training with low VRAM support
- **AI Toolkit** - AI model training tools
- **Dockge** - Docker Compose management UI
- **Ollama** - LLM inference engine (native installation)

All services share:
- Centralized model storage at `/vol/service/cw/storage-models/models`
- SMB network storage for outputs
- GPU access (NVIDIA RTX Pro 6000)
- Traefik reverse proxy for subdomain routing

## 💻 System Requirements

### Hardware
- **GPU**: NVIDIA RTX Pro 6000 (48GB VRAM) or similar
- **RAM**: 32GB+ recommended
- **Storage**: 500GB+ for models and outputs

### Software
- **OS**: Ubuntu 24.04 LTS (or compatible)
- **Docker**: 20.10+ with BuildKit
- **Docker Compose**: 2.0+
- **NVIDIA Docker Runtime**: For GPU passthrough
- **CUDA Toolkit**: 12.1+
- **Traefik**: Pre-configured reverse proxy

### Network
- Local network access to SMB share
- Domain: `design-hoch-drei.de` (configured in Traefik)

## 🛠️ Services

### AI Image Generation

#### ComfyUI
- **URL**: http://comfyui.design-hoch-drei.de
- **Port**: 8188
- **Purpose**: Node-based workflow for AI image generation
- **Image**: Pre-built (YanWenKun cu128-megapak-pt28)

#### Fooocus
- **URL**: http://fooocus.design-hoch-drei.de
- **Port**: 7860
- **Purpose**: Simplified AI image generation
- **Image**: Local build

#### Forge
- **URL**: http://forge.design-hoch-drei.de
- **Port**: 7861
- **Purpose**: Stable Diffusion WebUI with performance optimizations
- **Image**: Local build

#### InvokeAI
- **URL**: http://invokeai.design-hoch-drei.de
- **Port**: 9090
- **Purpose**: Professional AI image generation and editing
- **Image**: Pre-built (official)

### AI Training

#### FluxGym
- **URL**: http://fluxgym.design-hoch-drei.de
- **Port**: 3000
- **Purpose**: Flux LoRA training with 12GB/16GB/20GB VRAM support
- **Image**: Local build

#### AI Toolkit
- **URL**: http://ai-toolkit.design-hoch-drei.de
- **Port**: 8080
- **Purpose**: AI model training tools
- **Image**: Local build

### Management

#### Dockge
- **URL**: http://dockge.design-hoch-drei.de
- **Port**: 5001
- **Purpose**: Docker Compose stack management UI
- **Image**: Pre-built (official)

### LLM Inference

#### Ollama (Native)
- **URL**: http://localhost:11434
- **Purpose**: LLM inference engine
- **Installation**: Native Linux binary

## 📦 Installation

### Prerequisites

1. **Install Docker and NVIDIA Runtime**:
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

4. **Build Docker Images**:
```bash
./scripts/build-images.sh
```

This builds local images for:
- Fooocus
- Forge
- FluxGym
- AI Toolkit

5. **Start Services**:
```bash
docker-compose up -d
```

6. **Verify Services**:
```bash
docker-compose ps
docker-compose logs -f
```

## ⚙️ Configuration

### Environment Variables

Edit `.env` file with your settings:

```bash
# SMB Storage
SMB_SERVER=192.168.0.6
SMB_SHARE=ki_Daten
SMB_USER=d3kiserver
SMB_PASSWORD=your_password_here

# Model Storage
MODELS_PATH=/vol/service/cw/storage-models/models

# Domain
DOMAIN=design-hoch-drei.de

# GPU
NVIDIA_VISIBLE_DEVICES=all
CUDA_VISIBLE_DEVICES=0
```

### Service-Specific Configuration

Each service can be configured via environment variables in `docker-compose.yml` or through their respective web UIs.

## 🎮 Usage

### Accessing Services

All services are accessible via subdomains:

- ComfyUI: http://comfyui.design-hoch-drei.de
- Fooocus: http://fooocus.design-hoch-drei.de
- Forge: http://forge.design-hoch-drei.de
- InvokeAI: http://invokeai.design-hoch-drei.de
- FluxGym: http://fluxgym.design-hoch-drei.de
- AI Toolkit: http://ai-toolkit.design-hoch-drei.de
- Dockge: http://dockge.design-hoch-drei.de

### Managing Services

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart a specific service
docker-compose restart comfyui

# View logs
docker-compose logs -f [service-name]

# Check status
docker-compose ps
```

### Using Ollama

```bash
# Pull a model
ollama pull llama2

# List models
ollama list

# Run a model
ollama run llama2

# Access from containers
# Ollama is accessible at http://host.docker.internal:11434
```

### Model Storage

All services share the same model storage at `/vol/service/cw/storage-models/models`.

Place your models in the appropriate subdirectories:
- Stable Diffusion checkpoints
- LoRA models
- VAE models
- ControlNet models
- etc.

### Output Storage

Each service has a dedicated SMB folder for outputs:
- `//192.168.0.6/ki_Daten/ComfyUI/`
- `//192.168.0.6/ki_Daten/Fooocus/`
- `//192.168.0.6/ki_Daten/Forge/`
- `//192.168.0.6/ki_Daten/InvokeAI/`
- `//192.168.0.6/ki_Daten/FluxGym/`
- `//192.168.0.6/ki_Daten/AIToolkit/`

## 🔄 Updating

To update the project and rebuild services:

```bash
./scripts/update.sh
```

This script will:
1. Pull latest code from git
2. Create a backup of current state
3. Rebuild Docker images
4. Restart services
5. Verify service health

## 🐛 Troubleshooting

### Services Won't Start

1. **Check Docker is running**:
```bash
docker info
```

2. **Check GPU access**:
```bash
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

3. **Check logs**:
```bash
docker-compose logs [service-name]
```

### SMB Mount Issues

1. **Test SMB connection**:
```bash
smbclient -m SMB3 //192.168.0.6/ki_Daten -U d3kiserver
```

2. **Verify credentials in `.env`**

3. **Check SMB server is accessible**:
```bash
ping 192.168.0.6
```

### GPU Not Detected

1. **Verify NVIDIA drivers**:
```bash
nvidia-smi
```

2. **Check NVIDIA Docker runtime**:
```bash
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

3. **Restart Docker**:
```bash
sudo systemctl restart docker
```

### Port Conflicts

If ports are already in use, edit `.env` and change the port numbers:

```bash
COMFYUI_PORT=8188
FOOOCUS_PORT=7860
# etc.
```

### Build Failures

1. **Clear Docker cache**:
```bash
docker builder prune -a
```

2. **Rebuild with no cache**:
```bash
docker-compose build --no-cache
```

3. **Check disk space**:
```bash
df -h
```

## 📁 Project Structure

```
dhoch3-ai-services/
├── docker-compose.yml          # Main orchestration file
├── .env.example                # Environment template
├── .env                        # Your configuration (git-ignored)
├── .gitignore                  # Git ignore rules
├── README.md                   # This file
├── Initial.md                  # Project brief
├── RESEARCH.md                 # Service research notes
├── dockerfiles/                # Custom Dockerfiles
│   ├── fooocus/
│   │   └── Dockerfile
│   ├── forge/
│   │   └── Dockerfile
│   ├── fluxgym/
│   │   └── Dockerfile
│   └── ai-toolkit/
│       └── Dockerfile
└── scripts/                    # Utility scripts
    ├── build-images.sh         # Build all local images
    ├── setup.sh                # Initial setup
    └── update.sh               # Update and restart
```

## 📝 License

This project is for internal use at Design Hoch Drei.

## 🤝 Contributing

This is an internal project. For changes or improvements, please create a branch and submit a pull request.

## 📞 Support

For issues or questions, please contact the system administrator.

---

**Built with ❤️ for Design Hoch Drei**

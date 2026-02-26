# 🚀 Getting Started

How to set up the AI server from scratch. Follow these steps in order.

---

## Prerequisites

Before starting, make sure you have:

1. **A server** with an NVIDIA GPU (RTX PRO 6000 or similar) running **Ubuntu 24.04 LTS**
2. **SSH access** to the server
3. **A NAS** at `192.168.0.6` with an SMB share called `ki_Daten`
4. **A domain** (`design-hoch-drei.de`) with DNS records pointing subdomains to the server
5. **Traefik** already installed and running on the server (separate setup)

---

## Step 1: Install NVIDIA Drivers and Docker

```bash
# SSH into the server
ssh user@192.168.0.10

# Install NVIDIA drivers (if not already installed)
sudo apt update
sudo apt install -y nvidia-driver-570  # or latest available

# Verify GPU is detected
nvidia-smi

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install NVIDIA Container Toolkit (GPU passthrough for Docker)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify GPU is accessible from Docker
docker run --rm --gpus all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi
```

---

## Step 2: Mount the NAS

```bash
# Install CIFS utilities
sudo apt install -y cifs-utils

# Create mount point
sudo mkdir -p /mnt/nas

# Add to /etc/fstab for automatic mounting at boot
# Replace <password> with the actual SMB password
echo '//192.168.0.6/ki_Daten /mnt/nas cifs credentials=/root/.smbcredentials,uid=1000,gid=1000,file_mode=0777,dir_mode=0777 0 0' | sudo tee -a /etc/fstab

# Create credentials file
sudo bash -c 'cat > /root/.smbcredentials << EOF
username=d3kiserver
password=<password>
EOF'
sudo chmod 600 /root/.smbcredentials

# Mount now
sudo mount -a

# Verify
ls /mnt/nas/storage-user/
```

---

## Step 3: Create Storage Directories

```bash
# Create local model storage
sudo mkdir -p /vol/service/cw/storage-models/models/{checkpoints,loras,vae,controlnet,embeddings,clip,clip_vision,diffusion_models,upscale_models,vae_approx,text_encoders,hypernetworks,configs}

# Create user storage directories on NAS
mkdir -p /mnt/nas/storage-user/{input,output,workflows,datasets}
mkdir -p /mnt/nas/storage-user/output/{ComfyUI,Fooocus,Forge,InvokeAI,AIToolkit}
```

---

## Step 4: Clone the Repository

```bash
cd /vol/service/cw
git clone https://github.com/benjamin-bertram/dhoch3-ai-services.git
cd dhoch3-ai-services
```

---

## Step 5: Configure Environment

```bash
# Create .env from the example (or create manually)
cat > .env << 'EOF'
# Model storage (local NVMe)
MODELS_PATH=/vol/service/cw/storage-models/models

# User storage (NAS mount)
USER_STORAGE_PATH=/mnt/nas/storage-user

# Domain for Traefik routing
DOMAIN=design-hoch-drei.de

# GPU access
NVIDIA_VISIBLE_DEVICES=all
CUDA_VISIBLE_DEVICES=0
EOF
```

---

## Step 6: Build Custom Docker Images

Three services need to be built locally (Fooocus, Forge, AI Toolkit):

```bash
# Build all custom images (this takes 20-40 minutes)
docker compose build

# Or build individually:
docker compose build fooocus
docker compose build forge
docker compose build ai-toolkit
```

---

## Step 7: Start All Services

```bash
# Start everything
docker compose up -d

# Check status
docker compose ps

# Watch logs (Ctrl+C to exit)
docker compose logs -f
```

---

## Step 8: Initialize AI Toolkit Database

After the first start, AI Toolkit needs its database initialized:

```bash
docker exec dhoch3-ai-toolkit sh -c "cd /ai-toolkit/ui && npx prisma db push"
```

---

## Step 9: Verify Everything Works

Open each service in your browser:

1. ✅ [comfyui.design-hoch-drei.de](https://comfyui.design-hoch-drei.de)
2. ✅ [fooocus.design-hoch-drei.de](https://fooocus.design-hoch-drei.de)
3. ✅ [forge.design-hoch-drei.de](https://forge.design-hoch-drei.de)
4. ✅ [invokeai.design-hoch-drei.de](https://invokeai.design-hoch-drei.de)
5. ✅ [ai-toolkit.design-hoch-drei.de](https://ai-toolkit.design-hoch-drei.de)
6. ✅ [dockge.design-hoch-drei.de](https://dockge.design-hoch-drei.de)

Generate a test image in Fooocus (the simplest service) and verify it appears on the NAS at `\\192.168.0.6\ki_Daten\storage-user\output\Fooocus\`.

---

## What's Next?

- **Download AI models** — See [06 — Storage & Models](06-storage-and-models.md)
- **Learn daily operations** — See [05 — Daily Operations](05-daily-operations.md)
- **Something not working?** — See [08 — Troubleshooting](08-troubleshooting.md)


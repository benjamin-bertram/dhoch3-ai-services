# Storage Structure & Model Sharing

## File Server Overview

The file server has a well-organized structure for AI services. This document explains how dhoch3-ai-services integrates with it.

---

## Directory Structure

```
/vol/service/cw/
├── ComfyUI-Docker/          # Previous ComfyUI installation (IGNORE)
├── dhoch3-ai-services/      # This project (code repository)
├── storage/                 # Service-specific data
│   ├── ComfyUI/            # ComfyUI application data
│   └── user-scripts/       # Custom scripts
├── storage-models/          # SHARED MODEL STORAGE (READ-ONLY)
│   ├── hf-hub/             # Hugging Face cache
│   ├── models/             # All AI models (shared across services)
│   │   ├── checkpoints/    # Stable Diffusion checkpoints
│   │   ├── loras/          # LoRA models
│   │   ├── vae/            # VAE models
│   │   ├── controlnet/     # ControlNet models
│   │   ├── diffusion_models/FLUX1/  # Flux models
│   │   ├── text_encoders/  # CLIP, T5, etc.
│   │   └── ...             # Many more model types
│   └── torch-hub/          # PyTorch Hub cache
└── storage-user/            # User data (inputs/outputs/workflows)
    ├── input/              # User input files
    ├── output/             # Generated outputs
    └── workflows/          # Saved workflows
```

---

## Model Storage Strategy

### Shared Models Directory
**Path:** `/vol/service/cw/storage-models/models`

All services share the same model storage to:
- ✅ Save disk space (no duplicate models)
- ✅ Consistent model availability across services
- ✅ Centralized model management
- ✅ Faster deployment (models already downloaded)

**Mount as READ-ONLY** to prevent accidental modifications.

### Model Categories

| Category | Path | Used By |
|----------|------|---------|
| Checkpoints | `models/checkpoints/` | Forge, Fooocus, ComfyUI |
| LoRAs | `models/loras/` | All services |
| VAE | `models/vae/` | All services |
| ControlNet | `models/controlnet/` | Forge, ComfyUI |
| Flux Models | `models/diffusion_models/FLUX1/` | ComfyUI, FluxGym |
| Text Encoders | `models/text_encoders/` | All services |
| CLIP | `models/clip/` | All services |
| Upscalers | `models/upscale_models/` | All services |

---

## Service-Specific Storage

Each service gets its own directory in `storage/` for:
- Application data
- Custom nodes/extensions
- Configuration files
- Temporary files

### Recommended Structure

```
storage/
├── ComfyUI/              # Existing (keep)
├── Fooocus/              # New service data
├── Forge/                # New service data
├── InvokeAI/             # New service data
├── FluxGym/              # New service data
└── AIToolkit/            # New service data
```

---

## Output Storage

User-generated content goes to `storage-user/output/` organized by service:

```
storage-user/
├── input/                # User uploads
│   └── 3d/              # 3D assets
├── output/               # Generated content
│   ├── ComfyUI/         # ComfyUI outputs
│   ├── Fooocus/         # Fooocus outputs
│   ├── Forge/           # Forge outputs
│   ├── InvokeAI/        # InvokeAI outputs
│   ├── FluxGym/         # FluxGym training outputs
│   └── AIToolkit/       # AI Toolkit outputs
└── workflows/            # Saved workflows
```

---

## Docker Volume Mapping

### Production Configuration

```yaml
services:
  forge:
    volumes:
      # Shared models (READ-ONLY)
      - /vol/service/cw/storage-models/models:/models:ro
      
      # Service-specific data
      - /vol/service/cw/storage/Forge:/app/data
      
      # User outputs
      - /vol/service/cw/storage-user/output/Forge:/outputs
      
      # User inputs (optional)
      - /vol/service/cw/storage-user/input:/inputs:ro
```

### Key Points

1. **Models mount as READ-ONLY (`:ro`)**
   - Prevents accidental model deletion
   - Services can't modify shared models
   - Download new models to storage-models manually

2. **Service data is READ-WRITE**
   - Each service has its own directory
   - Can store custom nodes, configs, etc.

3. **Outputs are READ-WRITE**
   - Each service writes to its own output folder
   - Easy to organize and backup

---

## Environment Variables

### .env Configuration

```bash
# Model Storage (shared, read-only)
MODELS_PATH=/vol/service/cw/storage-models/models

# Service Data Storage
STORAGE_PATH=/vol/service/cw/storage

# User Data Storage
USER_STORAGE_PATH=/vol/service/cw/storage-user

# SMB Share (for remote access)
SMB_SERVER=192.168.0.6
SMB_SHARE=ki_Daten
```

---

## SMB/CIFS Mounting

**IMPORTANT:** Docker cannot mount SMB/CIFS shares directly using `//server/share` syntax in volume binds.

### On the Server (Production)
Use **local filesystem paths** with environment variables:

```yaml
volumes:
  # Shared models (READ-ONLY)
  - ${MODELS_PATH:-/vol/service/cw/storage-models/models}:/models:ro

  # User outputs
  - ${USER_STORAGE_PATH:-/vol/service/cw/storage-user}/output/Forge:/outputs

  # User inputs (READ-ONLY)
  - ${USER_STORAGE_PATH:-/vol/service/cw/storage-user}/input:/inputs:ro
```

### For Remote Development
If you need to access the SMB share from a remote machine, you must:

1. **Mount the SMB share to your local filesystem first:**
   ```bash
   # Linux/macOS
   sudo mount -t cifs //192.168.0.6/ki_Daten /mnt/ki_Daten -o username=d3kiserver,password=xxx

   # Windows (PowerShell)
   net use Z: \\192.168.0.6\ki_Daten /user:d3kiserver password
   ```

2. **Then use the local mount point in docker-compose:**
   ```yaml
   volumes:
     # Linux/macOS
     - /mnt/ki_Daten/storage-user/output/Forge:/outputs

     # Windows
     - Z:/storage-user/output/Forge:/outputs
   ```

**Never use `//server/share` syntax directly in Docker volume mounts!**

---

## Model Path Mapping

Different services expect models in different locations. Here's how to map them:

### Forge
```
/models/Stable-diffusion  → storage-models/models/checkpoints
/models/Lora              → storage-models/models/loras
/models/VAE               → storage-models/models/vae
/models/ControlNet        → storage-models/models/controlnet
/models/ESRGAN            → storage-models/models/upscale_models
```

### Fooocus
```
/models/checkpoints       → storage-models/models/checkpoints
/models/loras             → storage-models/models/loras
/models/vae               → storage-models/models/vae
```

### ComfyUI
```
/models/checkpoints       → storage-models/models/checkpoints
/models/loras             → storage-models/models/loras
/models/vae               → storage-models/models/vae
/models/controlnet        → storage-models/models/controlnet
/models/clip              → storage-models/models/clip
/models/diffusion_models  → storage-models/models/diffusion_models
```

---

## Adding New Models

### Why Read-Only?

Models are mounted **read-only inside containers** for safety:
- ✅ Prevents accidental deletion
- ✅ Protects against buggy extensions
- ✅ Ensures consistency across services

**You have full read-write access on the host system!**

### Method 1: Direct Download (Recommended)

```bash
# Navigate to model directory
cd /vol/service/cw/storage-models/models

# Download checkpoint
cd checkpoints
wget https://civitai.com/api/download/models/XXXXX -O model.safetensors

# Download LoRA
cd ../loras
wget https://example.com/lora.safetensors

# Models are immediately available to all services!
```

### Method 2: Helper Script

Use the provided download script:

```bash
# Download a checkpoint
./scripts/download-model.sh checkpoint "https://civitai.com/..." "model.safetensors"

# Download a LoRA
./scripts/download-model.sh lora "https://example.com/lora.safetensors" "my-lora.safetensors"

# Download a VAE
./scripts/download-model.sh vae "https://example.com/vae.safetensors" "vae-ft-mse.safetensors"
```

### Method 3: Drag-and-Drop via SMB (Client-Friendly) ⭐

**For clients without server access:**

A symlink directory is created at `storage-user/models-upload/` that points to the actual model storage.

**Windows:**
```
1. Open File Explorer
2. Navigate to: \\192.168.0.6\ki_Daten\storage-user\models-upload\
3. Drag and drop models into the appropriate folder:
   - checkpoints\
   - loras\
   - vae\
   - controlnet\
   - upscale_models\
```

**macOS:**
```
1. Open Finder
2. Connect to: smb://192.168.0.6/ki_Daten
3. Navigate to: storage-user/models-upload/
4. Drag and drop models
```

**Linux:**
```
1. Open File Manager
2. Connect to: smb://192.168.0.6/ki_Daten
3. Navigate to: storage-user/models-upload/
4. Drag and drop models
```

**See:** `CLIENT-MODEL-UPLOAD-GUIDE.md` for detailed client instructions.

### Method 4: Copy from Local Machine (Advanced)

```bash
# Via SCP
scp model.safetensors user@server:/vol/service/cw/storage-models/models/checkpoints/

# Via SMB direct path (if you know the structure)
\\192.168.0.6\ki_Daten\storage-models\models\checkpoints\
```

### Method 5: Temporary Write Access (Not Recommended)

If you need a service to download models:

```bash
# Edit docker-compose.yml temporarily
# Change: - ${MODELS_PATH}:/models:ro
# To:     - ${MODELS_PATH}:/models

# Restart service
docker compose restart SERVICE_NAME

# Download models via service UI
# Then change back to :ro and restart
```

---

## Best Practices

### 1. Model Management
- ✅ Download models to `storage-models/models/` on the host
- ✅ Use the helper script for easy downloads
- ✅ Organize by model type (checkpoints, loras, etc.)
- ✅ Keep models read-only in containers
- ❌ Don't give services write access unless necessary

### 2. Backups
- ✅ Backup `storage-user/` (user data and outputs)
- ✅ Backup `storage/` (service configurations)
- ⚠️ Models can be re-downloaded (optional backup)

### 3. Permissions
- ✅ Models: Read-only for all services
- ✅ Service data: Read-write for owner service only
- ✅ Outputs: Read-write for owner service

### 4. Disk Space
- Monitor `storage-user/output/` (grows with usage)
- Clean old outputs periodically
- Models are shared (no duplication)

---

## Migration from Old ComfyUI

The old `ComfyUI-Docker/` installation can be ignored. The new setup:

1. ✅ Uses the same model storage (`storage-models/models/`)
2. ✅ Creates new service data in `storage/ComfyUI/`
3. ✅ Writes outputs to `storage-user/output/ComfyUI/`
4. ✅ No conflicts with old installation

---

## Quick Reference

| Purpose | Path | Mount |
|---------|------|-------|
| Shared Models | `/vol/service/cw/storage-models/models` | `:ro` |
| Service Data | `/vol/service/cw/storage/{SERVICE}` | `:rw` |
| User Outputs | `/vol/service/cw/storage-user/output/{SERVICE}` | `:rw` |
| User Inputs | `/vol/service/cw/storage-user/input` | `:ro` |
| Workflows | `/vol/service/cw/storage-user/workflows` | `:rw` |


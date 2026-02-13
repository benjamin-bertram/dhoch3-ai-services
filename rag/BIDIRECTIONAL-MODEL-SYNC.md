# Bidirectional Model Synchronization

## Overview

This setup provides **bidirectional model access** between the server and SMB share, allowing:
- ✅ Clients to upload models via SMB → Models appear on server
- ✅ Services to download models → Models appear on SMB
- ✅ All services share the same models
- ✅ Outputs go directly to SMB for easy client access

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ SMB Share: \\192.168.0.6\ki_Daten\storage-user\            │
│                                                              │
│ ├── models/              ← Symlinks to server storage       │
│ │   ├── checkpoints/    ← Bidirectional access             │
│ │   ├── loras/          ← Bidirectional access             │
│ │   └── vae/            ← Bidirectional access             │
│ │                                                            │
│ ├── output/             ← Direct storage (no symlink)       │
│ │   ├── ComfyUI/                                            │
│ │   ├── Fooocus/                                            │
│ │   └── Forge/                                              │
│ │                                                            │
│ ├── input/              ← Direct storage (no symlink)       │
│ │   └── datasets/                                           │
│ │                                                            │
│ └── workflows/          ← Direct storage (no symlink)       │
└─────────────────────────────────────────────────────────────┘
                           ↕ Symlinks
┌─────────────────────────────────────────────────────────────┐
│ Server: /vol/service/cw/storage-models/models/             │
│                                                              │
│ ├── checkpoints/        ← Real storage location            │
│ ├── loras/              ← Real storage location            │
│ ├── vae/                ← Real storage location            │
│ ├── controlnet/         ← Real storage location            │
│ └── ...                                                      │
└─────────────────────────────────────────────────────────────┘
                           ↓ Mounted in containers
┌─────────────────────────────────────────────────────────────┐
│ Docker Containers (All Services)                            │
│                                                              │
│ /models/                ← Via SMB mount (read-write)        │
│ /outputs/               ← Via SMB mount (read-write)        │
│ /inputs/                ← Via SMB mount (read-only)         │
│ /workflows/             ← Via SMB mount (read-write)        │
└─────────────────────────────────────────────────────────────┘
```

---

## How It Works

### Models (Bidirectional)

**Symlink Structure:**
```bash
# SMB models directory contains symlinks to server storage
/vol/service/cw/storage-user/models/checkpoints → /vol/service/cw/storage-models/models/checkpoints
/vol/service/cw/storage-user/models/loras      → /vol/service/cw/storage-models/models/loras
/vol/service/cw/storage-user/models/vae        → /vol/service/cw/storage-models/models/vae
```

**Client uploads model:**
```
Client → \\192.168.0.6\ki_Daten\storage-user\models\checkpoints\model.safetensors
         ↓ (symlink)
Server → /vol/service/cw/storage-models/models/checkpoints/model.safetensors
         ↓ (mounted via SMB)
Container → /models/checkpoints/model.safetensors
```

**Service downloads model (e.g., ComfyUI Manager):**
```
Container → /models/checkpoints/model.safetensors
            ↓ (mounted via SMB)
Server → /vol/service/cw/storage-models/models/checkpoints/model.safetensors
         ↓ (symlink)
SMB → \\192.168.0.6\ki_Daten\storage-user\models\checkpoints\model.safetensors
```

**Result:** Models uploaded by clients OR downloaded by services are accessible everywhere!

---

### Outputs (Direct to SMB)

**No symlinks needed** - outputs go directly to SMB:

```
Container → /outputs/image.png
            ↓ (SMB mount)
SMB → \\192.168.0.6\ki_Daten\storage-user\output\image.png
```

**Benefits:**
- Clients can immediately download generated images
- No server disk space used
- Easy to browse and organize

---

### Workflows (Direct to SMB)

**No symlinks needed** - workflows stored directly on SMB:

```
Container → /workflows/my-workflow.json
            ↓ (SMB mount)
SMB → \\192.168.0.6\ki_Daten\storage-user\workflows\my-workflow.json
```

**Benefits:**
- Clients can share workflows
- Easy backup and version control
- Accessible from all services

---

### Input (Direct from SMB)

**No symlinks needed** - inputs read directly from SMB:

```
SMB → \\192.168.0.6\ki_Daten\storage-user\input\image.png
      ↓ (SMB mount, read-only)
Container → /inputs/image.png
```

**Benefits:**
- Clients upload source images
- Services can't modify inputs (read-only)
- Shared across all services

---

## Setup

### Step 1: Run Setup Script

```bash
sudo ./scripts/setup-storage-directories.sh
```

**This creates:**
1. Symlinks from SMB `models/` to server `storage-models/models/`
2. Direct directories for `output/`, `input/`, `workflows/`

### Step 2: Verify Symlinks

```bash
# Check symlinks exist
ls -la /vol/service/cw/storage-user/models/

# Expected output:
# lrwxrwxrwx checkpoints -> /vol/service/cw/storage-models/models/checkpoints
# lrwxrwxrwx loras -> /vol/service/cw/storage-models/models/loras
# lrwxrwxrwx vae -> /vol/service/cw/storage-models/models/vae
```

### Step 3: Configure Samba

Ensure Samba follows symlinks:

```bash
sudo nano /etc/samba/smb.conf
```

Add/verify:
```ini
[ki_Daten]
    path = /vol/service/cw
    follow symlinks = yes
    wide links = yes
    unix extensions = no
    read only = no
```

Restart Samba:
```bash
sudo systemctl restart smbd
```

### Step 4: Deploy Services

```bash
docker compose up -d
```

---

## Client Usage

### Upload Models

**Windows:**
```
1. Open: \\192.168.0.6\ki_Daten\storage-user\models\
2. Navigate to appropriate folder (checkpoints, loras, etc.)
3. Drag and drop model files
4. Models immediately available in all services!
```

**macOS:**
```
1. Connect to: smb://192.168.0.6/ki_Daten
2. Navigate to: storage-user/models/
3. Drag and drop model files
```

### Download Generated Images

**Windows:**
```
1. Open: \\192.168.0.6\ki_Daten\storage-user\output\
2. Browse by service (ComfyUI, Fooocus, Forge, etc.)
3. Download images
```

### Share Workflows

**Windows:**
```
1. Open: \\192.168.0.6\ki_Daten\storage-user\workflows\
2. Copy workflow JSON files
3. Share with team
```

---

## Service Usage

### ComfyUI Manager

When you download models via ComfyUI Manager:

1. Models download to `/models/checkpoints/` (inside container)
2. Via SMB mount → `/vol/service/cw/storage-user/models/checkpoints/`
3. Via symlink → `/vol/service/cw/storage-models/models/checkpoints/`
4. Immediately visible on SMB: `\\192.168.0.6\ki_Daten\storage-user\models\checkpoints\`

**All services can use the model immediately!**

### Forge/Fooocus

When generating images:

1. Images save to `/outputs/` (inside container)
2. Via SMB mount → `/vol/service/cw/storage-user/output/`
3. Immediately visible on SMB: `\\192.168.0.6\ki_Daten\storage-user\output\`

**Clients can download immediately!**

---

## Benefits

### ✅ For Clients
- **Easy upload:** Drag-and-drop models via network share
- **Immediate download:** Generated images appear instantly
- **Workflow sharing:** Save and share workflows easily
- **No server access needed:** Everything via SMB

### ✅ For Services
- **Model downloads work:** ComfyUI Manager, etc. can download models
- **Shared models:** All services see the same models
- **Direct output:** No need to copy files to SMB
- **Workflow access:** Load workflows from shared location

### ✅ For Administrators
- **Centralized storage:** Models in one location
- **No duplication:** Symlinks don't copy files
- **Easy backup:** Backup SMB share = backup everything
- **Transparent:** Services don't know about symlinks

---

## Troubleshooting

### Models uploaded to SMB don't appear in services

**Check symlinks:**
```bash
ls -la /vol/service/cw/storage-user/models/
```

**Recreate symlinks:**
```bash
sudo ./scripts/setup-storage-directories.sh
```

### Models downloaded by services don't appear on SMB

**Check Samba config:**
```bash
sudo nano /etc/samba/smb.conf
# Ensure: follow symlinks = yes
sudo systemctl restart smbd
```

### Permission denied

**Fix permissions:**
```bash
sudo chown -R 1000:1000 /vol/service/cw/storage-models/models
sudo chown -R 1000:1000 /vol/service/cw/storage-user
sudo chmod -R 755 /vol/service/cw/storage-models/models
```

---

## Summary

| Directory | Type | Purpose | Client Access |
|-----------|------|---------|---------------|
| `models/` | Symlink | Bidirectional model sync | `\\...\storage-user\models\` |
| `output/` | Direct | Generated images | `\\...\storage-user\output\` |
| `input/` | Direct | Source images/datasets | `\\...\storage-user\input\` |
| `workflows/` | Direct | Workflow files | `\\...\storage-user\workflows\` |

**Key Point:** Only `models/` uses symlinks for bidirectional access. Everything else is direct storage on SMB.


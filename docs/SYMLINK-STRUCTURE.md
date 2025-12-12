# Symlink Structure for Client Model Uploads

## Overview

This document explains how the symlink structure allows clients to easily upload models via SMB without needing direct server access.

---

## The Problem

**Challenge:**
- Model storage is at `/vol/service/cw/storage-models/models/`
- Clients access via SMB: `\\192.168.0.6\ki_Daten\`
- Clients shouldn't navigate complex directory structures
- Need simple drag-and-drop experience

**Solution:**
- Create symlinks in an easy-to-find location
- Symlinks point to actual model storage
- Clients drag-and-drop to symlinks
- Files appear in correct model directories

---

## Directory Structure

```
/vol/service/cw/
│
├── storage-models/              # Actual model storage
│   └── models/
│       ├── checkpoints/         # Real directory
│       ├── loras/               # Real directory
│       ├── vae/                 # Real directory
│       ├── controlnet/          # Real directory
│       └── ...
│
└── storage-user/                # User-accessible storage
    ├── input/
    ├── output/
    ├── workflows/
    └── models-upload/           # Symlink directory (NEW!)
        ├── checkpoints/         # → symlink to storage-models/models/checkpoints/
        ├── loras/               # → symlink to storage-models/models/loras/
        ├── vae/                 # → symlink to storage-models/models/vae/
        ├── controlnet/          # → symlink to storage-models/models/controlnet/
        └── ...
```

---

## How It Works

### 1. Symlinks Created

```bash
# During setup, these symlinks are created:
ln -s /vol/service/cw/storage-models/models/checkpoints \
      /vol/service/cw/storage-user/models-upload/checkpoints

ln -s /vol/service/cw/storage-models/models/loras \
      /vol/service/cw/storage-user/models-upload/loras

# And so on for all model types...
```

### 2. Client Access

**Client navigates to:**
```
\\192.168.0.6\ki_Daten\storage-user\models-upload\
```

**Client sees folders:**
```
checkpoints\
loras\
vae\
controlnet\
upscale_models\
embeddings\
clip\
diffusion_models\
```

### 3. Client Uploads

**Client drags file to:**
```
\\192.168.0.6\ki_Daten\storage-user\models-upload\checkpoints\model.safetensors
```

**File actually goes to:**
```
/vol/service/cw/storage-models/models/checkpoints/model.safetensors
```

**All services see it at:**
```
/models/checkpoints/model.safetensors (inside containers)
```

---

## Visual Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Client Computer (Windows/Mac/Linux)                         │
│                                                              │
│ File Explorer / Finder                                      │
│ \\192.168.0.6\ki_Daten\storage-user\models-upload\         │
│                                                              │
│ [Drag model.safetensors to checkpoints\ folder]            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ SMB Upload
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Server: /vol/service/cw/storage-user/models-upload/        │
│                                                              │
│ checkpoints/ → (symlink)                                    │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Points to
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Server: /vol/service/cw/storage-models/models/             │
│                                                              │
│ checkpoints/                                                │
│   └── model.safetensors ← File actually stored here        │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Mounted as :ro
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Docker Containers (Forge, Fooocus, ComfyUI, etc.)          │
│                                                              │
│ /models/checkpoints/                                        │
│   └── model.safetensors ← Services read from here          │
└─────────────────────────────────────────────────────────────┘
```

---

## Benefits

### ✅ For Clients
- **Simple path:** Just navigate to `storage-user\models-upload\`
- **Familiar interface:** Standard drag-and-drop
- **No server access needed:** Works via SMB only
- **Immediate availability:** Models appear in services instantly
- **Clear organization:** Folders named by model type

### ✅ For Administrators
- **Centralized storage:** Models still in one location
- **No duplication:** Symlinks don't copy files
- **Easy maintenance:** Update symlinks if structure changes
- **Security:** Clients can't access other server directories
- **Audit trail:** All uploads go through SMB (can be logged)

### ✅ For Services
- **Transparent:** Services don't know about symlinks
- **Read-only safety:** Still mounted as `:ro` in containers
- **Shared access:** All services see the same models
- **No changes needed:** Existing volume mounts work as-is

---

## Setup

### Automatic Setup

Run the setup script:

```bash
sudo ./scripts/setup-storage-directories.sh
```

This automatically creates:
1. `/vol/service/cw/storage-user/models-upload/` directory
2. Symlinks to all model type directories
3. Proper permissions

### Manual Setup

If you need to create symlinks manually:

```bash
# Create upload directory
mkdir -p /vol/service/cw/storage-user/models-upload

# Create symlinks
cd /vol/service/cw/storage-user/models-upload

ln -s /vol/service/cw/storage-models/models/checkpoints checkpoints
ln -s /vol/service/cw/storage-models/models/loras loras
ln -s /vol/service/cw/storage-models/models/vae vae
ln -s /vol/service/cw/storage-models/models/controlnet controlnet
ln -s /vol/service/cw/storage-models/models/upscale_models upscale_models
ln -s /vol/service/cw/storage-models/models/embeddings embeddings
ln -s /vol/service/cw/storage-models/models/clip clip
ln -s /vol/service/cw/storage-models/models/diffusion_models diffusion_models

# Set permissions
chown -R 1000:1000 /vol/service/cw/storage-user/models-upload
```

---

## Verification

### Check Symlinks

```bash
# List symlinks
ls -la /vol/service/cw/storage-user/models-upload/

# Expected output:
# lrwxrwxrwx checkpoints -> /vol/service/cw/storage-models/models/checkpoints
# lrwxrwxrwx loras -> /vol/service/cw/storage-models/models/loras
# ...
```

### Test Upload

```bash
# Create test file
echo "test" > /tmp/test.txt

# Copy via symlink
cp /tmp/test.txt /vol/service/cw/storage-user/models-upload/checkpoints/

# Verify it appears in actual location
ls -la /vol/service/cw/storage-models/models/checkpoints/test.txt

# Clean up
rm /vol/service/cw/storage-models/models/checkpoints/test.txt
```

### Test SMB Access

From a client computer:

1. Connect to `\\192.168.0.6\ki_Daten`
2. Navigate to `storage-user\models-upload\`
3. Verify you see all model type folders
4. Try copying a small file
5. Verify it appears in the actual model directory

---

## Troubleshooting

### Symlinks appear as files in Windows

**Cause:** Windows SMB client doesn't follow symlinks by default

**Solution:** Configure Samba to follow symlinks

Edit `/etc/samba/smb.conf`:
```ini
[ki_Daten]
    path = /vol/service/cw
    follow symlinks = yes
    wide links = yes
    unix extensions = no
```

Restart Samba:
```bash
sudo systemctl restart smbd
```

### Permission denied when uploading

**Cause:** Incorrect permissions on symlink target

**Solution:**
```bash
# Fix permissions on actual model directories
sudo chown -R 1000:1000 /vol/service/cw/storage-models/models
sudo chmod -R 755 /vol/service/cw/storage-models/models
```

### Symlink broken

**Cause:** Target directory doesn't exist or was moved

**Solution:**
```bash
# Check if target exists
ls -la /vol/service/cw/storage-models/models/checkpoints

# Recreate symlink if needed
rm /vol/service/cw/storage-user/models-upload/checkpoints
ln -s /vol/service/cw/storage-models/models/checkpoints \
      /vol/service/cw/storage-user/models-upload/checkpoints
```

---

## Security Considerations

### ✅ Safe
- Symlinks only point to model directories
- Clients can't navigate outside `storage-user/`
- Read-only mounts in containers prevent service modifications
- SMB authentication required

### ⚠️ Consider
- Clients can delete models (if SMB permissions allow)
- Clients can overwrite existing models
- No automatic virus scanning on uploads

### 🔒 Recommendations
- Configure SMB with authentication
- Set up file versioning/backups
- Monitor disk space usage
- Implement upload size limits if needed
- Consider read-only SMB share for model downloads

---

## Alternative Approaches

### Option 1: Dedicated Upload Directory (More Secure)

Instead of direct symlinks, use a staging directory:

```bash
# Clients upload to staging
/vol/service/cw/storage-user/models-staging/

# Admin reviews and moves to production
mv /vol/service/cw/storage-user/models-staging/model.safetensors \
   /vol/service/cw/storage-models/models/checkpoints/
```

**Pros:** Admin approval, virus scanning, validation
**Cons:** Manual process, delayed availability

### Option 2: Web Upload Interface

Create a web interface for model uploads:

**Pros:** Better control, validation, progress bars
**Cons:** More complex, requires development

### Option 3: Direct SMB Share (Current Approach)

Use symlinks for direct access:

**Pros:** Simple, immediate, familiar interface
**Cons:** Less control, no validation

---

## Summary

The symlink approach provides:
- ✅ **Easy client access** via familiar SMB interface
- ✅ **Centralized storage** in one location
- ✅ **Immediate availability** to all services
- ✅ **No duplication** of files
- ✅ **Simple maintenance** for administrators

**Recommended for:** Trusted clients, internal networks, ease of use

**See also:**
- `CLIENT-MODEL-UPLOAD-GUIDE.md` - Client instructions
- `STORAGE-STRUCTURE.md` - Overall storage organization


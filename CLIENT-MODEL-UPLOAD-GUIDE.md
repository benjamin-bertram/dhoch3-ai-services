# Client Guide: How to Upload Models

## Overview

This guide shows clients how to easily upload AI models to the server via the network share (SMB).

---

## Quick Start

### Windows

1. **Open File Explorer**
2. **Connect to the server:**
   - Press `Win + R`
   - Type: `\\192.168.0.6\ki_Daten`
   - Press Enter
   - Enter credentials if prompted

3. **Navigate to the upload folder:**
   ```
   \\192.168.0.6\ki_Daten\storage-user\models-upload\
   ```

4. **Drag and drop your model files** into the appropriate folder:
   - `checkpoints\` - For Stable Diffusion checkpoints (.safetensors, .ckpt)
   - `loras\` - For LoRA models (.safetensors)
   - `vae\` - For VAE models (.safetensors, .pt)
   - `controlnet\` - For ControlNet models (.safetensors, .pth)
   - `upscale_models\` - For upscaler models (.pth)
   - `embeddings\` - For textual inversions (.pt, .safetensors)

5. **Done!** Models are immediately available in all AI services.

---

### macOS

1. **Open Finder**
2. **Connect to the server:**
   - Press `Cmd + K`
   - Enter: `smb://192.168.0.6/ki_Daten`
   - Click "Connect"
   - Enter credentials if prompted

3. **Navigate to the upload folder:**
   ```
   ki_Daten/storage-user/models-upload/
   ```

4. **Drag and drop your model files** into the appropriate folder

5. **Done!** Models are immediately available.

---

### Linux

1. **Open File Manager**
2. **Connect to the server:**
   - Press `Ctrl + L` (to show location bar)
   - Enter: `smb://192.168.0.6/ki_Daten`
   - Press Enter
   - Enter credentials if prompted

3. **Navigate to the upload folder:**
   ```
   ki_Daten/storage-user/models-upload/
   ```

4. **Drag and drop your model files** into the appropriate folder

5. **Done!** Models are immediately available.

---

## Folder Structure

```
\\192.168.0.6\ki_Daten\storage-user\models-upload\
├── checkpoints\         ← Stable Diffusion checkpoints
├── loras\              ← LoRA models
├── vae\                ← VAE models
├── controlnet\         ← ControlNet models
├── upscale_models\     ← Upscaler models (ESRGAN, etc.)
├── embeddings\         ← Textual inversions
├── clip\               ← CLIP models
└── diffusion_models\   ← Flux and other diffusion models
    └── FLUX1\          ← Flux models go here
```

---

## Model Types Guide

### Checkpoints (.safetensors, .ckpt)
**What:** Full Stable Diffusion models
**Where:** `checkpoints\`
**Examples:**
- Realistic Vision v5.1
- DreamShaper
- Juggernaut XL
- SD 1.5, SDXL base models

**File size:** Usually 2-7 GB

---

### LoRAs (.safetensors)
**What:** Small add-on models for specific styles/subjects
**Where:** `loras\`
**Examples:**
- Character LoRAs
- Style LoRAs
- Concept LoRAs

**File size:** Usually 10-200 MB

---

### VAE (.safetensors, .pt)
**What:** Improves color and detail in generated images
**Where:** `vae\`
**Examples:**
- vae-ft-mse-840000-ema-pruned
- sdxl.vae

**File size:** Usually 300-800 MB

---

### ControlNet (.safetensors, .pth)
**What:** Control image generation with poses, edges, depth
**Where:** `controlnet\`
**Examples:**
- control_v11p_sd15_canny
- control_v11p_sd15_openpose
- controlnet-canny-sdxl-1.0

**File size:** Usually 700 MB - 2.5 GB

---

### Upscalers (.pth)
**What:** Enhance image resolution
**Where:** `upscale_models\`
**Examples:**
- 4x-UltraSharp
- RealESRGAN_x4plus
- ESRGAN_4x

**File size:** Usually 5-70 MB

---

### Embeddings (.pt, .safetensors)
**What:** Textual inversions for specific concepts
**Where:** `embeddings\`
**Examples:**
- EasyNegative
- BadDream
- UnrealisticDream

**File size:** Usually 10-100 KB

---

## Common Download Sources

### CivitAI (civitai.com)
1. Find the model you want
2. Click "Download" button
3. Save the file to your computer
4. Drag and drop to the appropriate folder on the network share

### HuggingFace (huggingface.co)
1. Navigate to the model repository
2. Click "Files and versions"
3. Download the `.safetensors` file
4. Drag and drop to the appropriate folder

---

## Tips & Best Practices

### ✅ Do's
- **Use .safetensors format** when available (safer than .ckpt)
- **Organize models** by creating subfolders (e.g., `checkpoints\SD1.5\`, `checkpoints\SDXL\`)
- **Use descriptive names** (e.g., `realistic-vision-v5.1.safetensors`)
- **Check file size** before uploading (ensure enough space)
- **Wait for upload to complete** before using the model

### ❌ Don'ts
- **Don't rename files** while they're being used
- **Don't delete models** without checking if they're in use
- **Don't upload to wrong folders** (checkpoints in loras folder, etc.)
- **Don't upload corrupted files** (verify downloads first)

---

## Troubleshooting

### Can't connect to network share

**Windows:**
```
1. Open Command Prompt
2. Type: net use \\192.168.0.6\ki_Daten /user:d3kiserver
3. Enter password when prompted
```

**macOS/Linux:**
- Verify you're on the same network
- Check credentials with IT admin

---

### Upload is very slow

- **Check network connection** (WiFi vs Ethernet)
- **Large files take time** (7GB checkpoint = 5-10 minutes on WiFi)
- **Use Ethernet** for faster uploads if possible

---

### Model doesn't appear in AI service

1. **Wait a moment** - Some services scan for new models periodically
2. **Refresh the service** - Reload the web page
3. **Restart the service** - Contact admin if needed
4. **Check correct folder** - Ensure model is in the right directory

---

### File permission error

- Contact the server administrator
- The admin may need to fix file permissions

---

## Verification

After uploading, verify your model is accessible:

1. **Open any AI service** (ComfyUI, Forge, Fooocus)
2. **Look for your model** in the model selector
3. **Try generating an image** with the new model

If the model appears in the list, it's ready to use!

---

## Support

If you encounter issues:

1. **Check this guide** for troubleshooting steps
2. **Verify file format** (.safetensors is recommended)
3. **Check file size** (ensure it's not corrupted)
4. **Contact the administrator** if problems persist

---

## Quick Reference

| Model Type | Folder | File Extension | Typical Size |
|------------|--------|----------------|--------------|
| Checkpoint | `checkpoints\` | .safetensors, .ckpt | 2-7 GB |
| LoRA | `loras\` | .safetensors | 10-200 MB |
| VAE | `vae\` | .safetensors, .pt | 300-800 MB |
| ControlNet | `controlnet\` | .safetensors, .pth | 700 MB - 2.5 GB |
| Upscaler | `upscale_models\` | .pth | 5-70 MB |
| Embedding | `embeddings\` | .pt, .safetensors | 10-100 KB |

---

## Network Path

**Windows:** `\\192.168.0.6\ki_Daten\storage-user\models-upload\`

**macOS:** `smb://192.168.0.6/ki_Daten/storage-user/models-upload/`

**Linux:** `smb://192.168.0.6/ki_Daten/storage-user/models-upload/`

---

**Happy model uploading!** 🚀


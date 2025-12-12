#!/bin/bash
# Helper script to download models to the correct directory
# Usage: ./download-model.sh <type> <url> <filename>
# Example: ./download-model.sh checkpoint "https://civitai.com/..." "model.safetensors"

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Base path
MODEL_BASE="/vol/service/cw/storage-models/models"

# Show usage
usage() {
    echo -e "${BLUE}Model Download Helper${NC}"
    echo ""
    echo "Usage: $0 <type> <url> <filename>"
    echo ""
    echo "Model Types:"
    echo "  checkpoint, checkpoints     - Stable Diffusion checkpoints"
    echo "  lora, loras                 - LoRA models"
    echo "  vae                         - VAE models"
    echo "  controlnet                  - ControlNet models"
    echo "  upscale, upscaler           - Upscale models"
    echo "  embedding, embeddings       - Textual inversions"
    echo "  clip                        - CLIP models"
    echo "  flux                        - Flux diffusion models"
    echo ""
    echo "Examples:"
    echo "  $0 checkpoint 'https://civitai.com/...' 'sd15-model.safetensors'"
    echo "  $0 lora 'https://example.com/lora.safetensors' 'my-lora.safetensors'"
    echo "  $0 vae 'https://example.com/vae.safetensors' 'vae-ft-mse.safetensors'"
    exit 1
}

# Check arguments
if [ $# -lt 3 ]; then
    usage
fi

MODEL_TYPE="$1"
URL="$2"
FILENAME="$3"

# Map model type to directory
case "$MODEL_TYPE" in
    checkpoint|checkpoints)
        TARGET_DIR="$MODEL_BASE/checkpoints"
        ;;
    lora|loras)
        TARGET_DIR="$MODEL_BASE/loras"
        ;;
    vae)
        TARGET_DIR="$MODEL_BASE/vae"
        ;;
    controlnet)
        TARGET_DIR="$MODEL_BASE/controlnet"
        ;;
    upscale|upscaler|upscale_models)
        TARGET_DIR="$MODEL_BASE/upscale_models"
        ;;
    embedding|embeddings)
        TARGET_DIR="$MODEL_BASE/embeddings"
        ;;
    clip)
        TARGET_DIR="$MODEL_BASE/clip"
        ;;
    flux)
        TARGET_DIR="$MODEL_BASE/diffusion_models/FLUX1"
        ;;
    *)
        echo -e "${RED}Error: Unknown model type '$MODEL_TYPE'${NC}"
        echo ""
        usage
        ;;
esac

# Check if directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Directory doesn't exist: $TARGET_DIR${NC}"
    echo -e "${BLUE}Creating directory...${NC}"
    mkdir -p "$TARGET_DIR"
fi

# Full path
TARGET_PATH="$TARGET_DIR/$FILENAME"

# Check if file already exists
if [ -f "$TARGET_PATH" ]; then
    echo -e "${YELLOW}Warning: File already exists: $TARGET_PATH${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Download
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Downloading Model${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Type:     ${GREEN}$MODEL_TYPE${NC}"
echo -e "Target:   ${GREEN}$TARGET_PATH${NC}"
echo -e "URL:      ${GREEN}$URL${NC}"
echo ""

# Use wget or curl (whichever is available)
if command -v wget &> /dev/null; then
    echo -e "${BLUE}Using wget...${NC}"
    wget -O "$TARGET_PATH" "$URL" --progress=bar:force 2>&1
elif command -v curl &> /dev/null; then
    echo -e "${BLUE}Using curl...${NC}"
    curl -L -o "$TARGET_PATH" "$URL" --progress-bar
else
    echo -e "${RED}Error: Neither wget nor curl is installed${NC}"
    exit 1
fi

# Verify download
if [ -f "$TARGET_PATH" ]; then
    FILE_SIZE=$(du -h "$TARGET_PATH" | cut -f1)
    echo ""
    echo -e "${GREEN}✓ Download complete!${NC}"
    echo -e "File: $TARGET_PATH"
    echo -e "Size: $FILE_SIZE"
    echo ""
    echo -e "${GREEN}Model is now available to all services!${NC}"
else
    echo -e "${RED}✗ Download failed!${NC}"
    exit 1
fi


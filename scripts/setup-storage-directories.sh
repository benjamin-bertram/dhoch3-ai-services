#!/bin/bash
# Setup storage directories on file server for dhoch3-ai-services
# Run this script on the server where /vol/service/cw is mounted

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base paths
BASE_PATH="/vol/service/cw"
STORAGE_PATH="${BASE_PATH}/storage"
USER_STORAGE_PATH="${BASE_PATH}/storage-user"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}dhoch3-ai-services Storage Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if base path exists
if [ ! -d "$BASE_PATH" ]; then
    echo -e "${YELLOW}Warning: Base path $BASE_PATH does not exist!${NC}"
    echo "Please ensure the file server is mounted."
    exit 1
fi

echo -e "${GREEN}✓${NC} Base path exists: $BASE_PATH"
echo ""

# Create service-specific storage directories
echo -e "${BLUE}Creating service storage directories...${NC}"
mkdir -p "${STORAGE_PATH}/ComfyUI"
mkdir -p "${STORAGE_PATH}/Fooocus"
mkdir -p "${STORAGE_PATH}/Forge"
mkdir -p "${STORAGE_PATH}/InvokeAI"
mkdir -p "${STORAGE_PATH}/FluxGym"
mkdir -p "${STORAGE_PATH}/AIToolkit/config"

echo -e "${GREEN}✓${NC} Service storage directories created"
echo ""

# Create user storage directories
echo -e "${BLUE}Creating user storage directories...${NC}"
mkdir -p "${USER_STORAGE_PATH}/input"
mkdir -p "${USER_STORAGE_PATH}/input/3d"
mkdir -p "${USER_STORAGE_PATH}/input/datasets"
mkdir -p "${USER_STORAGE_PATH}/output/ComfyUI"
mkdir -p "${USER_STORAGE_PATH}/output/Fooocus"
mkdir -p "${USER_STORAGE_PATH}/output/Forge"
mkdir -p "${USER_STORAGE_PATH}/output/InvokeAI"
mkdir -p "${USER_STORAGE_PATH}/output/FluxGym"
mkdir -p "${USER_STORAGE_PATH}/output/AIToolkit"
mkdir -p "${USER_STORAGE_PATH}/workflows"

echo -e "${GREEN}✓${NC} User storage directories created"
echo ""

# Set permissions (adjust UID/GID as needed)
echo -e "${BLUE}Setting permissions...${NC}"
# Assuming user ID 1000 and group ID 1000 (adjust if needed)
chown -R 1000:1000 "${STORAGE_PATH}"
chown -R 1000:1000 "${USER_STORAGE_PATH}"

echo -e "${GREEN}✓${NC} Permissions set (UID:1000, GID:1000)"
echo ""

# Create bidirectional symlinks for models
echo -e "${BLUE}Creating bidirectional model symlinks...${NC}"

MODEL_PATH="${BASE_PATH}/storage-models/models"
SMB_MODELS_DIR="${USER_STORAGE_PATH}/models"

# Check if SMB models directory exists
if [ -d "$SMB_MODELS_DIR" ]; then
    echo -e "${GREEN}✓${NC} SMB models directory exists: $SMB_MODELS_DIR"

    # Create symlinks FROM server model storage TO SMB
    # This allows models downloaded on server to appear on SMB
    if [ -d "$MODEL_PATH" ]; then
        echo -e "${BLUE}Creating symlinks from server to SMB...${NC}"

        # For each model type, create symlink if it doesn't exist
        for model_type in checkpoints loras vae controlnet upscale_models embeddings clip diffusion_models text_encoders unet style_models; do
            SERVER_DIR="${MODEL_PATH}/${model_type}"
            SMB_LINK="${SMB_MODELS_DIR}/${model_type}"

            if [ -d "$SERVER_DIR" ]; then
                # Remove existing symlink if it exists
                [ -L "$SMB_LINK" ] && rm "$SMB_LINK"

                # Create symlink from SMB to server
                if [ ! -e "$SMB_LINK" ]; then
                    ln -s "$SERVER_DIR" "$SMB_LINK"
                    echo -e "  ${GREEN}✓${NC} Linked: models/${model_type}"
                fi
            fi
        done

        echo ""
        echo -e "${GREEN}✓${NC} Bidirectional model access configured!"
        echo ""
        echo "Model access:"
        echo "  Server → SMB: Models downloaded on server appear on SMB"
        echo "  SMB → Server: Models uploaded to SMB appear on server"
        echo ""
        echo "SMB path for clients:"
        echo "  \\\\192.168.0.6\\ki_Daten\\storage-user\\models\\"
        echo ""
        echo "Available model folders:"
        echo "  - checkpoints/      (Stable Diffusion checkpoints)"
        echo "  - loras/            (LoRA models)"
        echo "  - vae/              (VAE models)"
        echo "  - controlnet/       (ControlNet models)"
        echo "  - upscale_models/   (Upscalers)"
        echo "  - embeddings/       (Textual inversions)"
        echo "  - clip/             (CLIP models)"
        echo "  - diffusion_models/ (Flux and other diffusion models)"
        echo "  - text_encoders/    (T5, CLIP encoders)"
        echo "  - unet/             (UNet models)"
    else
        echo -e "${YELLOW}Warning: Server model storage not found at $MODEL_PATH${NC}"
    fi
else
    echo -e "${YELLOW}Warning: SMB models directory not found at $SMB_MODELS_DIR${NC}"
    echo "Creating it now..."
    mkdir -p "$SMB_MODELS_DIR"
fi

echo ""

# Display directory structure
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Directory Structure Created:${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Service Storage (${STORAGE_PATH}):"
tree -L 2 -d "${STORAGE_PATH}" 2>/dev/null || ls -la "${STORAGE_PATH}"
echo ""
echo "User Storage (${USER_STORAGE_PATH}):"
tree -L 2 -d "${USER_STORAGE_PATH}" 2>/dev/null || ls -la "${USER_STORAGE_PATH}"
echo ""

# Verify model storage exists
echo -e "${BLUE}Verifying model storage...${NC}"
MODEL_PATH="${BASE_PATH}/storage-models/models"
if [ -d "$MODEL_PATH" ]; then
    echo -e "${GREEN}✓${NC} Model storage exists: $MODEL_PATH"
    echo ""
    echo "Model categories found:"
    ls -1 "$MODEL_PATH" | head -20
else
    echo -e "${YELLOW}Warning: Model storage not found at $MODEL_PATH${NC}"
    echo "Please ensure storage-models/models directory exists."
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Storage setup complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Verify model storage is accessible"
echo "2. Update .env file with correct paths"
echo "3. Deploy services with docker compose"
echo ""
echo "Storage paths to use in .env:"
echo "  MODELS_PATH=${MODEL_PATH}"
echo "  STORAGE_PATH=${STORAGE_PATH}"
echo "  USER_STORAGE_PATH=${USER_STORAGE_PATH}"
echo ""


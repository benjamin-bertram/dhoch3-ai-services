# Stable Diffusion WebUI Reforge Neo Dockerfile
# Optimized for RTX PRO 6000 Blackwell (sm_120, 96GB GDDR7) with CUDA 12.8
# Based on Haoming02/sd-webui-forge-classic (neo branch)

FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

# Build arguments
ARG DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST="12.0" \
    PATH="/root/.local/bin:/usr/local/cuda/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

# Install system dependencies (as per Reforge Neo requirements)
RUN apt-get update && apt-get install -y \
    git \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    build-essential \
    ffmpeg \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Install uv package manager (standalone installer, no pip required)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Set working directory
WORKDIR /app

# Clone Reforge Neo repository
RUN git clone https://github.com/Haoming02/sd-webui-forge-classic sd-webui-forge-neo --branch neo && \
    cd sd-webui-forge-neo && \
    mv * .. && \
    mv .* .. 2>/dev/null || true && \
    cd .. && \
    rm -rf sd-webui-forge-neo

# Create virtual environment using uv
RUN uv venv venv --python 3.11 --seed

# Activate venv and install PyTorch with CUDA 12.8 support (required for Blackwell sm_120)
RUN . venv/bin/activate && \
    uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

# Install other requirements using uv
RUN . venv/bin/activate && \
    uv pip install -r requirements.txt

# Install gradio + packaging (normally installed by prepare_environment, but we pre-install for faster startup)
RUN . venv/bin/activate && \
    uv pip install "gradio==4.40.0" "gradio_rangeslider==0.0.8" "packaging==26.0"

# Pre-install build dependencies for SageAttention + Triton
RUN . venv/bin/activate && \
    uv pip install "triton==3.6.0" setuptools wheel ninja

# Build SageAttention from source (v2.2.0 not on PyPI, must build from GitHub)
# Uses --no-build-isolation so it finds torch/triton already in venv
# TORCH_CUDA_ARCH_LIST="12.0" cross-compiles CUDA kernels for sm_120 (Blackwell) without needing GPU
RUN . venv/bin/activate && \
    git clone https://github.com/thu-ml/SageAttention.git /tmp/SageAttention && \
    cd /tmp/SageAttention && \
    pip install --no-build-isolation . && \
    rm -rf /tmp/SageAttention

# Note: Model directories are created as symlinks in entrypoint (shared-models → Forge naming)
# Output and input directories are provided via docker-compose volume mounts
RUN mkdir -p /outputs /inputs

# Environment variables for Reforge Neo configuration
# NOTE: paths_internal.py reads COMMANDLINE_ARGS and appends to sys.argv automatically
# Do NOT also pass ${COMMANDLINE_ARGS} on the command line or args will be doubled!
# SageAttention is pre-built from source during Docker build (cross-compiled for sm_120)
# prepare_environment() will see is_installed("sageattention") == True and skip re-install
ENV COMMANDLINE_ARGS="--listen --port 7861 --api --skip-python-version-check --skip-torch-cuda-test --skip-version-check --sage --uv" \
    TORCH_INDEX_URL="https://download.pytorch.org/whl/cu128"

# Expose Gradio port
EXPOSE 7861

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:7861/ || exit 1

# Create entrypoint script with model symlink setup
RUN cat << 'ENTRYPOINT_EOF' > /entrypoint.sh
#!/bin/bash
set -e
echo "========================================"
echo "Reforge Neo Starting..."
echo "  GPU: RTX PRO 6000 Blackwell (sm_120)"
echo "========================================"
echo ""

# ── Create symlinks from Forge model names → shared ComfyUI-style model dirs ──
echo "Setting up model symlinks (shared-models → Forge naming)..."
mkdir -p /models
# Forge name            → Shared (ComfyUI) name
ln -sfn /shared-models/checkpoints       /models/Stable-diffusion
ln -sfn /shared-models/vae               /models/VAE
ln -sfn /shared-models/loras             /models/Lora
ln -sfn /shared-models/controlnet        /models/ControlNet
ln -sfn /shared-models/upscale_models    /models/ESRGAN
ln -sfn /shared-models/embeddings        /models/embeddings
# Directories with same name in both systems
ln -sfn /shared-models/clip              /models/clip
ln -sfn /shared-models/clip_vision       /models/clip_vision
ln -sfn /shared-models/diffusion_models  /models/diffusion_models
ln -sfn /shared-models/text_encoders     /models/text_encoders
ln -sfn /shared-models/hypernetworks     /models/hypernetworks
ln -sfn /shared-models/vae_approx        /models/vae_approx
ln -sfn /shared-models/configs           /models/configs
echo "Model symlinks created."
echo ""

echo "Activating virtual environment..."
source /app/venv/bin/activate
echo ""
echo "Python version: $(python --version)"
echo "PyTorch version: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA available: $(python -c 'import torch; print(torch.cuda.is_available())')"
echo "CUDA version: $(python -c 'import torch; print(torch.version.cuda if torch.cuda.is_available() else "N/A")')"
echo "GPU: $(python -c 'import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else "N/A")')"
echo "VRAM: $(python -c 'import torch; print(f"{torch.cuda.get_device_properties(0).total_memory / 1024**3:.0f} GB") if torch.cuda.is_available() else print("N/A")')"
echo ""
echo "Starting Reforge Neo..."
echo ""
python launch.py
ENTRYPOINT_EOF
RUN chmod +x /entrypoint.sh

# Run Reforge Neo
CMD ["/entrypoint.sh"]


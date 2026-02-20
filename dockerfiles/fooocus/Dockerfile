# Fooocus Dockerfile
# Optimized for RTX PRO 6000 Blackwell (sm_120, 96GB GDDR7) with CUDA 12.8

FROM nvidia/cuda:12.8.1-runtime-ubuntu22.04

# Build arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.10

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH="/usr/local/cuda/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python3-pip \
    git \
    wget \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgoogle-perftools-dev \
    pkg-config \
    libcairo2-dev \
    libgirepository1.0-dev \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.10 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1

# Upgrade pip
RUN python3 -m pip install --upgrade pip setuptools wheel

# Set working directory
WORKDIR /app

# Clone Fooocus repository
RUN git clone https://github.com/lllyasviel/Fooocus.git . && \
    git checkout main

# Install PyTorch with CUDA 12.8 support (required for Blackwell sm_120)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

# Install Fooocus dependencies (this will install compatible torchvision/torchaudio if needed)
RUN pip install -r requirements_versions.txt

# Note: Shared models are mounted read-only at /shared-models
# Entrypoint symlinks shared subdirs into /app/models/ while preserving Fooocus-internal dirs

# Expose Gradio port
EXPOSE 7860

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# Create entrypoint script that symlinks shared models → /app/models/ subdirs
# Internal Fooocus dirs (prompt_expansion, inpaint, safety_checker, sam) are NOT symlinked
# so Fooocus can create/download them at runtime
RUN cat << 'ENTRYPOINT_EOF' > /entrypoint.sh
#!/bin/bash
set -e
echo "========================================"
echo "Fooocus Starting..."
echo "  GPU: RTX PRO 6000 Blackwell (sm_120)"
echo "========================================"
echo ""

# ── Symlink shared model dirs into /app/models/ ──
# These are the dirs that come from the shared NVMe model storage
echo "Setting up model symlinks (shared-models → /app/models/)..."
SHARED_DIRS="checkpoints loras embeddings vae vae_approx controlnet clip_vision upscale_models"
for dir in $SHARED_DIRS; do
    if [ -d "/shared-models/$dir" ]; then
        # Remove existing dir/symlink if present, then create symlink
        rm -rf "/app/models/$dir"
        ln -sfn "/shared-models/$dir" "/app/models/$dir"
        echo "  $dir → /shared-models/$dir"
    fi
done
echo "Model symlinks created."
echo ""

# Internal dirs (prompt_expansion, inpaint, safety_checker, sam) are left untouched
# Fooocus will create/download them on first run into /app/models/

echo "Starting Fooocus..."
exec python entry_with_update.py \
     --listen 0.0.0.0 \
     --port 7860 \
     --always-gpu
ENTRYPOINT_EOF
RUN chmod +x /entrypoint.sh

# Run Fooocus via entrypoint
CMD ["/entrypoint.sh"]


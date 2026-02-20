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

# Pre-install build dependencies for SageAttention + Triton (compiled at startup with GPU)
RUN . venv/bin/activate && \
    uv pip install triton setuptools wheel ninja

# Create directories for models and outputs
RUN mkdir -p /models /outputs /inputs

# Create model subdirectories (Reforge Neo structure)
RUN mkdir -p /models/Stable-diffusion \
             /models/VAE \
             /models/Lora \
             /models/ControlNet \
             /models/ESRGAN \
             /models/embeddings

# Environment variables for Reforge Neo configuration
ENV COMMANDLINE_ARGS="--listen --port 7861 --api --skip-prepare-environment --skip-install --skip-python-version-check --skip-torch-cuda-test --skip-version-check --sage --uv"

# Expose Gradio port
EXPOSE 7861

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:7861/ || exit 1

# Create entrypoint script with runtime SageAttention + Triton compilation
RUN echo '#!/bin/bash\n\
set -e\n\
echo "========================================"\n\
echo "Reforge Neo Starting..."\n\
echo "  GPU: RTX PRO 6000 Blackwell (sm_120)"\n\
echo "========================================"\n\
echo ""\n\
echo "Activating virtual environment..."\n\
source /app/venv/bin/activate\n\
echo ""\n\
echo "Python version: $(python --version)"\n\
echo "PyTorch version: $(python -c \"import torch; print(torch.__version__)\")"\n\
echo "CUDA available: $(python -c \"import torch; print(torch.cuda.is_available())\")"\n\
echo "CUDA version: $(python -c \"import torch; print(torch.version.cuda if torch.cuda.is_available() else '\"'\"'N/A'\"'\"')\")"\n\
echo "GPU: $(python -c \"import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else '\"'\"'N/A'\"'\"')\")"\n\
echo ""\n\
\n\
# Build SageAttention at runtime (needs GPU for sm_120 kernel compilation)\n\
SAGE_MARKER="/app/.sage_installed"\n\
if [ ! -f "$SAGE_MARKER" ]; then\n\
  echo "========================================"\n\
  echo "First startup: Building SageAttention for Blackwell..."\n\
  echo "========================================"\n\
  pip install sageattention 2>&1 && touch "$SAGE_MARKER" || echo "WARNING: SageAttention install failed (non-critical)"\n\
  echo ""\n\
fi\n\
\n\
echo "Starting Reforge Neo..."\n\
echo "Command: python launch.py ${COMMANDLINE_ARGS}"\n\
echo ""\n\
python launch.py ${COMMANDLINE_ARGS}\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Run Reforge Neo
CMD ["/entrypoint.sh"]


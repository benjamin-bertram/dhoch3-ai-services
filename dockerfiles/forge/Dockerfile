# Stable Diffusion WebUI Forge Dockerfile
# Optimized for RTX 5090 / RTX Pro 6000 with CUDA 12.4 support

FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

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
    google-perftools \
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

# Clone Forge repository
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git . && \
    git checkout main

# Remove xformers from requirements (incompatible with PyTorch nightly)
# Keep torch lines but we'll override them
RUN sed -i '/^xformers/d' requirements_versions.txt

# Install Forge dependencies first (this will install stable PyTorch)
RUN pip install -r requirements_versions.txt

# Force reinstall PyTorch nightly with CUDA 12.4 support (required for RTX 5090 sm_120)
# This overrides the stable version from requirements_versions.txt
RUN pip install --force-reinstall --no-deps --pre torch --index-url https://download.pytorch.org/whl/nightly/cu124

# Ensure xformers is NOT installed (diffusers might try to install it)
RUN pip uninstall -y xformers || true

# Set environment variable to disable xformers in diffusers
ENV XFORMERS_DISABLED=1

# Create directories for models and outputs
RUN mkdir -p /models /outputs

# Create model subdirectories
RUN mkdir -p /models/Stable-diffusion \
             /models/VAE \
             /models/Lora \
             /models/ControlNet \
             /models/ESRGAN \
             /models/GFPGAN

# Environment variables for Forge configuration
ENV FORGE_MODEL_PATH=/models \
    FORGE_OUTPUT_PATH=/outputs \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    TORCH_ALLOW_TF32_CUBLAS_OVERRIDE=1 \
    COMMANDLINE_ARGS="--listen --port 7861 --api --enable-insecure-extension-access --skip-torch-cuda-test --skip-install"

# Expose Gradio port
EXPOSE 7861

# Patch launch_utils.py to skip CUDA compatibility check for RTX 5090
RUN python3 -c "import re; \
content = open('/app/modules/launch_utils.py', 'r').read(); \
content = re.sub(r'raise RuntimeError\([^)]*Your device does not support[^)]*\)', 'print(\"Warning: CUDA compatibility check skipped for RTX 5090 with PyTorch nightly\")', content, flags=re.DOTALL); \
open('/app/modules/launch_utils.py', 'w').write(content)"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:7861/ || exit 1

# Run Forge
CMD python launch.py ${COMMANDLINE_ARGS}


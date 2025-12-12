# AI Toolkit (Ostris) Dockerfile
# Optimized for RTX Pro 6000 with CUDA 12.1 support
# Training toolkit for AI models

FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

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
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}" \
    HF_HUB_ENABLE_HF_TRANSFER=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
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
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.10 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1

# Upgrade pip
RUN python3 -m pip install --upgrade pip setuptools wheel

# Set working directory
WORKDIR /ai-toolkit

# Clone AI Toolkit repository
RUN git clone https://github.com/ostris/ai-toolkit.git . && \
    git checkout main

# Install PyTorch with CUDA 12.1 support
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install AI Toolkit dependencies
# Note: Some packages are installed from git, so this may take time
RUN pip install -r requirements.txt

# Create directories for models, outputs, and datasets
RUN mkdir -p /models /outputs /datasets /config

# Environment variables for AI Toolkit configuration
ENV AI_TOOLKIT_MODEL_PATH=/models \
    AI_TOOLKIT_OUTPUT_PATH=/outputs \
    AI_TOOLKIT_DATASET_PATH=/datasets \
    AI_TOOLKIT_CONFIG_PATH=/config

# Expose Gradio port (if UI is available)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Default command - can be overridden for training jobs
CMD ["python", "run.py"]


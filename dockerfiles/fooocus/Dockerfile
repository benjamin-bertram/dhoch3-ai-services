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

# Note: Models and outputs directories are provided via docker-compose volume mounts
# Fooocus resolves paths relative to /app/models/ and /app/outputs/ by default

# Expose Gradio port
EXPOSE 7860

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# Run Fooocus
CMD ["python", "entry_with_update.py", \
     "--listen", "0.0.0.0", \
     "--port", "7860", \
     "--always-gpu"]


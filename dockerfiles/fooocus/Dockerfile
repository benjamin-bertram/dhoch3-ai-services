# Fooocus Dockerfile
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

# Install PyTorch nightly with CUDA 12.4 support (required for RTX 5090 sm_120)
RUN pip install --pre torch --index-url https://download.pytorch.org/whl/nightly/cu124

# Install Fooocus dependencies (this will install compatible torchvision/torchaudio if needed)
RUN pip install -r requirements_versions.txt

# Create directories for models and outputs
RUN mkdir -p /models /outputs

# Environment variables for Fooocus configuration
ENV FOOOCUS_MODEL_PATH=/models \
    FOOOCUS_OUTPUT_PATH=/outputs

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


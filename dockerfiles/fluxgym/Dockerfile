# FluxGym Dockerfile
# Optimized for RTX Pro 6000 with CUDA 12.1 support
# Includes Kohya sd-scripts for FLUX LoRA training

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
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

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
WORKDIR /fluxgym

# Clone FluxGym repository
RUN git clone https://github.com/cocktailpeanut/fluxgym.git . && \
    git checkout main

# Clone Kohya sd-scripts (sd3 branch) as subdirectory
RUN git clone -b sd3 https://github.com/kohya-ss/sd-scripts.git sd-scripts

# Install PyTorch Nightly with CUDA 12.1 support
# Using nightly for latest FLUX model support
RUN pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu121

# Install FluxGym dependencies
RUN pip install -r requirements.txt

# Install Kohya sd-scripts dependencies (skip line 49 which references /fluxgym as editable package)
# Use sed to remove line 49 which contains the problematic reference
RUN sed '49d' sd-scripts/requirements.txt > /tmp/sd-scripts-requirements.txt && \
    pip install -r /tmp/sd-scripts-requirements.txt

# Install/upgrade bitsandbytes for quantization support
RUN pip install -U bitsandbytes

# Create directories for models and outputs
RUN mkdir -p /models /outputs /datasets

# Environment variables for FluxGym configuration
ENV FLUXGYM_MODEL_PATH=/models \
    FLUXGYM_OUTPUT_PATH=/outputs \
    FLUXGYM_DATASET_PATH=/datasets

# Expose Gradio port
EXPOSE 3000

# Patch app.py to use port 3000 instead of hardcoded 7860
RUN sed -i 's/server_port=7860/server_port=3000/g' app.py || true
RUN sed -i 's/server_name="127.0.0.1"/server_name="0.0.0.0"/g' app.py || true

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Run FluxGym
CMD ["python", "app.py"]


# AI Toolkit (Ostris) Dockerfile
# Optimized for RTX 5090 / RTX Pro 6000 with CUDA 12.4 support
# Training toolkit for AI models with Web UI

FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

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

# Install system dependencies including Node.js for UI
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
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x (required for UI)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3.10 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1

# Upgrade pip
RUN python3 -m pip install --upgrade pip setuptools wheel

# Set working directory
WORKDIR /ai-toolkit

# Clone AI Toolkit repository
RUN git clone https://github.com/ostris/ai-toolkit.git . && \
    git checkout main && \
    git submodule update --init --recursive

# Install PyTorch with CUDA 12.4 support (for RTX 5090)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Install AI Toolkit dependencies
RUN pip install -r requirements.txt

# Install and build UI
WORKDIR /ai-toolkit/ui
RUN npm install && \
    npm run build

# Back to main directory
WORKDIR /ai-toolkit

# Create directories for models, outputs, and datasets
RUN mkdir -p /models /outputs /datasets /config

# Environment variables for AI Toolkit configuration
ENV AI_TOOLKIT_MODEL_PATH=/models \
    AI_TOOLKIT_OUTPUT_PATH=/outputs \
    AI_TOOLKIT_DATASET_PATH=/datasets \
    AI_TOOLKIT_CONFIG_PATH=/config

# Expose UI port
EXPOSE 8675

# Create entrypoint script that starts the UI
RUN echo '#!/bin/bash\n\
echo "========================================"\n\
echo "AI Toolkit with Web UI"\n\
echo "========================================"\n\
echo ""\n\
echo "Starting Web UI on port 8675..."\n\
echo "Access at: http://localhost:8675"\n\
echo ""\n\
echo "Available directories:"\n\
echo "  /models   - Model storage"\n\
echo "  /outputs  - Training outputs"\n\
echo "  /datasets - Training datasets"\n\
echo "  /config   - Configuration files"\n\
echo ""\n\
echo "========================================"\n\
cd /ai-toolkit/ui\n\
npm run start\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Health check - check if UI is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8675/ || exit 1

# Start the UI
CMD ["/entrypoint.sh"]


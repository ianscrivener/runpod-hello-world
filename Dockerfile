
# Build argument for base image selection
ARG BASE_IMAGE=nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04
# ARG BASE_IMAGE=nvidia/cuda:13.2.1-cudnn-runtime-ubuntu24.04

# Stage 1: Base image with common dependencies
FROM ${BASE_IMAGE} AS base

# Build arguments for this stage with sensible defaults for standalone builds
ARG CUDA_VERSION=12.8

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive

# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1

# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1

# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3-pip \
    git \
    wget \
    curl \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    openssh-server \
    && ln -sf /usr/bin/python3.12 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install uv (latest) using official installer and create isolated venv
RUN wget -qO- https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv \
    && ln -s /root/.local/bin/uvx /usr/local/bin/uvx \
    && uv venv /opt/venv

# Use the virtual environment for all subsequent commands
ENV PATH="/opt/venv/bin:${PATH}"

# the workspace venv
RUN uv pip install pip 

# Go back to the root
WORKDIR /app

# Install Python runtime dependencies for the handler
RUN uv pip install runpod requests websocket-client

# Install MLX and verify installation
RUN uv pip install --no-cache "mlx[cuda]==0.32.0" \
    && python -c 'import mlx.core as mx; print("MLX:", mx.__version__)'

# Install mflux and verify installation    
RUN uv pip install --no-cache \
    "mflux @ git+https://github.com/mflux-community/mflux.git@main" \
    && python -c \
    'from importlib.metadata import version; print("mflux:", version("mflux"))'


# Copy your handler code
COPY handler.py .

# Command to run when the container starts
CMD [ "python", "-u", "handler.py" ]


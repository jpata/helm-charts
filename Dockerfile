# Dockerfile

# 1. Start from an official NVIDIA CUDA base image
# Choose a CUDA version compatible with your host drivers and application needs.
# Check NVIDIA Docker Hub for available tags: https://hub.docker.com/r/nvidia/cuda
ARG CUDA_VERSION="12.7.0"
ARG CUDA_DISTRO="ubuntu22.04"
FROM nvidia/cuda:${CUDA_VERSION}-devel-${CUDA_DISTRO}

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install essential dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    jq \
    sudo \
    ca-certificates \
    gnupg \
    # Add any other tools your workflows or runner might need
    # Example: Python, build tools
    python3 \
    python3-pip \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# 3. Install GitHub Actions Runner
# Create a non-root user for the runner
ARG RUNNER_USER="runner"
ARG RUNNER_UID="1001"
ARG RUNNER_GID=${RUNNER_UID}
RUN groupadd -g ${RUNNER_GID} ${RUNNER_USER} \
    && useradd -u ${RUNNER_UID} -g ${RUNNER_GID} -m -s /bin/bash ${RUNNER_USER} \
    && echo "${RUNNER_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${RUNNER_USER}
WORKDIR /home/${RUNNER_USER}

# Download and install the runner
RUN curl -o actions-runner-linux.tar.gz -L https://github.com/actions/runner/releases/download/v2.323.0/actions-runner-linux-x64-2.323.0.tar.gz \
    && tar xzf ./actions-runner-linux.tar.gz \
    && rm ./actions-runner-linux.tar.gz

# The runner software includes dependencies needed for various OS capabilities.
# If you need to install them manually (e.g. for very minimal base images without sudo):
# RUN sudo ./bin/installdependencies.sh # Usually not needed if base image is reasonably complete

# 4. (Optional) Install other CUDA-related libraries if not in the base devel image
# e.g., cuDNN, NCCL - many devel images from NVIDIA already include these.
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     libcudnn8 \
#     libnccl2 \
#  && rm -rf /var/lib/apt/lists/*

# 5. (Optional) Pre-install common tools for your workflows
# RUN pip3 install numpy pandas tensorflow # Example for Python

# Set environment variables for CUDA (often inherited from nvidia/cuda base, but good to be aware)
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

# Cleanup apt cache if you installed more packages as root before switching user
# USER root
# RUN rm -rf /var/lib/apt/lists/*
# USER ${RUNNER_USER}

WORKDIR /home/${RUNNER_USER}
# The entrypoint for the runner pod will typically be managed by actions-runner-controller,
# which will invoke /home/runner/run.sh or similar.

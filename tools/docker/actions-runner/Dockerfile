# Start from the official ARC runner base
FROM ghcr.io/actions/actions-runner:latest

# Switch to root to install packages
USER root

# Install predefined packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Switch back to the non-root 'runner' user
USER runner

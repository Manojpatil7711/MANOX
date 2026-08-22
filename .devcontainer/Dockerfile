FROM cirrusci/flutter:stable

# Install common utilities
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    git \
    wget \
    unzip \
    xz-utils \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Set working directory consistent with devcontainer
WORKDIR /workspaces/MANOX

# Ensure flutter is on PATH (cirrusci image already sets this)
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Cache pub packages between rebuilds
RUN flutter --version || true

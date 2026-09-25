ARG REPO_OWNER=eddict
ARG OS=noble
ARG BASE_IMAGE=ghcr.io/${REPO_OWNER}/eddictwareelec:${OS}
FROM ${BASE_IMAGE} AS builder

# Copy repo into the image so the project's build scripts can run
COPY . /src
#RUN sudo chown -R docker:docker /src
WORKDIR /src

ENV DEBIAN_FRONTEND=noninteractive

# Add build arguments for EE variables
ARG DISTRO=EddictwareELEC
ARG PROJECT=RPi
ARG DEVICE=RPi4
ARG ARCH=aarch64
ARG DIAG_OUTPUT=false
ARG SRC_DIR=/src
ARG BUILD_DIR=/opt/tmp/prebuild
ARG PREBUILD_TC_DIR=/opt/prebuilt-toolchain
ENV SRC_DIR=${SRC_DIR}
ENV BUILD_DIR=${BUILD_DIR}
ENV PREBUILD_TC_DIR=${PREBUILD_TC_DIR}

# Set the default shell for all subsequent RUN commands to Bash
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

USER root
RUN mkdir -p $SRC_DIR $BUILD_DIR $PREBUILD_TC_DIR && \
    chown -R docker:docker $SRC_DIR $BUILD_DIR $PREBUILD_TC_DIR && \
    ls -al /src/tools/download-tool

USER docker

# RUN export DISTRO="$DISTRO" PROJECT="$PROJECT" DEVICE="$DEVICE" ARCH="$ARCH"; \
#     echo "Downloading sources for Distro: $DISTRO, Project: $PROJECT, Device: $DEVICE, Arch: $ARCH"; \
#     export BUILD_DIR="$BUILD_DIR"; \
#     # pre-fetch the source packages
#     # /src/tools/download-tool > "$BUILD_DIR/download-tool.log" 2>&1; \
#     /src/tools/download-tool 2>&1 | tee "$BUILD_DIR/download-tool.log"; \
#     echo "--- DIAGNOSTIC: $BUILD_DIR/download-tool.log ---"; \
#     cat "$BUILD_DIR/download-tool.log" || true;

RUN echo "Building for Distro: $DISTRO, Project: $PROJECT, Device: $DEVICE, Arch: $ARCH"; \
    # sudo chmod u=rwx,g=rwxs,o=rx "$BUILD_DIR"; \
    export BUILD_DIR="$BUILD_DIR"; \
    # export PKG_MAKE_OPTS_HOST="-j$(nproc) -l$(nproc)"; \
    export PKG_MAKE_OPTS_HOST="--silent --jobs=$(nproc)"; \
    echo "PKG_MAKE_OPTS_HOST=$PKG_MAKE_OPTS_HOST"; \
    for pkg in \
        make:host \
        pkg-config:host gettext:host xxHash:host \
        cmake:host \
        zstd:host rpi-eeprom:host \
        toolchain:host \
        linux:host \
        mesa:host; \
    do \
        log="$BUILD_DIR/${pkg//:/-}.log"; \
        if ! /src/scripts/build "$pkg" >"$log" 2>&1; then \
            echo "Build failed: $pkg"; \
            tail -n 200 "$log"; \
            exit 0; \
        fi; \
    done; \
    # Diagnostic: show contents of $BUILD_DIR and $BUILD_DIR/toolchain after build
    echo "--- DIAGNOSTIC: $BUILD_DIR ---"; \
    ls -l "$BUILD_DIR" || true; \
    echo "--- DIAGNOSTIC: $BUILD_DIR/toolchain ---"; \
    ls -l "$BUILD_DIR/toolchain" || true; \
    # Copy the first found toolchain dir as /opt/prebuilt-toolchain/toolchain (flat, predictable path)
    tcdir=$(find "$BUILD_DIR" -type d -name 'toolchain' | head -n1); \
    if [ -n "$tcdir" ]; then \
      cp -a "$tcdir" "$PREBUILD_TC_DIR/toolchain"; \
    fi; \
    # Diagnostic: confirm /opt/prebuilt-toolchain presence and permissions
    echo "--- DIAGNOSTIC: $PREBUILD_TC_DIR ---"; \
    ls -l "$PREBUILD_TC_DIR" || true; \
    find "$PREBUILD_TC_DIR" -type f | xargs ls -l || true; \
    stat "$PREBUILD_TC_DIR" || true

FROM ${BASE_IMAGE}
ARG BUILD_DIR=/opt/tmp/prebuild
ARG PREBUILD_TC_DIR=/opt/prebuilt-toolchain

COPY --from=builder $PREBUILD_TC_DIR $PREBUILD_TC_DIR
LABEL org.opencontainers.image.title="EddictwareELEC prebuilt toolchain" \
      org.opencontainers.image.description="Prebuilt host-toolchain trees for EddictwareELEC builds (placed in /opt/prebuilt-toolchain)."

# Default entrypoint is inherited from base image; this image's job is to provide /opt/prebuilt-toolchain

FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install -y locales sudo

RUN locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN useradd docker -U -G sudo -m -s /bin/bash \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN apt-get update \
 && apt-get install -y \
    cmake curl bash bc gcc-14 cpp-14 sed patch patchutils tar bzip2 gzip xz-utils zstd perl gawk gperf zip \
      unzip diffutils lzop make file g++-14 xfonts-utils xsltproc default-jre-headless python3 \
      libxxhash-dev \
      libzstd-dev \
      pkgconf pkg-config autoconf automake libtool m4 \
      ccache \
      zlib1g-dev \
      libc6-dev libncurses5-dev libjson-perl libxml-parser-perl libparse-yapp-perl rdfind \
      golang-1.23-go git openssh-client rsync upx-ucl nodejs npm \
    --no-install-recommends \
    && ln -s /usr/lib/go-1.23 /usr/lib/go \
    && ln -s /usr/lib/go-1.23/bin/go /usr/bin/go \
    && ln -s /usr/lib/go-1.23/bin/gofmt /usr/bin/gofmt

RUN if [ "$(uname -m)" = "aarch64" ]; then \
  apt-get install -y libc6-amd64-cross qemu-user-binfmt --no-install-recommends; \
 fi

RUN rm -rf /var/lib/apt/lists/*

# Attempt to install libfmt runtime/dev packages so host-built ccache can load libfmt.so
# Use a tolerant install so the build doesn't fail on bases that lack the exact package name.
RUN apt-get update \
 && { apt-get install -y libfmt-dev libfmt1 --no-install-recommends || true; } \
 && rm -rf /var/lib/apt/lists/*

RUN rm -f /usr/bin/cpp /etc/alternatives/cpp || true && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 \
      --slave /usr/bin/g++ g++ /usr/bin/g++-14 \
      --slave /usr/bin/gcov gcov /usr/bin/gcov-14 && \
    update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-14 100 || true
RUN update-alternatives --config gcc || true

USER docker

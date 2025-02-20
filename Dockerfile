# syntax=docker/dockerfile:1
FROM ubuntu:24.10 AS base

WORKDIR /freesmlauncher

#############
### Setup ###
#############

FROM base AS setup

WORKDIR /freesmlauncher

# Install ccache
RUN \
  apt-get update && apt-get install -y \
  ccache && \
  rm -rf /var/lib/apt/lists

# Install boost
RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update && apt-get install -y libboost-dev

##############
### Locale ###
##############

FROM setup AS locale

WORKDIR /freesmlauncher

# setup locales
RUN apt update && \
  apt install -y locales && \
  sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 C.UTF-8/' /etc/locale.gen && \
  locale-gen

ENV LANGUAGE=C.UTF-8
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

#############
### Cache ###
#############

FROM locale AS cache
WORKDIR /freesmlauncher

# Mount ccache cache
RUN --mount=type=cache,target=/root/.ccache
ENV CCACHE_DIR=/ccache

###################
### Environment ###
###################

FROM cache AS environment

WORKDIR /freesmlauncher

# Install dependencies for FreesmLauncher
#
# 1. Update the package index
# 2. Install dependencies
# 3. Clean up
RUN \
  apt-get update && apt-get install -y \
  zlib1g \
  libtomlplusplus-dev \
  libxkbcommon-dev \
  libxkbcommon-x11-dev \
  libqt6widgets6 \
  libqt6xml6 \
  libqt6concurrent6 \
  qt6-networkauth-dev \
  qt6-svg-dev \
  qt6-base-dev \
  qt6-5compat-dev \
  libquazip1-qt6-1 \
  libbz2-1.0 \
  libcmark-dev \
  cmark \
  libqt6network6 \
  libqt6core5compat6 \
  libqt6gui6 \
  libglx0 \
  libopengl0 \
  libqt6core6 \
  libstdc++6 \
  libgcc-s1 \
  libc6 \
  libxkbcommon0 \
  libgssapi-krb5-2 \
  libbrotli1 \
  libzstd1 \
  libghc-resolv-dev \
  libproxy1v5 \
  libglib2.0-0 \
  libssl3 \
  libcrypto++-dev \
  libicu74 \
  libegl1 \
  libfontconfig1 \
  libx11-6 \
  libqt6dbus6 \
  libpng16-16 \
  libharfbuzz0b \
  libmd4c0 \
  libfreetype6 \
  libgthread-2.0-0 \
  libxext6 \
  libsystemd0 \
  libdouble-conversion3 \
  libb2-1 \
  libpcre2-16-0 \
  libkrb5-3 \
  libk5crypto3 \
  libcom-err2 \
  libkrb5support0 \
  libkeyutils1 \
  libbrotli-dev \
  libffi8 \
  libpcre2-8-0 \
  libpthread-stubs0-dev \
  libexpat1 \
  libxcb1 \
  libdbus-1-3 \
  libgraphite2-3 \
  libcap2 \
  libgomp1 \
  libcurl4 \
  libgio-2.0-0 \
  libduktape207 \
  libxau6 \
  libxdmcp6 \
  libnghttp2-14 \
  libidn2-0 \
  libssh2-1 \
  libpsl5 \
  libgmodule-2.0-0 \
  libmount1 \
  libselinux1 \
  libunistring-dev \
  libopenal-dev \
  libblkid1 \
  openjdk-17-jdk \
  openjdk-17-jre \
  cmake \
  extra-cmake-modules \
  build-essential && \
  rm -rf /var/lib/apt/lists/*

###############
### Prepare ###
###############

FROM environment AS prepare

WORKDIR /freesmlauncher

# Copy sources
COPY . /freesmlauncher

# Mk build directory
RUN mkdir -p /freesmlauncher/build

# Update ld
RUN ldconfig

#############
### Build ###
#############

FROM prepare AS build

WORKDIR /freesmlauncher

# Configure
RUN cmake . -DLauncher_BUILD_PLATFORM="docker" -DLauncher_QT_VERSION_MAJOR="6" -Bbuild -S.

# Build
RUN cmake --build build

###########
### Run ###
###########

FROM ubuntu:24.10 AS run

WORKDIR /freesmlauncher

# Install dependencies
RUN apt-get update && apt-get install -y \
  openjdk-17-jre \
  qt6-networkauth-dev \
  libgl1 qt6-base-dev \
  qt6-5compat-dev \
  qt6-svg-dev \
  zlib1g \
  hicolor-icon-theme \
  libquazip1-qt6-dev \
  libtomlplusplus-dev \
  libcmark-dev && \
  rm -rf /var/lib/apt/lists/*

# Copy binary
COPY --from=build /freesmlauncher/build/freesmlauncher /usr/bin/freesmlauncher

# Update ld
RUN ldconfig

# Run
CMD ["freesmlauncher"]
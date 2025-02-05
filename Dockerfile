FROM ubuntu:24.10 AS base

WORKDIR /freesmlauncher

#############
### Setup ###
#############

# Install ccache
RUN \
  apt-get update && apt-get install -y \
  ccache && \
  rm -rf /var/lib/apt/lists

# Install boost
RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update && apt-get install -y libboost-dev

#############
### Cache ###
#############

# Mount ccache cache
RUN --mount=type=cache,target=/root/.ccache

#################
### Build env ###
#################

# Install dependencies for FreesmLauncher
#
# 1. Update the package index
# 2. Install build dependencies
# 3. Install optional dependencies
# 4. Clean up
RUN \
  apt-get update && apt-get install -y \
  cmake extra-cmake-modules git openjdk-17-jdk scdoc gamemode-dev build-essential cmark \
  libglfw3 libopenal1 visualvm x11-xserver-utils openjdk-8-jre flite && \
  rm -rf /var/lib/apt/lists

# Install main deps
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

###############
### Prepare ###
###############

# Copy sources
COPY . /freesmlauncher

# Mk build directory
RUN mkdir -p /freesmlauncher/build

#############
### Build ###
#############

# Configure
RUN cmake . -DLauncher_BUILD_PLATFORM="docker" -DLauncher_QT_VERSION_MAJOR="6" -Bbuild -S.

# Build
RUN cmake --build build

###########
### Run ###
###########

FROM ubuntu:24.10

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
COPY --from=base /freesmlauncher/build/freesmlauncher /usr/bin/freesmlauncher

# Update ld
RUN ldconfig

# Environment variables
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Run
CMD ["freesmlauncher"]
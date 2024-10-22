# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# =================================
# Purpose
# =================================
#
# The purpose of this Dockerfile is to
# - build a debian package for google-cloud-cpp
# - install the package
# - verify the package works
#
# =================================
# Usage
# =================================
#
# Build the image:
#
# ```
# docker build -t package-builder .
# ```

# =================================
# Base Image
# =================================

# The debian workflow is to develop in unstable (sid) then move packages to
# testing (trixie) then into stable (bookworm). The stable branch does not have
# a package for crc32c. The testing and unstable branches have an Abseil that
# incorporates crc32c. So let's use the testing branch.
FROM debian:trixie

# =================================
# Install the minimal development tools.
# TODO : this could likely be more minimal. Not worth doing now.
# =================================
RUN apt-get update && \
    apt-get --no-install-recommends install -y apt-transport-https apt-utils \
        automake build-essential ca-certificates cmake curl debhelper-compat \
        g++ gcc git m4 make ninja-build pkgconf tar wget zlib1g-dev

# =================================
# Install the development packages for direct `google-cloud-cpp` dependencies:
# =================================
RUN apt-get update && \
    apt-get --no-install-recommends install -y \
        libabsl-dev \
        libprotobuf-dev protobuf-compiler \
        libgrpc++-dev libgrpc-dev protobuf-compiler-grpc \
        libcurl4-openssl-dev libssl-dev nlohmann-json3-dev

# =================================
# Fetch google-cloud-cpp
# =================================
WORKDIR /var/tmp/build/google-cloud-cpp
ARG VERSION=2.25.0

# Note that we use a patched branch of google-cloud-cpp. Ideally we would have
# the patches in this workspace and apply them. But I do not have time for that.
# And I don't want to use sed either.

#RUN curl -fsSL https://github.com/googleapis/google-cloud-cpp/archive/v${VERSION}.tar.gz | \
RUN curl -fsSL https://github.com/dbolduc/google-cloud-cpp/archive/refs/heads/v${VERSION}-patched-for-deb-package.tar.gz | \
    tar -xzf - --strip-components=1

# =================================
# Add debian specific files (control, rules, etc.)
# =================================
RUN mkdir debian
COPY debian debian/

# =================================
# Build the package
# =================================
RUN dpkg-buildpackage

# =================================
# Install the package
# =================================
WORKDIR /var/tmp/build
#RUN dpkg -i google-cloud-cpp_${VERSION}_amd64.deb
RUN dpkg -i libgoogle-cloud-cpp-common_${VERSION}_all.deb

# Storage, which is REST
RUN dpkg -i libgoogle-cloud-cpp-rest-internal_${VERSION}_all.deb
RUN dpkg -i libgoogle-cloud-cpp-storage_${VERSION}_all.deb

# Basic gRPC
RUN dpkg -i libgoogle-cloud-cpp-googleapis_${VERSION}_all.deb
RUN dpkg -i libgoogle-cloud-cpp-grpc-utils_${VERSION}_all.deb
RUN dpkg -i libgoogle-cloud-cpp-kms_${VERSION}_all.deb

# idk, it's compute, it's weird. Also a *REGAPIC.
RUN dpkg -i libgoogle-cloud-cpp-rest-protobuf-internal_${VERSION}_all.deb
RUN dpkg -i libgoogle-cloud-cpp-compute_${VERSION}_all.deb

# Shared proto dep
RUN dpkg -i libgoogle-cloud-cpp-iam-v2_${VERSION}_all.deb
RUN dpkg -i libgoogle-cloud-cpp-iam_${VERSION}_all.deb

# Cross library dep
# Also the weird, common google/cloud/orgpolicy/*.proto
#RUN dpkg -i libgoogle-cloud-cpp-orgpolicy_${VERSION}_all.deb
#RUN dpkg -i libgoogle-cloud-cpp-asset_${VERSION}_all.deb

# =================================
# Test the package by building a quickstart?
# =================================
WORKDIR /var/tmp/quickstart

COPY quickstart/ .

RUN cmake -S . -B cmake-out
RUN cmake --build cmake-out

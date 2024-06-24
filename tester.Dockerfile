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

# The purpose of this Dockerfile is to test our debian package. It copies in the
# local package, installs it, then builds and runs a quickstart that uses the
# Cloud C++ libraries.
#
# To build the image:
# ```
# docker build -t tester -f tester.Dockerfile .
# ```
#
# To inspect the image...
# ```
# # Create the container
# docker container create --name tester tester
#
# # Get a shell in the container
# docker run -it tester bash
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
        automake build-essential ca-certificates cmake curl git \
        gcc g++ m4 make ninja-build pkg-config tar wget zlib1g-dev

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
# Install the google-cloud-cpp package
# =================================
WORKDIR /var/tmp/package

COPY libgoogle-cloud-cpp-dev.deb .
RUN dpkg -i libgoogle-cloud-cpp-dev.deb

# =================================
# Build a quickstart?
# =================================
WORKDIR /var/tmp/quickstart

COPY quickstart/quickstart.cc .
COPY quickstart/CMakeLists.txt .

# TODO : HACK : I am seeing the following error:
#
# ```
# CMake Error at /usr/lib/x86_64-linux-gnu/cmake/google_cloud_cpp_common/google_cloud_cpp_common-targets.cmake:85 (message):
#   The imported target "google-cloud-cpp::common" references the file
# 
#      "/usr/lib/lib/libgoogle_cloud_cpp_common.so.2.25.0"
# 
#   but this file does not exist.  Possible reasons include:
# 
#   * The file was deleted, renamed, or moved to another location.
# ```
#
# I think this means I am not allowed to copy the installed artifacts
# willy-nilly. The real lib is in /usr/lib/x86_64-linux-gnu/. I am not sure
# where the /lib/lib/ comes from...
#
# I tried using CMAKE_INSTALL_DATAROOTDIR, but no luck.
#
# We can create symlinks to make the thing work.
RUN ln -s /usr/include /usr/lib/include
RUN ln -s /usr/lib/x86_64-linux-gnu /usr/lib/lib

RUN cmake -S . -B cmake-out
RUN cmake --build cmake-out

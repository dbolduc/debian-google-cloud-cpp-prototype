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

# The purpose of this Dockerfile is to produce a debian package. Or at least the files in it.
# To build the package and extract it, run:
#
# Build the image:
# ```
# docker build -t producer -f producer.Dockerfile .
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
# Install google-cloud-cpp
# =================================
WORKDIR /var/tmp/build/google-cloud-cpp

ENV INSTALL_PREFIX="/var/tmp/install/google-cloud-cpp"

# Note that we do not enable opentelemetry. There is not a package for
# opentelemetry-cpp yet.

# Note that we use a patched branch of google-cloud-cpp. Ideally we would have
# the patches in this workspace and apply them. But I do not have time for that.
# And I don't want to use sed either.

#RUN curl -fsSL https://github.com/googleapis/google-cloud-cpp/archive/v2.25.0.tar.gz | \
RUN curl -fsSL https://github.com/dbolduc/google-cloud-cpp/archive/refs/heads/v2.25.0-patched-for-deb-package.tar.gz | \
    tar -xzf - --strip-components=1 && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=yes \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
        -DBUILD_TESTING=OFF \
        -DGOOGLE_CLOUD_CPP_ENABLE_EXAMPLES=OFF \
        -DGOOGLE_CLOUD_CPP_ENABLE=__ga_libraries__ \
        -S . -B cmake-out && \
    cmake --build cmake-out --target install -- -j $(nproc)

# =================================
# Create debian specific files (control, changelog, etc.)
# =================================
WORKDIR /var/tmp/package/libgoogle-cloud-cpp-dev

RUN mkdir DEBIAN
COPY control DEBIAN/ 

RUN mkdir -p usr/share/doc/libgoogle-cloud-cpp-dev
COPY copyright usr/share/doc/libgoogle-cloud-cpp-dev/
COPY changelog usr/share/doc/libgoogle-cloud-cpp-dev/
RUN gzip --best -n usr/share/doc/libgoogle-cloud-cpp-dev/changelog

# =================================
# Move files where they belong
# =================================
WORKDIR /var/tmp/package/libgoogle-cloud-cpp-dev

# TODO : HACK : Clean up the import prefix?
# The value is `/usr/lib`. Which doesn't work for the headers or the libraries.
#RUN sed -i "s;${_IMPORT_PREFIX}/include;/usr/include;" ${INSTALL_PREFIX}/lib/cmake/google_cloud_cpp_*/*-targets.cmake
#RUN sed -i "s;${_IMPORT_PREFIX}/lib;/usr/lib/x86_64-linux-gnu;" ${INSTALL_PREFIX}/lib/cmake/google_cloud_cpp_*/*-targets-release.cmake

# Headers go into /usr/include/
RUN mkdir -p usr/include
RUN cp -r ${INSTALL_PREFIX}/include usr

# Libraries, package config, cmake config files go into /usr/lib/x86_64-linux-gnu/
RUN mkdir -p usr/lib/x86_64-linux-gnu
RUN cp -r ${INSTALL_PREFIX}/lib/. usr/lib/x86_64-linux-gnu

# =================================
# Make debian package
# =================================
WORKDIR /var/tmp/package

RUN dpkg-deb --root-owner-group --build libgoogle-cloud-cpp-dev

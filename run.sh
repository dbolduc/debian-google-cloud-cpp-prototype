#!/bin/bash
#
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

# Build docker image
docker build -t producer -f producer.Dockerfile .

# Create docker container
docker container create --name producer producer

# Copy out debian package
docker cp producer:/var/tmp/package/libgoogle-cloud-cpp-dev.deb .

# Clean up docker container
docker container rm producer

 # Build tester image
docker build -t tester -f tester.Dockerfile .

# OPTIONAL: Lint the package
#lintian -j 96 libgoogle-cloud-cpp-dev.deb

# OPTIONAL: Remove the package before the next run
#rm libgoogle-cloud-cpp-dev.deb

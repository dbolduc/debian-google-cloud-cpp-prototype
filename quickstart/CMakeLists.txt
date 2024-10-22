# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

# A minimal CMakeList.txt showing how to use the Google Cloud Storage C++ client
# library in CMake-based projects.

cmake_minimum_required(VERSION 3.10...3.24)
project(test-google-cloud-cpp CXX)

set(libs "storage" "kms" "iam" "compute")
#set(libs "storage" "kms" "iam" "compute" "asset")

foreach (lib IN LISTS libs)
  find_package(google_cloud_cpp_${lib} REQUIRED)
  add_executable(quickstart_${lib} quickstart_${lib}.cc)
  target_link_libraries(quickstart_${lib} google-cloud-cpp::${lib})
endforeach ()

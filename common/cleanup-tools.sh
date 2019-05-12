#!/usr/bin/env bash

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Variables
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}
export PATH=$PATH:$WORK_DIR/bin:

export ISTIO_VERSION=1.1.4

rm -rf $WORK_DIR/bin
rm -rf $WORK_DIR/istio-$ISTIO_VERSION 
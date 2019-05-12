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
export CLUSTER_NAME=$(kubectl config current-context)
export BASE_DIR=${BASE_DIR:="${PWD}/.."}
echo "BASE_DIR set to $BASE_DIR"

source $BASE_DIR/2-ConfigManagement/config-repo-url.env

echo "### "
echo "### Begin install config sync"
echo "### "




## Poll the Config Repository
(set -x; cat $BASE_DIR/2-ConfigManagement/config_sync.yaml | sed 's@<REPO_URL>@'${REPO_URL}@g | sed 's@<CLUSTER_NAME>@'${CLUSTER_NAME}@g | kubectl apply -f -)





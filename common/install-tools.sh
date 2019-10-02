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
export PROJECT=$(gcloud config get-value project)
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}

export ISTIO_VERSION=1.1.15

## Install Tools
mkdir -p $WORK_DIR/bin

echo "### "
echo "### Begin Tools install"
echo "### "

## Install kubectx
curl -sLO https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx 
chmod +x kubectx 
mv kubectx $WORK_DIR/bin

# Download Istio
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cp istio-$ISTIO_VERSION/bin/istioctl $WORK_DIR/bin/.
mv istio-$ISTIO_VERSION $WORK_DIR/

# Install yq.v2
#curl -o yq.v2 -OL https://github.com/mikefarah/yq/releases/download/2.3.0/yq_linux_amd64
#chmod +x yq.v2
#mv yq.v2 $WORK_DIR/bin






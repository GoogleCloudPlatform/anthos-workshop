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

## Install Tools
mkdir -p $WORK_DIR/bin

echo "### "
echo "### Begin Tools install"
echo "### "

## Install tree
if command -v tree 2>/dev/null; then
	echo "tree already installed."
else
	echo "Installing tree..."
	sudo apt-get install tree
	sudo mv /usr/bin/tree $WORK_DIR/bin
fi

## Install kubectx
if command -v kubectx 2>/dev/null; then
	echo "kubectx already installed."
else
	echo "Installing kubectx..."
	curl -sLO https://raw.githubusercontent.com/ahmetb/kubectx/"$KUBECTX_VERSION"/kubectx 
	chmod +x kubectx 
	mv kubectx $WORK_DIR/bin
	echo "kubectx installation complete."
fi

## Install Istio
if [ -d "$WORK_DIR/istio-$ISTIO_VERSION" ] && [ -x "$(command -v istioctl)" ]; then
	echo "Istio already installed."
else
	echo "Downloading Istio..."
	curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
	cp istio-$ISTIO_VERSION/bin/istioctl $WORK_DIR/bin/.
	mv istio-$ISTIO_VERSION $WORK_DIR/
fi

## Install kops
if command -v kops 2>/dev/null; then
	echo "kops already installed."
else
	echo "Installing kops..."
	curl -sLO https://github.com/kubernetes/kops/releases/download/$KOPS_VERSION/kops-linux-amd64
	chmod +x kops-linux-amd64
	mv kops-linux-amd64 $WORK_DIR/bin/kops
	echo "kops installation complete."
fi

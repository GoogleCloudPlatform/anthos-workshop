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

## Install kubectx
if command -v kubectx 2>/dev/null; then
	echo "kubectx already installed."
else
	echo "Installing kubectx..."
	curl -sLO https://raw.githubusercontent.com/ahmetb/kubectx/"$KUBECTX_VERSION"/kubectx 
	chmod +x kubectx 
	mv kubectx $WORK_DIR/bin
fi

## Install Helm
#curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
#chmod 700 get_helm.sh
#./get_helm.sh &> /dev/null
#cp /usr/local/bin/helm $WORK_DIR/bin
#rm ./get_helm.sh

## Install Helm
if command -v helm 2>/dev/null; then
	echo "helm already installed."
else
	echo "Installing helm..."
	wget -q https://storage.googleapis.com/kubernetes-helm/helm-"$HELM_VERSION"-linux-amd64.tar.gz
	tar -xvzf helm-"$HELM_VERSION"-linux-amd64.tar.gz
	mv linux-amd64/helm $WORK_DIR/bin
	mv linux-amd64/tiller $WORK_DIR/bin
	rm helm-"$HELM_VERSION"-linux-amd64.tar.gz
	rm -rf linux-amd64
fi

## Install Istio
if [ -d "$WORK_DIR/istio-$ISTIO_VERSION" ]; then
    if command -v istioctl 2>/dev/null; then
		echo "Istio already installed."
	else
		echo "Installing Istio..."
		curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
		cp istio-$ISTIO_VERSION/bin/istioctl $WORK_DIR/bin/.
		mv istio-$ISTIO_VERSION $WORK_DIR/ 
	fi
else
	echo "Installing Istio..."
	curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
	cp istio-$ISTIO_VERSION/bin/istioctl $WORK_DIR/bin/.
	mv istio-$ISTIO_VERSION $WORK_DIR/
fi


## Install kops
if command -v kops 2>/dev/null; then
	echo "kops already installed."
else
	echo "Installing kops"
  curl -sLO https://github.com/kubernetes/kops/releases/download/$KOPS_VERSION/kops-linux-amd64
  chmod +x kops-linux-amd64
	mv kops-linux-amd64 $WORK_DIR/bin/kops
fi

# Install yq.v2
#curl -o yq.v2 -OL https://github.com/mikefarah/yq/releases/download/2.3.0/yq_linux_amd64
#chmod +x yq.v2
#mv yq.v2 $WORK_DIR/bin






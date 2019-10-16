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

# This script to establish Cloud Shell kubectl connectivity to clusters created
# outside of that Cloud Shell session, to both a GKE cluster, and a Kops
# cluster.

source ./env
source ./common/install-tools.sh
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}
export PATH=$PATH:$WORK_DIR/bin

# Connect to central cluster

export CLUSTER_NAME=gcp
export CLUSTER_ZONE=us-central1-b

gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE

# This renames the kubectl context to something simpler.
kubectx ${CLUSTER_NAME}=gke_${PROJECT}_${CLUSTER_ZONE}_${CLUSTER_NAME}

# Connect to remote cluster

# Download kops tool, move to workdir/bin
curl -sLO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
mv kops-linux-amd64 $WORK_DIR/bin/kops

export REMOTE_CLUSTER_NAME_BASE=onprem
export REMOTE_CLUSTER_NAME=$REMOTE_CLUSTER_NAME_BASE.k8s.local
export KOPS_STORE=gs://$PROJECT-kops-$REMOTE_CLUSTER_NAME_BASE

# Set user to storage object viewer
export STUDENT=$(gcloud config get-value account)
gcloud projects add-iam-policy-binding $PROJECT --member user:$STUDENT --role roles/storage.objectViewer

kops export kubecfg --name $REMOTE_CLUSTER_NAME --state=$KOPS_STORE

# This renames the kubectl context to something simpler.
kubectx $REMOTE_CLUSTER_NAME_BASE=$REMOTE_CLUSTER_NAME && kubectx $REMOTE_CLUSTER_NAME_BASE

# Set up firewall to access clusters from Cloud Shell
./common/remote-k8s-access-fw.sh


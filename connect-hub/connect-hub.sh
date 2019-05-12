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

export REMOTE_CLUSTER_NAME_BASE="remote"
export REMOTE_CLUSTER_NAME=$REMOTE_CLUSTER_NAME_BASE.k8s.local
export REMOTE_KUBECONFIG=$WORK_DIR/remote.context

export GKE_CONNECT_SA=anthos-connect
export GKE_CONNECT_SA=gke-connect-sa
export GKE_SA_CREDS=$WORK_DIR/$GKE_CONNECT_SA-creds.json


echo "### "
echo "### Prepare remote cluster for Hub"
echo "### "


# Install Tools
### Access hub alpha
sudo gcloud components repositories add https://storage.googleapis.com/gkehub-gcloud-dist-beta/components-2.json
sudo gcloud components update


# Switch to remote Context
kubectx $REMOTE_CLUSTER_NAME_BASE


## Provision the GKE Connect Service Account & Access

# Create GKE Connect Service Account
# >> NOTE: This should already exist as it was needed for the whitelisting process
gcloud iam service-accounts create $GKE_CONNECT_SA --project=$PROJECT

# Assign it GKE Connect rights
gcloud projects add-iam-policy-binding $PROJECT \
    --member="serviceAccount:$GKE_CONNECT_SA@$PROJECT.iam.gserviceaccount.com" \
    --role="roles/gkehub.connect"

# Create and download a key
gcloud iam service-accounts keys create $GKE_SA_CREDS --project=$PROJECT \
  --iam-account=$GKE_CONNECT_SA@$PROJECT.iam.gserviceaccount.com 



### Connect Cluster to Hub
gcloud alpha container hub register-cluster $REMOTE_CLUSTER_NAME_BASE\
 --context=$REMOTE_CLUSTER_NAME \
 --service-account-key-file=$GKE_SA_CREDS \
 --kubeconfig-file=$REMOTE_KUBECONFIG \
 --docker-image=gcr.io/gkeconnect/gkeconnect-gce:gkeconnect_20190311_00_00 \
 --project=$PROJECT


## Create Service Account for use in Login Step
export KSA=remote-admin-sa
kubectl create serviceaccount $KSA
kubectl create clusterrolebinding ksa-admin-binding --clusterrole cluster-admin --serviceaccount default:$KSA


# Generate Token for login process
echo "###########################"
echo "Use the following token during login at https://console.cloud.google.com/kubernetes/list"
kubectl --kubeconfig=$REMOTE_KUBECONFIG describe secret $KSA | sed -ne 's/^token: *//p' 

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


# Reclaim Workspace






git clone -b demo https://github.com/GoogleCloudPlatform/anthos-workshop.git anthos-workshop
cd anthos-workshop
source ./env


./common/install-tools.sh


# Get GKE Auth
export CLUSTER="gcp"
export ZONE="us-central1-b"
export CLUSTER_KUBECONFIG=$WORK_DIR/central.context
export PROJECT=$(gcloud config get-value project)
export PROJECT_ID=${PROJECT}

gcloud container clusters get-credentials ${CLUSTER} --zone ${ZONE}


kubectx ${CLUSTER}=gke_${PROJECT}_${ZONE}_${CLUSTER}
kubectx ${CLUSTER}

KUBECONFIG= kubectl config view --minify --flatten --context=$CLUSTER > $CLUSTER_KUBECONFIG

# Get KOPS Auth
./common/remote-k8s-access-fw.sh

export PROJECT=$(gcloud config get-value project)
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}
export REMOTE_CLUSTER_NAME_BASE=${GCE_CONTEXT:-"onprem"}
export REMOTE_KUBECONFIG=$WORK_DIR/${REMOTE_CLUSTER_NAME_BASE}.context
export REMOTE_CLUSTER_NAME=$REMOTE_CLUSTER_NAME_BASE.k8s.local
export KOPS_STORE=gs://$PROJECT-kops-$REMOTE_CLUSTER_NAME_BASE

### GIVE USER ACCESS TO BUCKET
# gsutil acl ch -u [USER_EMAIL]:[PERMISSION] gs://[BUCKET_NAME]
# $(gcloud config get-value account)
# roles/storage.admin

gsutil iam ch "user:$(gcloud config get-value account):legacyObjectOwner" $KOPS_STORE
#kops get cluster --state=$KOPS_STORE
kops export kubecfg $REMOTE_CLUSTER_NAME --state=$KOPS_STORE
KUBECONFIG= kubectl config view --minify --flatten --context=$REMOTE_CLUSTER_NAME > $REMOTE_KUBECONFIG

kubectx $REMOTE_CLUSTER_NAME_BASE=$REMOTE_CLUSTER_NAME && kubectx $REMOTE_CLUSTER_NAME_BASE

# Cleanup
kubectx gcp && kubectl delete secret git-creds -n config-management-system
kubectx onprem && kubectl delete secret git-creds -n config-management-system
gcloud source repos delete config-repo --quiet


yes y | ssh-keygen -t rsa -b 4096 -C "$GCLOUD_ACCOUNT" -N '' -f $HOME/.ssh/id_rsa.nomos>/dev/null
kubectx gcp && kubectl create secret generic git-creds --namespace=config-management-system --from-file=ssh=$HOME/.ssh/id_rsa.nomos
kubectx onprem && kubectl create secret generic git-creds --namespace=config-management-system --from-file=ssh=$HOME/.ssh/id_rsa.nomos



source ./config-management/create-repo.sh

cd $HOME/anthos-workshop

GCLOUD_ACCOUNT=$(gcloud config get-value account)
export REPO_URL=ssh://${GCLOUD_ACCOUNT}@source.developers.google.com:2022/p/${PROJECT}/r/config-repo




kubectx gcp && ./config-management/install-config-sync.sh
kubectx onprem && ./config-management/install-config-sync.sh

export KSA=remote-admin-sa


#export CONTEXT=onprem && ./connect-hub/connect-hub.sh
kubectx gcp


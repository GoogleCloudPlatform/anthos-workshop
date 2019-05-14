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

. common/demo-magic.sh

pe "gcloud services enable \
    cloudresourcemanager.googleapis.com \
    container.googleapis.com \
    gkeconnect.googleapis.com \
    gkehub.googleapis.com \
    serviceusage.googleapis.com \
    sourcerepo.googleapis.com \
    --async"

pe "git clone https://github.com/GoogleCloudPlatform/anthos-workshop.git anthos-workshop"

# Initial build
pe "cd anthos-workshop"
pe "source ./env"
pe "source ./bootstrap-workshop.sh"
pe "source ./service-mesh/enable-service-mesh.sh"
pe "kubectx remote"
pe "kubectl get nodes"

# Environment
pe "export PROJECT=$(gcloud config get-value project)"
pe "export GKE_CONNECT_SA=anthos-connect"
pe "export GKE_SA_CREDS=$WORK_DIR/$GKE_CONNECT_SA-creds.json"

pe "gcloud projects add-iam-policy-binding $PROJECT \
    --member=\"serviceAccount:$GKE_CONNECT_SA@$PROJECT.iam.gserviceaccount.com\" \
    --role=\"roles/gkehub.connect\""

pe "gcloud iam service-accounts keys create $GKE_SA_CREDS \
  --iam-account=$GKE_CONNECT_SA@$PROJECT.iam.gserviceaccount.com \
  --project=$PROJECT"

pe "export REMOTE_CLUSTER_NAME_BASE=remote"
pe "export REMOTE_CLUSTER_NAME=$REMOTE_CLUSTER_NAME_BASE.k8s.local"
pe "export REMOTE_KUBECONFIG=$WORK_DIR/remote.context"

pe "export GKE_CONNECT_SA=anthos-connect"
pe "export GKE_SA_CREDS=$WORK_DIR/$GKE_CONNECT_SA-creds.json"
pe "kubectx remote"

# Cluster registration
pe "gcloud alpha container hub register-cluster $REMOTE_CLUSTER_NAME_BASE \
 --context=$REMOTE_CLUSTER_NAME \
 --service-account-key-file=$GKE_SA_CREDS \
 --kubeconfig-file=$REMOTE_KUBECONFIG \
 --docker-image=gcr.io/gkeconnect/gkeconnect-gce:gkeconnect_20190508_03_00 \
 --project=$PROJECT"

pe "export KSA=remote-admin-sa"
pe "kubectl create serviceaccount $KSA"
pe "kubectl create clusterrolebinding ksa-admin-binding \
    --clusterrole cluster-admin \
    --serviceaccount default:$KSA"

pe "printf \"\n$(kubectl --kubeconfig=$REMOTE_KUBECONFIG describe secret $KSA | sed -ne 's/^token: *//p')\n\n\""

p "Now use the GKE console to log in to the cluster with the token above"
p "============================================================"

# Config management
pe "export PROJECT=$(gcloud config get-value project)"

pe "cd $HOME"
pe "export GCLOUD_ACCOUNT=$(gcloud config get-value account)"
pe "export REPO_URL=https://source.developers.google.com/p/${PROJECT}/r/config-repo"

pe "git clone https://github.com/cgrant/config-repo config-repo"
pe "cd config-repo"
pe "git remote remove origin"
pe "git config credential.helper gcloud.sh"
pe "git remote add origin $REPO_URL"

pe "gcloud source repos create config-repo"
pe "git push -u origin master"

pe "ssh-keygen -t rsa -b 4096 \
-C \"$GCLOUD_ACCOUNT\" \
-N '' \
-f $HOME/.ssh/id_rsa.nomos"

pe "kubectx central"
pe "kubectl create secret generic git-creds \
--namespace=config-management-system \
--from-file=ssh=$HOME/.ssh/id_rsa.nomos"

pe "kubectx remote"
pe "kubectl create secret generic git-creds \
--namespace=config-management-system \
--from-file=ssh=$HOME/.ssh/id_rsa.nomos"

p "Now register the public key in the Cloud Source Repositories console"

p "============================================================"

# Review the structure
pe "tree . "
pe "echo $REPO_URL"
pe "cat $BASE_DIR/config-management/config_sync.yaml"

pe "export REMOTE=remote"
pe "export CENTRAL=central"
pe "REPO_URL=ssh://${GCLOUD_ACCOUNT}@source.developers.google.com:2022/p/${PROJECT}/r/config-repo"

pe "kubectx $REMOTE"
pe "cat $BASE_DIR/config-management/config_sync.yaml | \
  sed 's|<REPO_URL>|'\"$REPO_URL\"'|g' | \
  sed 's|<CLUSTER_NAME>|'\"$REMOTE\"'|g' | \
  sed 's|none|ssh|g' | \
  kubectl apply -f - "

pe "kubectx $CENTRAL"
pe "cat $BASE_DIR/config-management/config_sync.yaml | \
  sed 's|<REPO_URL>|'\"$REPO_URL\"'|g' | \
  sed 's|<CLUSTER_NAME>|'\"$CENTRAL\"'|g' | \
  sed 's|none|ssh|g' | \
  kubectl apply -f - "

pe "mkdir namespaces/checkout"

pe "cat <<EOF > namespaces/checkout/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: checkout
EOF"

pe "tree ." 

pe "export EMAIL=$(gcloud config get-value account)"
pe "git config --global user.email \"$EMAIL\""
pe "git config --global user.name \"$USER\""

pe "git add . && git commit -m 'adding checkout namespace'"
pe "git push origin master"

pe "kubectl --context remote delete ns checkout"
pe "cd $HOME/config-repo"
pe "mkdir clusterregistry"

pe "cat <<EOF > clusterregistry/cluster-remote.yaml
kind: Cluster
apiVersion: clusterregistry.k8s.io/v1alpha1
metadata:
  name: remote
  labels:
    env: remote
    lifecycle: prod
EOF"

pe "cat <<EOF > clusterregistry/cluster-central.yaml
kind: Cluster
apiVersion: clusterregistry.k8s.io/v1alpha1
metadata:
  name: central
  labels:
    env: central
    lifecycle: prod
EOF"

pe "git add . && git commit -m 'add ClusterSelector and Cluster resource definitions for remote and central'"
pe "git push origin master"

pe "cat <<EOF > clusterregistry/clusterselector-remote.yaml
kind: ClusterSelector
apiVersion: configmanagement.gke.io/v1
metadata:
  name: selector-env-remote
spec:
  selector:
    matchLabels:
      env: remote
      lifecycle: prod
EOF"

pe "cat <<EOF > namespaces/checkout/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: checkout
  annotations:
    configmanagement.gke.io/cluster-selector: selector-env-remote
EOF"

pe "git add . && git commit -m 'modify the checkout namespace'"
pe "git push origin master"

p "============================================================"

pe "cd $BASE_DIR"
pe "./hybrid-multicluster/istio-dns.sh"
pe "kubectl --context central -n kube-system get configmap kube-dns -o json | jq '.data' "
pe "kubectl --context central -n istio-system get configmap coredns -o json | jq -r '.data.Corefile'"
pe "./hybrid-multicluster/istio-deploy-hipster.sh"

pe "kubectl --context central -n hipster2 get all"
pe "kubectl --context remote -n hipster1 get all"

pe "kubectl --context central -n hipster2 get deploy frontend -ojson | jq -r '[.spec.template.spec.containers[].env[]]'"
pe "kubectl --context remote -n hipster1 get deploy checkoutservice -ojson | jq -r '[.spec.template.spec.containers[].env[]]'"

pe "kubectl --context central -n hipster2 get serviceentries"
pe "kubectl --context remote -n hipster1 get serviceentries"

pe "kubectl --context central -n hipster2 get serviceentry checkoutservice-entry -ojson | jq '.spec.endpoints'"
pe "kubectl --context central -n hipster2 get gateway -ojson | jq '.items[].spec'"
pe "kubectl --context central get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"

p "============================================================"

pe "./hybrid-multicluster/istio-connect.sh"
pe "./hybrid-multicluster/istio-migrate-hipster.sh"

pe "kubectl --context central -n hipster2 get deploy frontend -ojson | jq -r '[.spec.template.spec.containers[].env[]]'"
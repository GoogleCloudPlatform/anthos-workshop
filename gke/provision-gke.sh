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
export PROJECT_ID=${PROJECT}
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}

export CLUSTER_VERSION="1.13.7-gke.19"
export CLUSTER_NAME="gcp"
export CLUSTER="gcp"
export CLUSTER_ZONE="us-central1-b"
export ZONE="us-central1-b"
export CLUSTER_KUBECONFIG=$WORK_DIR/central.context

echo "### "
echo "### Begin Provision GKE"
echo "### "

gcloud beta container clusters create $CLUSTER_NAME --zone $CLUSTER_ZONE \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing,Istio,CloudRun \
    --istio-config=auth=MTLS_PERMISSIVE \
    --username "admin" \
    --machine-type "n1-standard-8" \
    --image-type "COS" \
    --disk-size "100" \
    --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    --num-nodes "5" \
    --enable-autoscaling --min-nodes 5 --max-nodes 10 \
    --network "default" \
    --enable-cloud-logging \
    --enable-cloud-monitoring \
    --enable-ip-alias \
    --cluster-version=${CLUSTER_VERSION} \
    --enable-stackdriver-kubernetes \
    --identity-namespace=${PROJECT_ID}.svc.id.goog \
    --labels csm=

gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_ZONE}

kubectx ${CLUSTER_NAME}=gke_${PROJECT}_${CLUSTER_ZONE}_${CLUSTER_NAME}
kubectx ${CLUSTER_NAME}

KUBECONFIG= kubectl config view --minify --flatten --context=$CLUSTER_NAME > $CLUSTER_KUBECONFIG

kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"








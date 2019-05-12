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

echo "### "
echo "### Provisioning Cloud Run on GKE"
echo "### "

set -euo pipefail
log() { echo "$1" >&2; }

# set vars, remove or move into 1-settings.env when live for 0-full-install.sh
export CLOUDRUN_CLUSTER_NAME=cloud-run-gke
export CLOUDRUN_ZONE=us-west1-a
export PROJECT=$(gcloud config get-value project)

# create cloud run on gke cluster
gcloud beta container clusters create $CLOUDRUN_CLUSTER_NAME \
--addons=HorizontalPodAutoscaling,HttpLoadBalancing,Istio,CloudRun \
--machine-type=n1-standard-4 \
--cluster-version=latest --zone=$CLOUDRUN_ZONE \
--enable-stackdriver-kubernetes --enable-ip-alias \
--scopes cloud-platform

# rename context
kubectx $CLOUDRUN_CLUSTER_NAME=gke_${PROJECT}_${CLOUDRUN_ZONE}_${CLOUDRUN_CLUSTER_NAME}

# export pod and svc ip ranges 
export POD_IP_RANGE=$(gcloud container clusters describe $CLOUDRUN_CLUSTER_NAME --zone $CLOUDRUN_ZONE --format=flattened | grep -e clusterIpv4Cidr | awk 'FNR == 1 {print $2}')
export SERVICE_IP_RANGE=$(gcloud container clusters describe $CLOUDRUN_CLUSTER_NAME --zone $CLOUDRUN_ZONE --format=flattened | grep -e servicesIpv4Cidr | awk 'FNR == 1 {print $2}')

# patch config-network configmap
kubectl get configmap config-network --namespace knative-serving -o yaml --export=true > config-network.yaml
sed -i 's@istio.sidecar.includeOutboundIPRanges: \"\*\"@istio.sidecar.includeOutboundIPRanges: \"'"$POD_IP_RANGE,$SERVICE_IP_RANGE"'\"@g' config-network.yaml
kubectl apply -f setup/resources/config-network.yaml --namespace knative-serving

# grab istio-ingressgateway ip
kubectl get service istio-ingressgateway --namespace istio-system | grep istio-ingressgateway | awk 'FNR == 1 {print $4}'
export ISTIO_INGRESSGATEWAY_IP=$(kubectl get service istio-ingressgateway --namespace istio-system | grep istio-ingressgateway | awk 'FNR == 1 {print $4}')

# patch configmap for config-domain to use xip.io for wildcard dns
kubectl patch configmap config-domain --namespace knative-serving --patch \
  '{"data": {"example.com": null, "'$ISTIO_INGRESSGATEWAY_IP'.xip.io": ""}}'
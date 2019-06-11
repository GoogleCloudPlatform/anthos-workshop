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
echo "### Deploying hipster app on central "
echo "### "


# Set vars for DIRs
export BASE_DIR=${BASE_DIR:="${PWD}/.."}
echo "BASE_DIR set to $BASE_DIR"
export ISTIO_CONFIG_DIR="$BASE_DIR/hybrid-multicluster/istio"

# Get Istio ingress gateway Ip addresses from  central
export GWIP_CENTRAL=$(kubectl --context central get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Prepare central cluster hipster manifests
# change context to central cluster
kubectx central
# Prepare the service-entries yaml to add the remote cluster istio ingress gateway IP 
export pattern='.*- address:.*'
export replace="  - address: "$GWIP_CENTRAL""
sed -r -i "s|$pattern|$replace|g" ${ISTIO_CONFIG_DIR}/central/service-entries.yaml

# Create hipster2 namespace and enable istioInjection on the namespace
kubectl create namespace hipster2
kubectl label namespace hipster2 istio-injection=enabled


kubectl apply -n hipster2  -f ${ISTIO_CONFIG_DIR}/central
kubectl apply -n hipster2  -f ${ISTIO_CONFIG_DIR}/hipster 

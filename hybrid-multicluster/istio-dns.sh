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
echo "### Prepare core-dns to resolve .global domain"
echo "### "


# Install configmap for kube-dns to send 'global' domain to CoreDNS pod IP
# This means that any DNS name that ends with .global will be resolved using CoreDNS instead of kube-dns
# Install in central cluster
kubectx central
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"global": ["$(kubectl --context central get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})"]}
EOF

# Install in central cluster
kubectx remote
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    {"global": ["$(kubectl --context remote get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP})"]}
EOF

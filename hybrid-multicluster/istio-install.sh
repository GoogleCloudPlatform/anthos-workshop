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
echo "### Begin install istio control plane"
echo "### "

# Install Istio on central
# Change context
kubectx central
# Create istio-system namespace
kubectl create namespace istio-system
# Tiller service account
kubectl --context central apply -f ${WORK_DIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/helm-service-account.yaml
# Install tiller
helm init --service-account tiller --wait

# wait for helm to install in central cluster
#until timeout 10 helm version; do sleep 10; done

# Create a secret with the sample certs for multicluster deployment
kubectl --context central create secret generic cacerts -n istio-system \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/ca-cert.pem \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/ca-key.pem \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/root-cert.pem \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/cert-chain.pem

# install istio CRDs
helm install istio-init ${WORK_DIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init --namespace istio-system

# wait until all 23 CRDs are installed
until [ $(kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l) = 23 ]; do echo "Waiting for Istio CRDs to install..." && sleep 3; done

# Confirm Istio CRDs ae installed
echo "Istio CRDs installed" && kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

# Create a secret for kiali username: 'admin' and password 'password'
kubectl --context central apply -f ${ISTIO_CONFIG_DIR}/istio-multicluster/kiali-secret.yaml

# Install Istio
helm install istio ${WORK_DIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio --namespace istio-system \
--values ${ISTIO_CONFIG_DIR}/istio-multicluster/values-istio-multicluster-gateways.yaml


# Install Istio on remote cluster
# Change context
kubectx remote
# Create istio-system namespace
kubectl create namespace istio-system
# Tiller service account
kubectl --context remote apply -f ${WORK_DIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/helm-service-account.yaml
# Install tiller
helm init --service-account tiller --wait

# wait for helm to install in central cluster
#until timeout 10 helm version; do sleep 10; done

# Create a secret with the sample certs for multicluster deployment
kubectl --context remote create secret generic cacerts -n istio-system \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/ca-cert.pem \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/ca-key.pem \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/root-cert.pem \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/cert-chain.pem

# install istio CRDs
helm install istio-init ${WORK_DIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init --namespace istio-system

# wait until all 23 CRDs are installed
until [ $(kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l) = 23 ]; do echo "Waiting for Istio CRDs to install..." && sleep 3; done

# Confirm Istio CRDs ae installed
echo "Istio CRDs installed" && kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

# Create a secret for kiali username: 'admin' and password 'password'
kubectl --context remote apply -f ${ISTIO_CONFIG_DIR}/istio-multicluster/kiali-secret.yaml

# Install Istio
helm install istio ${WORK_DIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio --namespace istio-system \
--values ${ISTIO_CONFIG_DIR}/istio-multicluster/values-istio-multicluster-gateways.yaml

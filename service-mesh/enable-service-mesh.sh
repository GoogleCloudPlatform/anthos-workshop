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
export PROJECT_ID=$(gcloud config get-value project)
export CLUSTER="gcp"
export ZONE="us-central1-b"

kubectx gcp

gcloud services enable contextgraph.googleapis.com --project ${PROJECT_ID}
ACCOUNT=$(gcloud config get-value account)

kubectl create clusterrolebinding cluster-admin-binding --clusterrole="cluster-admin" --user=${ACCOUNT}

MESH_ID="${PROJECT_ID}/${ZONE}/${CLUSTER}"

gsutil cat gs://csm-artifacts/stackdriver/stackdriver.istio_1_1.csm_beta.yaml | sed 's@<mesh_uid>@'${MESH_ID}@g | kubectl apply -f -

gcloud iam service-accounts create istio-mixer --display-name istio-mixer --project ${PROJECT_ID}

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:istio-mixer@${PROJECT_ID}.iam.gserviceaccount.com --role=roles/contextgraph.asserter
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:istio-mixer@${PROJECT_ID}.iam.gserviceaccount.com --role=roles/logging.logWriter
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:istio-mixer@${PROJECT_ID}.iam.gserviceaccount.com --role=roles/monitoring.metricWriter
gcloud iam service-accounts add-iam-policy-binding --role roles/iam.workloadIdentityUser --member "serviceAccount:${PROJECT_ID}.svc.id.goog[istio-system/istio-mixer-service-account]" istio-mixer@${PROJECT_ID}.iam.gserviceaccount.com

kubectl annotate serviceaccount --namespace istio-system istio-mixer-service-account iam.gke.io/gcp-service-account=istio-mixer@${PROJECT_ID}.iam.gserviceaccount.com

kubectl label namespace default istio-injection=enabled

kubectl delete po $(kubectl get pod -n istio-system -l app=telemetry -o json | jq -r '.items[].metadata.name') -n istio-system

# This script is run from a parent directory so adding the path
kubectl apply -f ./service-mesh/asm-mtls.yaml #enable mTLS for some services
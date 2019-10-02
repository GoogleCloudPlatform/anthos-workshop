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
kubectx central

# Enable the required GCP APIs for the topology view
gcloud services enable iamcredentials.googleapis.com contextgraph.googleapis.com --project ${PROJECT}

# Add a csm label for your cluster
gcloud container clusters update ${CLUSTER_NAME} --zone ${CLUSTER_ZONE} --update-labels csm=

# Since we are using Istio 1.1 series, run the commands below to enable the adapter
ACCOUNT=$(gcloud config get-value account)
kubectl create clusterrolebinding cluster-admin-binding --clusterrole="cluster-admin" --user=${ACCOUNT}
MESH_ID="${PROJECT}/${CLUSTER_ZONE}/${CLUSTER_NAME}"
gsutil cat gs://csm-artifacts/stackdriver/stackdriver.istio_1_1.csm_beta.yaml | \
    sed 's@<mesh_uid>@'${MESH_ID}@g | kubectl apply -f -

# Create a GSA for Istio’s Mixer component.  Workload Identity will use the permissions granted to this GSA.
gcloud iam service-accounts create istio-mixer --display-name istio-mixer --project ${PROJECT}

# Grant the required permissions to Istio Mixer GSA. Those permissions are used for Istio sending telemetry data to Stackdriver.
gcloud projects add-iam-policy-binding ${PROJECT} --member=serviceAccount:istio-mixer@${PROJECT}.iam.gserviceaccount.com --role=roles/contextgraph.asserter
gcloud projects add-iam-policy-binding ${PROJECT} --member=serviceAccount:istio-mixer@${PROJECT}.iam.gserviceaccount.com --role=roles/logging.logWriter
gcloud projects add-iam-policy-binding ${PROJECT} --member=serviceAccount:istio-mixer@${PROJECT}.iam.gserviceaccount.com --role=roles/monitoring.metricWriter

# Allow the Kubernetes service account  to use Istio Mixer GSA by creating a Cloud IAM policy binding between them
gcloud iam service-accounts add-iam-policy-binding --role roles/iam.workloadIdentityUser --member "serviceAccount:${PROJECT}.svc.id.goog[istio-system/istio-mixer-service-account]" istio-mixer@${PROJECT}.iam.gserviceaccount.com

# Tell the Pod to use the GSA by adding an annotation to the Kubernetes service account, using the email address of Istio Mixer GSA.
kubectl annotate serviceaccount --namespace istio-system istio-mixer-service-account iam.gke.io/gcp-service-account=istio-mixer@${PROJECT}.iam.gserviceaccount.com

# Restarting the istio-telemetry to ensure metric and topology are being sent
kubectl delete po $(kubectl get pod -n istio-system -l app=telemetry -o json | jq -r '.items[].metadata.name') -n istio-system
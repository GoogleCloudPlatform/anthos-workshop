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

echo "###"
echo "# Deploying a Cloud Run app that integrates with GCS, PubSub, and Vision APIex"
echo "###"

REGION=us-central1
CLOUD_RUN_IMAGE_ID=gcr.io/alexmattson-scratch/cloud-run-gcs-computer-vision-demo-02:750b8f9914fefe8832c0d46df846b7a2a378c836

SERVICE_NAME=cloud-run-vision
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
BUCKET_NAME=$SERVICE_NAME-$PROJECT_ID
SUBSCRIPTION_NAME=$SERVICE_NAME-subscription
TOPIC_NAME=projects/$PROJECT_ID/topics/$SERVICE_NAME

echo "Creating resources in current project $PROJECT_ID in region $REGION"

echo "Creating GCS bucket $BUCKET_NAME"
gsutil mb -p $PROJECT_ID -c regional -l $REGION -b on gs://$BUCKET_NAME/

echo "Enabling Cloud PubSub API"
gcloud services enable pubsub.googleapis.com

echo "Creating PubSub topic $TOPIC_NAME"
gcloud pubsub topics create $SERVICE_NAME

echo "Enabling GCS notifications to PubSub for object writes"
gsutil notification create -t $TOPIC_NAME -f json -e OBJECT_FINALIZE gs://$BUCKET_NAME
echo "Note that the above creates a new notification every time it's run"
echo "You can list existing ones via 'gsutil notification list [BUCKET_LOCATION]'"
echo "Delete old ones via 'gsutil notification delete [NOTIFICATION_NAME]'"

echo "Enabling Cloud Vision API"
gcloud services enable staging-vision.sandbox.googleapis.com
gcloud services enable vision.googleapis.com

echo "Creating Cloud Run service $SERVICE_NAME"
echo "NOTE: This is enabling the Cloud Run service in unauthenticated mode, meaning anyone can run it"
echo "In production environments, enable authentication to secure your workloads"
gcloud beta run deploy $SERVICE_NAME --image $CLOUD_RUN_IMAGE_ID --region $REGION --allow-unauthenticated

echo "Exporting Cloud Run URL"
CLOUD_RUN_URL=$(gcloud beta run services list --format=flattened | grep status.address.hostname | awk 'FNR == 1 {print $2}')

echo "Creating Pub/Sub Subscription for Cloud Run app"
gcloud pubsub subscriptions create $SUBSCRIPTION_NAME --topic $TOPIC_NAME --topic-project $PROJECT_ID --push-endpoint $CLOUD_RUN_URL 

echo "You can now access your Cloud Run app at $CLOUD_RUN_URL"

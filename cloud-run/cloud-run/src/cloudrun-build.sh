#!/bin/bash

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
echo "Building a new version of the Cloud Run service"
echo "NOTE: this uses the 'latest' image tag"
echo "###"

REGION=us-central1
SERVICE_NAME=cloud-run-vision
PROJECT_ID=$(gcloud config list --format 'value(core.project)')

gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME .

echo "Updating $SERVICE_NAME with new image gcr.io/$PROJECT_ID/$SERVICE_NAME:latest"
gcloud beta run deploy $SERVICE_NAME --image gcr.io/$PROJECT_ID/$SERVICE_NAME:latest --region $REGION --allow-unauthenticated
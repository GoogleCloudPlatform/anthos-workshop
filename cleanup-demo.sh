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

source ./env
source $BASE_DIR/common/manage-state.sh
load_state

export PROJECT=$(gcloud config get-value project)
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}

echo "WORK_DIR set to $WORK_DIR"

gcloud config set project $PROJECT

# Delete source repo
gcloud source repos delete config-repo -q

# Clean up resources in the background and wait for completion

shopt -s nocasematch
if [[ ${KOPS_AWS} == y ]]; then
    export CONTEXT=$AWS_CONTEXT && ./connect-hub/cleanup-hub.sh
    ./connect-hub/cleanup-remote-aws.sh
fi

shopt -s nocasematch
if [[ ${KOPS_GCE} == y ]]; then
    export CONTEXT=$GCE_CONTEXT && ./connect-hub/cleanup-hub.sh
    ./connect-hub/cleanup-remote-gce.sh
fi

shopt -s nocasematch
if [[ ${GKE_CLUSTER} == y ]]; then
    ./gke/cleanup-gke.sh
fi

# Delete kops storage bucket
gsutil rm -r gs://kbcn-alpha10-kops-onprem/

rm -rf $WORK_DIR


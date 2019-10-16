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


## Clean up
shopt -s nocasematch
if [[ ${KOPS_AWS} == y ]]; then
    export CONTEXT=$AWS_CONTEXT && ./connect-hub/cleanup-hub.sh
    ./connect-hub/cleanup-remote-aws.sh
fi




## Reprovision
  # Kops on AWS?
    read -e -p "Kops on AWS? (Y/N) [${KOPS_AWS:-$KOPS_AWS}]:" kopsa
    export KOPS_AWS=${kopsa:-"$KOPS_AWS"}
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then

        # AWS ID
        read -e -p "AWS_ACCESS_KEY_ID [${AWS_ACCESS_KEY_ID:-$AWS_ACCESS_KEY_ID}]:" id
        export AWS_ACCESS_KEY_ID=${id:-"$AWS_ACCESS_KEY_ID"}

        # AWS Key
        read -e -p "AWS_SECRET_ACCESS_KEY [${AWS_SECRET_ACCESS_KEY:-$AWS_SECRET_ACCESS_KEY}]:" key
        export AWS_SECRET_ACCESS_KEY=${key:-"$AWS_SECRET_ACCESS_KEY"}

        # AWS Context name
        read -e -p 'AWS_CONTEXT [external]:' key
        export AWS_CONTEXT=${key:-"external"}

        # AWS Uniquee Bucket Suffix
        read -e -p "New Bucket Suffix - Last used was [${AWS_RND}]:" rnd
        export AWS_RND=${rnd:-"${AWS_RND}"}
    fi

    write_state


# Provision
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then
        ./connect-hub/provision-remote-aws.sh &> ${WORK_DIR}/provision-aws-${AWS_CONTEXT}.log &
        wait
    fi


# Istio
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then
        kubectx ${AWS_CONTEXT} && ./hybrid-multicluster/istio-install-single.sh
    fi

# Config Management
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then
        kubectx ${AWS_CONTEXT} && kubectl create secret generic git-creds --namespace=config-management-system --from-file=ssh=$HOME/.ssh/id_rsa.nomos
        kubectx ${AWS_CONTEXT} && ./config-management/install-config-operator.sh
        kubectx ${AWS_CONTEXT} && ./config-management/install-config-sync.sh
    fi



  # Remote
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then
        export CONTEXT=$AWS_CONTEXT && ./connect-hub/connect-hub.sh
    fi

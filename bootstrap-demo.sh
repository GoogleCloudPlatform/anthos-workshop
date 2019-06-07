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

# Variables

# REQUIRES 
## AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY



if [[ $OSTYPE == "linux-gnu" && $CLOUD_SHELL == true ]]; then 

    export PROJECT=$(gcloud config get-value project)
    export BASE_DIR=${BASE_DIR:="${PWD}"}
    export WORK_DIR=${WORK_DIR:="${BASE_DIR}/workdir"}

    source $BASE_DIR/common/manage-state.sh 
    load_state

  
    # Kops on GCE?
    read -e -p "Kops on GCE? (Y/N) [${KOPS_GCE:-$KOPS_GCE}]:" kopsg 
    KOPS_GCE=${kopsg:-"$KOPS_GCE"}

    # Kops on AWS?
    read -e -p "Kops on AWS? (Y/N) [${KOPS_AWS:-$KOPS_AWS}]:" kopsa 
    KOPS_AWS=${kopsa:-"$AWS_SECRET_ACCESS_KEY"}
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then

        # AWS ID
        read -e -p "AWS_ACCESS_KEY_ID [${AWS_ACCESS_KEY_ID:-$AWS_ACCESS_KEY_ID}]:" id 
        AWS_ACCESS_KEY_ID=${id:-"$AWS_ACCESS_KEY_ID"}
        
        # AWS Key
        read -e -p "AWS_SECRET_ACCESS_KEY [${AWS_SECRET_ACCESS_KEY:-$AWS_SECRET_ACCESS_KEY}]:" key 
        AWS_SECRET_ACCESS_KEY=${key:-"$AWS_SECRET_ACCESS_KEY"}
    fi
   


    write_state


    
    echo "WORK_DIR set to $WORK_DIR"
    gcloud config set project $PROJECT

    source ./common/settings.env
    ./common/install-tools.sh
    echo -e "\nMultiple tasks are running asynchronously to setup your environment.  It may appear frozen, but you can check the logs in $WORK_DIR for additional details in another terminal window." 


    ./gke/provision-gke.sh &> ${WORK_DIR}/provision-gke.log &

    shopt -s nocasematch
    if [[ ${KOPS_GCE} == y ]]; then
        ./connect-hub/provision-remote-gce.sh &> ${WORK_DIR}/provision-remote.log &
    fi

    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then
        ./connect-hub/provision-remote-aws.sh &> ${WORK_DIR}/provision-remote-aws.log &
    fi

    wait

    kubectx central && ./config-management/install-config-operator.sh
    kubectx remote && ./config-management/install-config-operator.sh


    kubectx central && ./hybrid-multicluster/istio-install-single.sh
    ./hybrid-multicluster/deploy-hipster-single.sh

    #./service-mesh/enable-service-mesh.sh


    ./connect-hub/connect-hub.sh


else
    echo "This has only been tested in GCP Cloud Shell.  Only Linux (debian) is supported".
fi

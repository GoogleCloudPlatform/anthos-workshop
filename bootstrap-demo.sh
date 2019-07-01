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


## Enable quite profile mode
while getopts "p:" OPTION
do
	case $OPTION in
		p) PROFILE=$OPTARG;;
	esac
done



if [[ $OSTYPE == "linux-gnu" && $CLOUD_SHELL == true ]]; then 

    export PROJECT=$(gcloud config get-value project)
    export BASE_DIR=${BASE_DIR:="${PWD}"}
    export WORK_DIR=${WORK_DIR:="${BASE_DIR}/workdir"}

    source $BASE_DIR/common/manage-state.sh 
    load_state

    if [[ $PROFILE ]]; then
        ## Load Profile
       load_profile $PROFILE
    else
        ## Get user defined Profile

        # Kops on GCE?
        read -e -p "Create GKE Cluster? (Y/N) [y]:" gke  
        export GKE_CLUSTER=${gke:-"y"}

        # Kops on GCE?
        read -e -p "Kops on GCE? (Y/N) [${KOPS_GCE:-$KOPS_GCE}]:" kopsg 
        export KOPS_GCE=${kopsg:-"$KOPS_GCE"}

        shopt -s nocasematch
        if [[ ${KOPS_GCE} == y ]]; then
            # GCE Context name
            read -e -p 'GCE_CONTEXT [remote]:' key
            export GCE_CONTEXT=${key:-"remote"} 
        fi

        # Kops on AWS?
        read -e -p "Kops on AWS? (Y/N) [${KOPS_AWS:-$KOPS_AWS}]:" kopsa 
        export KOPS_AWS=${kopsa:-"$KOPS_AWS"}
        shopt -s nocasematch
        
        if [[ ${KOPS_AWS} == y ]]; then

        # AWS Context name
        read -e -p 'AWS_CONTEXT [external]:' key
        export AWS_CONTEXT=${key:-"external"} 

        # AWS Uniquee Bucket Postfix
        export AWS_RND=${AWS_RND:-"1"}    
        fi
        

        # Config repo source 
    
        read -e -p "Config Repo Source [https://github.com/cgrant/policy-repo]:" reposource 
        export REPO_URL=${reposource:-"$REPO_URL"}
        read -e -p "Config Repo Branch [master]:" repobranch
        export REPO_BRANCH=${repobranch:-"$REPO_BRANCH"}

        # Deploy Hipster?
        read -e -p "Deploy hipster with kubectl? (Y/N) [y]:" deployhip 
        export DEPLOY_HIPSTER=${deployhip:-"y"}
    fi

    ## Get user provided Keys
    if [[ ${KOPS_AWS} == y ]]; then
        # AWS ID
        read -e -p "AWS_ACCESS_KEY_ID [${AWS_ACCESS_KEY_ID:-$AWS_ACCESS_KEY_ID}]:" id 
        export AWS_ACCESS_KEY_ID=${id:-"$AWS_ACCESS_KEY_ID"}
        
        # AWS Key
        read -e -p "AWS_SECRET_ACCESS_KEY [${AWS_SECRET_ACCESS_KEY:-$AWS_SECRET_ACCESS_KEY}]:" key 
        export AWS_SECRET_ACCESS_KEY=${key:-"$AWS_SECRET_ACCESS_KEY"}

    fi


    write_state


    echo "WORK_DIR set to $WORK_DIR"
    gcloud config set project $PROJECT

## Install Tooling
    source ./common/settings.env
    ./common/install-tools.sh
    echo -e "\nMultiple tasks are running asynchronously to setup your environment.  It may appear frozen, but you can check the logs in $WORK_DIR for additional details in another terminal window." 

## Provision Clusters

    # GKE
    shopt -s nocasematch
    if [[ ${GKE_CLUSTER} == y ]]; then
        ./gke/provision-gke.sh &> ${WORK_DIR}/provision-gke.log &
    fi

    # GCE
    shopt -s nocasematch
    if [[ ${KOPS_GCE} == y ]]; then
        ./connect-hub/provision-remote-gce.sh &> ${WORK_DIR}/provision-gce-${GCE_CONTEXT}.log &
    fi
    
    # External
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then
        ./connect-hub/provision-remote-aws.sh &> ${WORK_DIR}/provision-aws-${AWS_CONTEXT}.log &

        
    fi

    wait

## Install Anthos Config Manager

    # Repo
  

    yes y | ssh-keygen -t rsa -b 4096 -C "$GCLOUD_ACCOUNT" -N '' -f $HOME/.ssh/id_rsa.nomos>/dev/null
    gcloud services enable sourcerepo.googleapis.com
    source ./config-management/create-repo.sh

    GCLOUD_ACCOUNT=$(gcloud config get-value account)
    export REPO_URL=ssh://${GCLOUD_ACCOUNT}@source.developers.google.com:2022/p/${PROJECT}/r/config-repo


    cd $HOME/anthos-workshop
    # GKE
    shopt -s nocasematch
    if [[ ${GKE_CLUSTER} == y ]]; then
        kubectx central && kubectl create secret generic git-creds --namespace=config-management-system --from-file=ssh=$HOME/.ssh/id_rsa.nomos
        kubectx central && ./config-management/install-config-operator.sh
        kubectx central && ./config-management/install-config-sync.sh
    fi


    # GCE
    shopt -s nocasematch
    if [[ ${KOPS_GCE} == y ]]; then
        kubectx ${GCE_CONTEXT} && kubectl create secret generic git-creds --namespace=config-management-system --from-file=ssh=$HOME/.ssh/id_rsa.nomos    
        kubectx ${GCE_CONTEXT} && ./config-management/install-config-operator.sh
        kubectx ${GCE_CONTEXT} && ./config-management/install-config-sync.sh
    fi

    # External
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then
        kubectx ${AWS_CONTEXT} && kubectl create secret generic git-creds --namespace=config-management-system --from-file=ssh=$HOME/.ssh/id_rsa.nomos  
        kubectx ${AWS_CONTEXT} && ./config-management/install-config-operator.sh
        kubectx ${AWS_CONTEXT} && ./config-management/install-config-sync.sh
    fi
    
    

## Install Istio

    # GKE
    shopt -s nocasematch
    if [[ ${GKE_CLUSTER} == y ]]; then
        kubectx central && ./hybrid-multicluster/istio-install-single.sh
    fi
    

    # GCE
    shopt -s nocasematch
    if [[ ${KOPS_GCE} == y ]]; then
        kubectx ${GCE_CONTEXT} && ./hybrid-multicluster/istio-install-single.sh
    fi

    # External
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then
        kubectx ${AWS_CONTEXT} && ./hybrid-multicluster/istio-install-single.sh
    fi



## Install Hipster on GKE
    shopt -s nocasematch
    if [[ ${DEPLOY_HIPSTER} == y ]]; then
        ./hybrid-multicluster/deploy-hipster-single.sh
    fi 


## Enable Service Mesh
    ./service-mesh/enable-service-mesh.sh

## Register With Anthos Hub
    # GCE
    shopt -s nocasematch
    if [[ ${KOPS_GCE} == y ]]; then
        export CONTEXT=$GCE_CONTEXT && ./connect-hub/connect-hub.sh
    fi

    # Remote
    shopt -s nocasematch
    if [[ ${KOPS_AWS} == y ]]; then
        export CONTEXT=$AWS_CONTEXT && ./connect-hub/connect-hub.sh
    fi
    







else
    echo "This has only been tested in GCP Cloud Shell.  Only Linux (debian) is supported".
fi

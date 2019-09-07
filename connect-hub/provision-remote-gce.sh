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
export PROJECT=$(gcloud config get-value project)
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}

#export REMOTE_CLUSTER_NAME_BASE="remote-g"
export REMOTE_CLUSTER_NAME_BASE=${GCE_CONTEXT:-"remote"}

export REMOTE_CLUSTER_NAME=$REMOTE_CLUSTER_NAME_BASE.k8s.local
export KOPS_STORE=gs://$PROJECT-kops-$REMOTE_CLUSTER_NAME_BASE
export REMOTE_KUBECONFIG=$WORK_DIR/${REMOTE_CLUSTER_NAME_BASE}.context
export NODE_COUNT=4
export NODE_SIZE=n1-standard-2
export ZONES=us-central1-a
export INSTANCE_IP=$(curl -s api.ipify.org)
export INSTANCE_CIDR=$INSTANCE_IP/32

echo "### "
echo "### Begin provision remote cluster"
echo "### "


# Install Tools
mkdir -p $WORK_DIR/bin
export PATH=$PATH:$WORK_DIR/bin:



# Unlock GCE features (?)
export KOPS_FEATURE_FLAGS=AlphaAllowGCE

gsutil mb $KOPS_STORE

# Make sure bucket is created before cluster creation
n=0
until [ $n -ge 5 ]
do
    gsutil ls | grep $KOPS_STORE && break 
    n=$[$n+1]
    sleep 3
done

kops create cluster \
	--name=$REMOTE_CLUSTER_NAME \
	--zones=$ZONES \
	--state=$KOPS_STORE \
	--project=${PROJECT} \
	--node-count=$NODE_COUNT \
	--node-size=$NODE_SIZE \
	--admin-access=$INSTANCE_CIDR \
	--yes
    # --master-size $MASTER_SIZE --master-count 3 
     

KUBECONFIG= kubectl config view --minify --flatten --context=$REMOTE_CLUSTER_NAME > $REMOTE_KUBECONFIG


for (( c=1; c<=20; c++))
do
	echo "Check if cluster is ready - Attempt $c"
        CHECK=`kops validate cluster --name $REMOTE_CLUSTER_NAME --state $KOPS_STORE | grep ready | wc -l`
        if [[ "$CHECK" == "1" ]]; then
                break;
        fi
        sleep 10
done

sleep 20


# Ensure you have cluster-admin on the remote cluster
kubectl create clusterrolebinding user-cluster-admin --clusterrole cluster-admin --user $(gcloud config get-value account)


# Context
#kops export kubecfg remotectx
kubectx $REMOTE_CLUSTER_NAME_BASE=$REMOTE_CLUSTER_NAME && kubectx $REMOTE_CLUSTER_NAME_BASE


echo "Wait for nodes to be ready with:  'watch kubectl get nodes'"

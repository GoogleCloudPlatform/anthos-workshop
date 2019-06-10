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



## Tools and Paths

pip3 install awscli --upgrade --user

export PATH=$PATH:$HOME/.local/bin

aws --version




curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl $HOME/.local/bin/

eksctl version



curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
mv ./aws-iam-authenticator $HOME/.local/bin/aws-iam-authenticator

aws-iam-authenticator --help


# ensure access
aws s3 ls

git clone https://github.com/ahmetb/kubectx.git
mv kubectx/kube* $HOME/.local/bin/
rm -rf kubectx



curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x ./kops
sudo mv ./kops $HOME/.local/bin/


# Variables
export PROJECT=$(gcloud config get-value project)
#export REMOTE_CLUSTER_NAME_BASE="remote-a"
export REMOTE_CLUSTER_NAME_BASE=${AWS_CONTEXT:-"external"}

export REMOTE_CLUSTER_NAME=$REMOTE_CLUSTER_NAME_BASE.k8s.local
export KOPS_STORE=s3://$PROJECT-kops-$REMOTE_CLUSTER_NAME_BASE
export KOPS_STATE_STORE=$KOPS_STORE
export REMOTE_KUBECONFIG=$WORK_DIR/remote.context
export NODE_COUNT=4
export NODE_SIZE=t3.medium
export ZONES=us-west-2a






aws iam create-group --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops
aws iam create-user --user-name kops
aws iam add-user-to-group --user-name kops --group-name kops
aws iam create-access-key --user-name kops



aws s3 mb $KOPS_STATE_STORE


#kops create cluster --name=$REMOTE_CLUSTER_NAME --zones us-west-2a --master-size t3.medium --node-size t3.medium --yes

kops create cluster \
	--name=$REMOTE_CLUSTER_NAME \
	--zones=$ZONES \
	--state=$KOPS_STORE \
	--project=${PROJECT} \
	--node-count=$NODE_COUNT \
	--node-size=$NODE_SIZE \
    --master-size t3.medium \
	--yes


KUBECONFIG= kubectl config view --minify --flatten --context=$REMOTE_CLUSTER_NAME > $REMOTE_KUBECONFIG

for (( c=1; c<=40; c++))
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



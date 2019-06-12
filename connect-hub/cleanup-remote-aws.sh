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
export PATH=$PATH:$WORK_DIR/bin:
export PATH=$PATH:$HOME/.local/bin


export REMOTE_CLUSTER_NAME_BASE=${AWS_CONTEXT:-"external"}

export REMOTE_CLUSTER_NAME=$REMOTE_CLUSTER_NAME_BASE.k8s.local
export KOPS_STORE=s3://$PROJECT-kops-$REMOTE_CLUSTER_NAME_BASE-11

kops delete cluster --name $REMOTE_CLUSTER_NAME --state $KOPS_STORE --yes

kubectx -d $REMOTE_CLUSTER_NAME_BASE 

#aws iam remove-user-from-group --user-name kops --group-name kops

#aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
#aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
#aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
#aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
#aws iam detach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops
#aws iam delete-group --group-name kops

#aws iam delete-access-key [\w]+ --user-name kops
#aws iam delete-user --user-name kops


aws s3 rm $KOPS_STORE



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

export PROJECT=$(gcloud config get-value project)

# repo 
# cd $HOME
export GCLOUD_ACCOUNT=$(gcloud config get-value account)
export REPO_URL=https://source.developers.google.com/p/${PROJECT}/r/config-repo

# git clone https://github.com/cgrant/config-repo config-repo
# cd config-repo
# git remote remove origin
# git config credential.helper gcloud.sh
# git remote add origin $REPO_URL

# gcloud source repos create config-repo
# git push -u origin master

# # give ACM permission to read the repo 
# ssh-keygen -t rsa -b 4096 \
# -C "$GCLOUD_ACCOUNT" \
# -N '' \
# -f $HOME/.ssh/id_rsa.nomos

# # apply token to the cluster (using central only) 
# kubectx central
# kubectl create secret generic git-creds \
# --namespace=config-management-system \
# --from-file=ssh=$HOME/.ssh/id_rsa.nomos

# # user needs key to register to GCR 
# echo "-------- YOUR SSH KEY ----------- "
# cat $HOME/.ssh/id_rsa.nomos.pub

# configure ACM to look for files in this repo 
kubectx $CENTRAL
cat $BASE_DIR/config-management/config_sync.yaml | \
  sed 's|<REPO_URL>|'"$REPO_URL"'|g' | \
  sed 's|<CLUSTER_NAME>|'"$CENTRAL"'|g' | \
  sed 's|none|ssh|g' | \
  kubectl apply -f -
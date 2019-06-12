export PROJECT=$(gcloud config get-value project)

cd $HOME
export GCLOUD_ACCOUNT=$(gcloud config get-value account)
export REPO_URL=https://source.developers.google.com/p/${PROJECT}/r/config-repo



## CLONE REPO 

git clone https://github.com/cgrant/config-repo config-repo
cd config-repo
git remote remove origin
git config credential.helper gcloud.sh
git remote add origin $REPO_URL

gcloud source repos create config-repo
git push -u origin master


## SSH KEY
ssh-keygen -t rsa -b 4096 \
-C "$GCLOUD_ACCOUNT" \
-N '' \
-f $HOME/.ssh/id_rsa.nomos


## Add Key To clusters
# this must be done on each cluster
kubectx central
kubectl create secret generic git-creds \
--namespace=config-management-system \
--from-file=ssh=$HOME/.ssh/id_rsa.nomos

kubectx remote
kubectl create secret generic git-creds \
--namespace=config-management-system \
--from-file=ssh=$HOME/.ssh/id_rsa.nomos



### Apply the config 
export REMOTE=remote
export CENTRAL=central
REPO_URL=ssh://${GCLOUD_ACCOUNT}@source.developers.google.com:2022/p/${PROJECT}/r/config-repo

kubectx $REMOTE
# Replace variables and stream results to kubectl apply
cat $BASE_DIR/config-management/config_sync.yaml | \
  sed 's|<REPO_URL>|'"$REPO_URL"'|g' | \
  sed 's|<CLUSTER_NAME>|'"$REMOTE"'|g' | \
  sed 's|none|ssh|g' | \
  kubectl apply -f - 

kubectx $CENTRAL
cat $BASE_DIR/config-management/config_sync.yaml | \
  sed 's|<REPO_URL>|'"$REPO_URL"'|g' | \
  sed 's|<CLUSTER_NAME>|'"$CENTRAL"'|g' | \
  sed 's|none|ssh|g' | \
  kubectl apply -f -





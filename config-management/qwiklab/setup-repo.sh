export PROJECT=$(gcloud config get-value project)

# repo 
cd $HOME
export GCLOUD_ACCOUNT=$(gcloud config get-value account)
export REPO_URL=https://source.developers.google.com/p/${PROJECT}/r/config-repo

git clone https://github.com/cgrant/config-repo config-repo
cd config-repo
git remote remove origin
git config credential.helper gcloud.sh
git remote add origin $REPO_URL

gcloud source repos create config-repo
git push -u origin master

# give ACM permission to read the repo 
ssh-keygen -t rsa -b 4096 \
-C "$GCLOUD_ACCOUNT" \
-N '' \
-f $HOME/.ssh/id_rsa.nomos

# apply token to the cluster (using central only) 
kubectx central
kubectl create secret generic git-creds \
--namespace=config-management-system \
--from-file=ssh=$HOME/.ssh/id_rsa.nomos

# user needs key to register to GCR 
echo "-------- YOUR SSH KEY ----------- "
cat $HOME/.ssh/id_rsa.nomos.pub

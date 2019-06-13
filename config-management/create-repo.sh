

export PROJECT=$(gcloud config get-value project)
export REPO_URL=${REPO_URL:-"https://github.com/cgrant/hipster"}
export REPO_BRANCH=${REPO_BRANCH:-"next2019"}

cd $HOME
export GCLOUD_ACCOUNT=$(gcloud config get-value account)
export PROJECT_REPO_URL=https://source.developers.google.com/p/${PROJECT}/r/config-repo


if [[ ${REPO_BRANCH} != "master" ]]; then
    git clone ${REPO_URL} -b ${REPO_BRANCH} config-repo
else
    git clone ${REPO_URL} config-repo
fi

cd config-repo
git remote remove origin
git config credential.helper gcloud.sh
git remote add origin $PROJECT_REPO_URL

gcloud source repos create config-repo
if [[ ${REPO_BRANCH} != "master" ]]; then
    git push -u origin ${REPO_BRANCH}
else
    git push -u origin master
fi

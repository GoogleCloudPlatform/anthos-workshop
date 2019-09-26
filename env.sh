cd $HOME/anthos-workshop

export BASE_DIR=$PWD
export WORK_DIR=$BASE_DIR/workdir
export PATH=$PATH:$WORK_DIR/bin:
export PROJECT=$(gcloud config get-value project)

export ISTIO_VERSION=1.1.15
export KUBECTX_VERSION=v0.7.0
export HELM_VERSION=v2.14.3
export GKE_CLUSTER_VERSION=1.13.7
export KOPS_VERSION=1.12.3

## Install tree
## Note: This is here and not in install-tools.sh to ensure it is available across sessions since this is installed using apt-get
if command -v tree 2>/dev/null; then
	echo "tree already installed."
else
	echo "Installing tree..."
	sudo apt-get install tree
fi
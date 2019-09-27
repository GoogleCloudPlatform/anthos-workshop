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

## Setting variables for GKE
export CLUSTER_NAME="central"
export CLUSTER_ZONE="us-central1-b"
export CLUSTER_KUBECONFIG=$WORK_DIR/$CLUSTER_NAME.context

# Variables for remote kops cluster
export REMOTE_CLUSTER_NAME_BASE="remote"
export REMOTE_CLUSTER_NAME=$REMOTE_CLUSTER_NAME_BASE.k8s.local
export KOPS_STORE=gs://$PROJECT-kops-$REMOTE_CLUSTER_NAME_BASE
export REMOTE_KUBECONFIG=$WORK_DIR/remote.context
export NODE_COUNT=4
export NODE_SIZE=n1-standard-2
export ZONES=us-central1-a
export INSTANCE_IP=$(curl -s api.ipify.org)
export INSTANCE_CIDR=$INSTANCE_IP/32

# Variables for config manager 
export OPERATOR_YAML_LOCATION=$(gsutil cat gs://anthos-workshop/cfg-op-loc)

# Variables for istio
export ISTIO_DIR=$WORK_DIR/istio-$ISTIO_VERSION
export ISTIO_CONFIG_DIR="$BASE_DIR/hybrid-multicluster/istio"

## Install tree
## Note: This is here and not in install-tools.sh to ensure it is available across sessions since this is installed using apt-get
if command -v tree 2>/dev/null; then
	echo "tree already installed."
else
	echo "Installing tree..."
	sudo apt-get install tree
fi
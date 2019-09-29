cd $HOME/anthos-workshop

if [[ -z "$BASE_DIR" ]]; then
    export BASE_DIR=$(pwd)
    echo "export BASE_DIR=\"$(pwd)\"" >> ~/.bashrc
    export WORK_DIR=$BASE_DIR/workdir
    echo "export WORK_DIR=\"$BASE_DIR/workdir\"" >> ~/.bashrc
    export PATH=$PATH:$WORK_DIR/bin:
    echo "export PATH=\"$PATH\"" >> ~/.bashrc
fi

if [[ -z "$PROJECT" ]]; then
    export PROJECT=$(gcloud config get-value project)
    echo "export PROJECT=\"$(gcloud config get-value project)\"" >> ~/.bashrc
fi

if [[ -z "$ISTIO_VERSION" ]]; then
    export ISTIO_VERSION=1.1.15
    echo 'export ISTIO_VERSION="1.1.15"' >> ~/.bashrc
    export KUBECTX_VERSION=v0.7.0
    echo 'export KUBECTX_VERSION="v0.7.0"' >> ~/.bashrc
    export HELM_VERSION=v2.14.3
    echo 'export HELM_VERSION="v2.14.3"' >> ~/.bashrc
    export CLUSTER_VERSION=1.13.7
    echo 'export CLUSTER_VERSION="1.13.7"' >> ~/.bashrc
    export KOPS_VERSION=1.12.3
    echo 'export KOPS_VERSION="1.12.3"' >> ~/.bashrc
fi

## Setting variables for GKE
if [[ -z "$CLUSTER_NAME" ]]; then
    export CLUSTER_NAME="central"
    echo 'export CLUSTER_NAME="central"' >> ~/.bashrc
    export CLUSTER_ZONE="us-central1-b"
    echo 'export CLUSTER_ZONE="us-central1-b"' >> ~/.bashrc
    export CLUSTER_KUBECONFIG=$WORK_DIR/$CLUSTER_NAME.context
    echo "export CLUSTER_KUBECONFIG=\"$WORK_DIR/$CLUSTER_NAME.context\"" >> ~/.bashrc
fi

# Variables for remote kops cluster
if [[ -z "$REMOTE_CLUSTER_NAME_BASE" ]]; then
    export REMOTE_CLUSTER_NAME_BASE="remote"
    echo 'export REMOTE_CLUSTER_NAME_BASE="remote"' >> ~/.bashrc
    export REMOTE_CLUSTER_NAME=$REMOTE_CLUSTER_NAME_BASE.k8s.local
    echo "export REMOTE_CLUSTER_NAME=\"$REMOTE_CLUSTER_NAME_BASE.k8s.local\"" >> ~/.bashrc
    export KOPS_STORE=gs://$PROJECT-kops-$REMOTE_CLUSTER_NAME_BASE
    echo "export KOPS_STORE=\"gs://$PROJECT-kops-$REMOTE_CLUSTER_NAME_BASE\"" >> ~/.bashrc
    export REMOTE_KUBECONFIG=$WORK_DIR/remote.context
    echo "export REMOTE_KUBECONFIG=\"$WORK_DIR/remote.context\"" >> ~/.bashrc
    export NODE_COUNT=4
    echo 'export NODE_COUNT="4"' >> ~/.bashrc
    export NODE_SIZE=n1-standard-2
    echo 'export NODE_SIZE="n1-standard-2"' >> ~/.bashrc
    export ZONES=us-central1-a
    echo 'export ZONES="us-central1-a"' >> ~/.bashrc
    export INSTANCE_IP=$(curl -s api.ipify.org)
    echo 'export INSTANCE_IP=$(curl -s api.ipify.org)' >> ~/.bashrc
    export INSTANCE_CIDR=$INSTANCE_IP/32
    echo 'export INSTANCE_CIDR=$INSTANCE_IP/32' >> ~/.bashrc
fi

# Variables for config manager 
if [[ -z "$OPERATOR_YAML_LOCATION" ]]; then
    export OPERATOR_YAML_LOCATION=$(gsutil cat gs://anthos-workshop/cfg-op-loc)
    echo "export OPERATOR_YAML_LOCATION=\"$(gsutil cat gs://anthos-workshop/cfg-op-loc)\"" >> ~/.bashrc
fi

# Variables for istio
if [[ -z "$ISTIO_DIR" ]]; then
    export ISTIO_DIR=$WORK_DIR/istio-$ISTIO_VERSION
    echo "export ISTIO_DIR=\"$WORK_DIR/istio-$ISTIO_VERSION\"" >> ~/.bashrc
    export ISTIO_CONFIG_DIR="$BASE_DIR/hybrid-multicluster/istio"
    echo "export ISTIO_CONFIG_DIR=\"$BASE_DIR/hybrid-multicluster/istio\"" >> ~/.bashrc
fi
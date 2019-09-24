
if [[ $OSTYPE == "linux-gnu" && $CLOUD_SHELL == true ]]; then 
	if [ -f "/google/devshell/bashrc.google" ]; then
		source "/google/devshell/bashrc.google"
	fi

	cd $HOME/anthos-workshop

	export BASE_DIR=$PWD
	echo "BASE_DIR: ${BASE_DIR}"
	export WORK_DIR=$BASE_DIR/workdir
	echo "WORK_DIR: ${WORK_DIR}"
	export PATH=$PATH:$WORK_DIR/bin:
	echo "PATH: ${PATH}"
	export PROJECT=$(gcloud config get-value project)
	echo "PROJECT: ${PROJECT}"

	## Install tree
	## Note: This is here and not in install-tools.sh to ensure it is available across sessions since this is installed using apt-get
	if command -v tree 2>/dev/null; then
		echo "tree already installed."
	else
		echo "Installing tree..."
		sudo apt-get install tree
	fi

else
    echo "This has only been tested in GCP Cloud Shell.  Only Linux (debian) is supported".
fi

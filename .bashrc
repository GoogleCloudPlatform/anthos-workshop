
if [[ $OSTYPE == "linux-gnu" && $CLOUD_SHELL == true ]]; then 
	if [ -f "/google/devshell/bashrc.google" ]; then
		source "/google/devshell/bashrc.google"
	fi

	export BASE_DIR=$PWD
	echo "BASE_DIR: ${BASE_DIR}"
	export WORK_DIR=$BASE_DIR/workdir
	echo "WORK_DIR: ${WORK_DIR}"
	export PATH=$PATH:$WORK_DIR/bin:
	echo "PATH: ${PATH}"
	export PROJECT=$(gcloud config get-value project)
	echo "PROJECT: ${PROJECT}"

else
    echo "This has only been tested in GCP Cloud Shell.  Only Linux (debian) is supported".
fi
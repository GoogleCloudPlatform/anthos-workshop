
# Cloud Run content

## What is Cloud Run?
[Cloud Run](https://cloud.google.com/run/) is a managed compute platform that enables you to run stateless containers that are invocable via HTTP requests. 

### About this content
As part of the Anthos workshop, this content walks you through using Cloud Run to create a serverless, container-based service that responds to events (in this case, writing image files to a [GCS](https://cloud.google.com/storage/) bucket). When you write to the GCS bucket, a message will be sent to [Cloud PubSub](https://cloud.google.com/pubsub/), which will then trigger Cloud Run to analyze the image file via the [Cloud Vision API](https://cloud.google.com/vision/) and store the resulting analysis as a JSON document to the same GCS location. 

In the `cloud-run` directory in this repo is a shell script (`deploy-cloud-run.sh`) that will do the following:

- Create a GCS bucket
- Enable the Cloud PubSub & Cloud Vision APIs
- Create a PubSub topic 
- Enable GCS to PubSub notification for object writes
- Create a Cloud Run service (the image used for the service can be modified in the `deploy-cloud-run.sh` script)
- Create a PubSub subscription to trigger the Cloud Run service

Note that this script is *not* idempotent. Running it multiple times will do the following:

- Create multiple notification streams to PubSub
- Create multiple Cloud Run service revisions

So if you run in multiple times, you will want to clean up those excess notification resources.

Additionally, the Cloud Run service will be enabled *without* authentication enabled. The good news is that this allows you to perform a simple test from your browser or via cURL to verify that your service is running. The bad is that you wouldn't want to do this in production because anyone could invoke that endpoint. In a production environment you would enable auth for the Cloud Run service, and configure your PubSub push subscription to use a service account that had the proper invocation permissions.

The deployment script at `cloud-run/deploy-cloud-run.sh` references a pre-built deployment script that will deploy a `golang` container to respond to requests. If you'd like to modify the code and push those changes to your service, read ahead...

### Creating build triggers

[Google Cloud Build](https://cloud.google.com/cloud-build/) is managed service for creating build artifacts for any language. [Google Cloud Source Repositories](https://cloud.google.com/source-repositories/) is a fully managed private git repository. In Cloud Build you can create [build triggers](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds) - build triggers provide an automated system for kicking off a build pipeline to a git repository.

If you run `cloud-run/deploy-build-trigger.sh`, the following will happen:

- a new Cloud Source Repository will be created
- that repository will be cloned locally, and the source code in `cloud-run/src` will be copied to that directory
- a Cloud Build build trigger will be created that will build a new image when code is commited from the local repo directory, which will automatically be deployed to your Cloud Run service
- IAM policies will be applied to the Cloud Build service account to allow that service account to deploy the new image(s) to your Cloud Run service

Note that this will only work *after* running `cloud-run/deploy-cloud-run.sh`, and it requires that `jq` is installed.

### Cleaning up 

The resources you created for this demo can be removed by running `cloud-run/cleanup-cloud-run.sh` and (if you set up build triggers) running `cloud-run/cleanup-build-trigger.sh`.

Note for running `cloud-run/cleanup-build-trigger.sh`: this script removes the following IAM roles from the Cloud Build service account:

- `roles/run.admin`
- `roles/iam.serviceAccountUser`

If you're using these roles for other use cases, please make sure to re-add them.

Finally, this demo currently does *not* remove the [Google Container Registry](https://cloud.google.com/container-registry/) images created by this walkthrough. Please remove them manually if you wish to do so. 
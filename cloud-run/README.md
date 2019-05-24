
# Cloud Run content

## What is Cloud Run?
[Cloud Run](https://cloud.google.com/run/) is a managed compute platform that enables you to run stateless containers that are invocable via HTTP requests. 

### About this content
As part of the Anthos workshop, this content walks you through using Cloud Run to create a serverless, container-based service that responds to events (in this case, writing image files to a [GCS](https://cloud.google.com/storage/) bucket). When you write to the GCS bucket, a message will be sent to [Cloud PubSub](https://cloud.google.com/pubsub/), which will then trigger Cloud Run to analyze the image file via the [Cloud Vision API](https://cloud.google.com/vision/) and store the resulting analysis as a JSON document to the same GCS location. 

In the `cloud-run` directory in this repo is a shell script (`deploy-cloudrun.sh`) that will do the following:

- Create a GCS bucket
- Enable the Cloud PubSub & Cloud Vision APIs
- Create a PubSub topic 
- Enable GCS to PubSub notification for object writes
- Create a Cloud Run service (the image used for the service can be modified in the `deploy-cloudrun.sh` script)
- Create a PubSub subscription to trigger the Cloud Run service

Note that this script is *not* idempotent. Running it multiple times will do the following:

- Create multiple notification streams to PubSub
- Create multiple Cloud Run service revisions

So if you run in multiple times, you will want to clean up those excess notification resources.

Additionally, the Cloud Run service will be enabled *without* authentication enabled. The good news is that this allows you to perform a simple test from your browser or via cURL to verify that your service is running. The bad is that you wouldn't want to do this in production because anyone could invoke that endpoint. In a production environment you would enable auth for the Cloud Run service, and configure your PubSub push subscription to use a service account that had the proper invocation permissions.

The deployment script at `cloud-run/deploy-cloudrun.sh` references a pre-built deployment script that will deploy a `golang` container to respond to requests. If you'd like to modify the code and push those changes to your service, read ahead...

### Modifying the source code

In `cloud-run/src` is the source code for the Cloud Run service. If you modify it and wish to build that code in to a new image, run `cloud-run/src/cloudrun-build.sh`. Note that this will only work *after* running `cloud-run/deploy-cloudrun.sh`.

### Cleaning up 

The resources you created for this demo can be removed by running `cloud-run/cleanup-cloudrun.sh`.
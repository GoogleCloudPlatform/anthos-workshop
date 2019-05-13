
# Anthos Demo

## Overview
Kubernetes has become the market leader for orchestrating containers. GKE is Google‘s fully managed Kubernetes service in the cloud. We’ve brought that to data centers with GKE On-Prem and now we’re expanding with the release of Anthos. Anthos provides the tools and tech you need for modern hybrid and multi-cloud solutions, all built on the foundations of GKE. This workshop will walk through some of the features available within the Anthos stack.

## About this Repository
This repository contains the scripts and configurations used throughout the session. These are intended for instructional purposes as part of the Anthos Workshop.

## What you’ll learn
In this workshop, you’ll work through an example modernization effort moving a hybrid workload from a cluster that could be on-prem or with another cloud vendor to Google Kubernetes Engine. During the course of this exercise you’ll learn more about the features available in Anthos and GKE.

Topics covered will include:

### Connect & Hub

- Register non-GKE kubernetes to hub
- Deploy workloads - Hybrid hipster
- Review GKE & non GKE clusters and workloads through hub

### Config Management

- Auto install namespaces & logging daemonset on all nodes
- Register non-GKE cluster with Config Management and see the config apply
- Add a new config, push to repo and watch it apply to both clusters
  
### Hybrid Multicluster Workloads

- Move non-GKE workloads to GKE
- Demo Service Mesh capabilities

In this workshop we will use 2 Kubernetes clusters:
- A Kubernetes cluster built on Compute Engine using kops to simulate a remote cluster you may have on-prem or with another cloud vendor. 
- A GKE cluster in central designed to be your target environment. 

The workshop will begin by installing a hybrid application with components split between both clusters. During the workshop, the workload will be migrated to run wholly on GKE.

To learn more about Anthos or this Anthos workshop contact your Google Cloud sales representative.
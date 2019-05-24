# Anthos Workshop

## Overview
Kubernetes is the de-facto standard for container orchestration*, and Google Kubernetes Engine (GKE) is a leader in the field of managed Kubernetes offerings. In 2018, Google brought Kubernetes to data centers with a new offering called _GKE On-Prem_, a [certified](https://github.com/cncf/k8s-conformance) and managed extension of the cloud-based GKE platform. Responding to significant early successes and listening to customer needs, Google has expanded its efforts to enable your modernization effort. 

Anthos is a [modern application management platform](https://cloud.google.com/anthos/docs/concepts/anthos-overview) announced by Google at Next '19. Anthos  provides the tools and technology you need for modern, hybrid, and multi-cloud solutions, all built on the foundations of GKE. Anthos enables several features, including:
- Infrastructure provisioning in both cloud and on-premises.
- Infrastructure management tooling, security, policies and compliance solutions.
- Streamlined application development, service discovery and telemetry, service management, and workload migration from on-premises to cloud.

*_Nachmany, Udi (2018, November). Kubernetes: Evolution Of An IT Revolution. Retrieved from https://www.forbes.com/sites/udinachmany/2018/11/01/kubernetes-evolution-of-an-it-revolution/#5916c8a554e1_


## About this Repository
This repository contains the scripts and configurations intended for instructional purposes as part of the Anthos Workshop.

## What you’ll learn
In this workshop, you’ll work through an example modernization effort: moving a hybrid workload from a cluster that could be running on-prem or with another cloud vendor, to GKE in Google Cloud Platform (GCP). During the course of this workshop, you’ll learn more about the tools provided by Anthos that assist you with your modernization and migration to the cloud. 

This workshop will cover the following topics:

### GKE Connect & Hub
Centralized management of your Kubernetes clusters. In this section, you will:
- Register a non-GKE Kubernetes cluster to GKE Hub.
- Review GKE & non-GKE clusters and workloads through GKE Hub.
- Review workloads running in various locations across all your clusters.


### Anthos Config Management
Centralized configuration management for all your clusters. In this section, you will:
- Observe base state, which auto installs namespaces & logging DaemonSet on all nodes.
- Deploy Config Management custom resources and verify applied configuration.
- Add a new configuration, push it to the Config Management repo, and verify newly applied configuration in both clusters.

  
### Hybrid Multicluster Workloads
Applications split between clusters running in different on-prem and on-cloud locations. In this section, you will:
- Deploy an app using a hybrid model across multiple clusters.
- Learn the mechanics of multi-cluster mesh patterns.
- Migrate the remote, non-GKE workloads to cloud-based GKE.

### Service Manager 
Workload operational insights, SLO management and policy recommendations. In this section, you will:
- Review workload topology and connections.
- Inspect service level metrics and telemetry.
- Define and inspect Service Level Objectives.

To learn more about Anthos, or this Anthos workshop, contact your Google Cloud Sales team.
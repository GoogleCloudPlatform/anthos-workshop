#!/usr/bin/env bash

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Variables
INSTANCE_IP=$(curl -s api.ipify.org)
INSTANCE_CIDR=$INSTANCE_IP/32

gcloud compute firewall-rules create cidr-to-master-remote-k8s-local --allow tcp:443,tcp:4194 \
  --source-ranges=100.64.0.0/10 --target-tags=remote-k8s-local-k8s-io-role-master 
gcloud compute firewall-rules create cidr-to-node-remote-k8s-local --allow tcp,udp,icmp,esp,ah,sctp \
  --source-ranges=100.64.0.0/10 --target-tags=remote-k8s-local-k8s-io-role-node
gcloud compute firewall-rules create node-to-node-remote-k8s-local --allow tcp,udp,icmp,esp,ah,sctp \
  --source-tags=remote-k8s-local-k8s-io-role-node --target-tags=remote-k8s-local-k8s-io-role-node
gcloud compute firewall-rules create node-to-master-remote-k8s-local --allow tcp:443,tcp:4194 \
  --source-tags=remote-k8s-local-k8s-io-role-node --target-tags=remote-k8s-local-k8s-io-role-master 
gcloud compute firewall-rules create master-to-master-remote-k8s-local --allow tcp,udp,icmp,esp,ah,sctp \
  --source-tags=remote-k8s-local-k8s-io-role-master --target-tags=remote-k8s-local-k8s-io-role-master
gcloud compute firewall-rules create master-to-node-remote-k8s-local --allow tcp,udp,icmp,esp,ah,sctp \
  --source-tags=remote-k8s-local-k8s-io-role-master --target-tags=remote-k8s-local-k8s-io-role-node
gcloud compute firewall-rules create nodeport-external-to-node-remote-k8s-local --allow tcp:30000-32767,udp:30000-32767 \
  --source-tags=remote-k8s-local-k8s-io-role-node --target-tags=remote-k8s-local-k8s-io-role-node
gcloud compute firewall-rules create ssh-external-to-node-remote-k8s-local --allow tcp:22 \
  --source-ranges=$INSTANCE_CIDR --target-tags=remote-k8s-local-k8s-io-role-node
gcloud compute firewall-rules create ssh-external-to-master-remote-k8s-local --allow tcp:22 \
  --source-ranges=$INSTANCE_CIDR --target-tags=remote-k8s-local-k8s-io-role-master
gcloud compute firewall-rules create https-api-remote-k8s-local --allow tcp:443 \
  --source-ranges=$INSTANCE_CIDR --target-tags=remote-k8s-local-k8s-io-role-master
  

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

CIDR_REGEX="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))?$"
CENTRAL_REGEX="gke-gcp-default*"
REMOTE_REGEX="nodes-*"
CIDR_RANGE="/32"
FIREWALL_FILTER="tcp:15020,tcp:80,tcp:443,tcp:31400,tcp:15029,tcp:15030,tcp:15031,tcp:15032,tcp:15443"

# valid cidr ip required
if ! [[ $1 =~ $CIDR_REGEX ]];
then
  echo "Input a valid CIDR, i.e. 10.192.168.40/32"
  exit
fi

# grab the ip of the cloud shell instance
SHELL_IP=$(curl -s api.ipify.org)$CIDR_RANGE

# grab the ips for central
CENTRAL_IPS=$(gcloud compute instances list --filter="name~'$CENTRAL_REGEX'" --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
# grab the ips for remote
REMOTE_IPS=$(gcloud compute instances list --filter="name~'$REMOTE_REGEX'" --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

# combine ips
IPS="$CENTRAL_IPS $REMOTE_IPS"
# append /32 to each ip
IPS=$(printf "%s$CIDR_RANGE," $IPS)

# combine all ips
ALL_IPS="$SHELL_IP,$IPS$1"

echo -e "Applying the following source ranges to the applicable firewall rules:\n$ALL_IPS\n"
# pick the firewall rules that open 15020
FR=$(gcloud compute firewall-rules list \
  --format="table(name,allowed[].map().firewall_rule().list():label=ALLOW)" | \
  grep $FIREWALL_FILTER | \
  awk '{print $1}')

# for each firewall rule, add the compiled source range
for item in $FR
do
  gcloud compute firewall-rules update \
  $item \
  --source-ranges=$ALL_IPS
done



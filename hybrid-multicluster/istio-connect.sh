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

echo "### "
echo "### Port forwarding for prometheus, grafana and kiali"
echo "### "

# Expose PROMETHEUS POD on Port 9090 (central) and 9091 (remote)
PROM_PORT_1=9090
PROM_PORT_2=9091
PROM_POD_1=$(kubectl get po --namespace istio-system -l "app=prometheus" \
  -o jsonpath="{.items[0].metadata.name}" --context central)
PROM_POD_2=$(kubectl get po --namespace istio-system -l "app=prometheus" \
  -o jsonpath="{.items[0].metadata.name}" --context remote)

EXISTING_PID_9090=$(sudo netstat -nlp | grep $PROM_PORT_1 | awk '{print $7}' | cut -f1 -d '/')
EXISTING_PID_9091=$(sudo netstat -nlp | grep $PROM_PORT_2 | awk '{print $7}' | cut -f1 -d '/')

if [ -n "$EXISTING_PID_9090" ]; then
  echo "PID $EXISTING_PID_9090 already listening... restarting port-forward"
  kill $EXISTING_PID_9090
  sleep 5
fi
if [ -n "$EXISTING_PID_9091" ]; then
  echo "PID $EXISTING_PID_9091 already listening... restarting port-forward"
  kill $EXISTING_PID_9091
  sleep 5
fi

kubectl port-forward $PROM_POD_1 $PROM_PORT_1:9090 -n istio-system --context central >> /dev/null &
echo "Prometheus Port opened on $PROM_PORT_1 for central"

kubectl port-forward $PROM_POD_2 $PROM_PORT_2:9090 -n istio-system --context remote >> /dev/null &
echo "Prometheus Port opened on $PROM_PORT_2 for remote"

# Expose GRAFANA POD on Port 3000 (central) and 3001 (remote)
GRAFANA_PORT_1=3000
GRAFANA_PORT_2=3001
GRAFANA_POD_1=$(kubectl get po --namespace istio-system -l "app=grafana" \
  -o jsonpath="{.items[0].metadata.name}" --context central)
GRAFANA_POD_2=$(kubectl get po --namespace istio-system -l "app=grafana" \
  -o jsonpath="{.items[0].metadata.name}" --context remote)

EXISTING_PID_3000=$(sudo netstat -nlp | grep $GRAFANA_PORT_1 | awk '{print $7}' | cut -f1 -d '/')
EXISTING_PID_3001=$(sudo netstat -nlp | grep $GRAFANA_PORT_2 | awk '{print $7}' | cut -f1 -d '/')

if [ -n "$EXISTING_PID_3000" ]; then
  echo "PID $EXISTING_PID_3000 already listening... restarting port-forward"
  kill $EXISTING_PID_3000
  sleep 5
fi
if [ -n "$EXISTING_PID_3001" ]; then
  echo "PID $EXISTING_PID_3001 already listening... restarting port-forward"
  kill $EXISTING_PID_3001
  sleep 5
fi

kubectl port-forward $GRAFANA_POD_1 $GRAFANA_PORT_1:3000 -n istio-system --context central >> /dev/null &
echo "Grafana Port opened on $GRAFANA_PORT_1 for central"

kubectl port-forward $GRAFANA_POD_2 $GRAFANA_PORT_2:3000 -n istio-system --context remote >> /dev/null &
echo "Grafana Port opened on $GRAFANA_PORT_2 for remote"

# Expose KIALI POD on Port 20001 (central) and 20002 (remote)
KIALI_PORT_1=20001
KIALI_PORT_2=20002
KIALI_POD_1=$(kubectl get po --namespace istio-system -l "app=kiali" \
  -o jsonpath="{.items[0].metadata.name}" --context central)
KIALI_POD_2=$(kubectl get po --namespace istio-system -l "app=kiali" \
  -o jsonpath="{.items[0].metadata.name}" --context remote)

EXISTING_PID_20001=$(sudo netstat -nlp | grep $KIALI_PORT_1 | awk '{print $7}' | cut -f1 -d '/')
EXISTING_PID_20002=$(sudo netstat -nlp | grep $KIALI_PORT_2 | awk '{print $7}' | cut -f1 -d '/')

if [ -n "$EXISTING_PID_20001" ]; then
  echo "PID $EXISTING_PID_20001 already listening... restarting port-forward"
  kill $EXISTING_PID_20001
  sleep 5
fi
if [ -n "$EXISTING_PID_20002" ]; then
  echo "PID $EXISTING_PID_20002 already listening... restarting port-forward"
  kill $EXISTING_PID_20002
  sleep 5
fi

kubectl port-forward $KIALI_POD_1 $KIALI_PORT_1:20001 -n istio-system --context central >> /dev/null &
echo "Kiali Port opened on $KIALI_PORT_1 for central"

kubectl port-forward $KIALI_POD_2 $KIALI_PORT_2:20001 -n istio-system --context remote >> /dev/null &
echo "Kiali Port opened on $KIALI_PORT_2 for remote"




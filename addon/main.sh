#!/bin/bash

./pod-sec-policy.sh
# kube-system
./tiller.sh 
# kube-system
./metrics-server.sh
# kube-system
cluster-autoscaler.sh spectest.jin.apirs.net 5 us-west-2
# kube-system
efk.sh us-west-2a
# istio-system
istio.sh spectest.jin.apirs.net yuping-k8s-kops-state
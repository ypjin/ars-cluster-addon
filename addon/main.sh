#!/bin/bash
echo
echo =========================
echo deploy add-on services...

echo
echo -----------------------------------------------------------------------------------
echo install the default pod security policy and authorize it to all service accounts...
echo
./pod-sec-policy.sh

echo
echo ------------------------------------------
echo install tiller to namespace kube-system...
echo
# kube-system
./tiller.sh 

echo
echo --------------------------------------------------
echo install metrics server to namespace kube-system...
echo
# kube-system
./metrics-server.sh

echo
echo ------------------------------------------------------
echo install cluster-autoscaler to namespace kube-system...
echo
# kube-system
./cluster-autoscaler.sh spectest.jin.apirs.net 5 us-west-2

echo
echo ----------------------------------------------------------------
echo install elasticsearch-fluentd-kibana to namespace kube-system...
echo
# kube-system
./efk.sh us-west-2a

echo
echo ------------------------------------------
echo install istio to namespace istio-system...
echo
# istio-system
./istio.sh spectest.jin.apirs.net yuping-k8s-kops-state

echo 
echo done!
#!/bin/bash

_sa=helm
_ns=kube-system
_crb=tiller-cluster-role
_max_history=64
kubectl get sa -n "$_ns" --no-headers -o custom-columns=NAME:.metadata.name | grep -qw "$_sa" || \
    kubectl create serviceaccount --namespace "$_ns" "$_sa" 2>/dev/null
kubectl get clusterrolebinding -n "$_ns" --no-headers -o custom-columns=NAME:.metadata.name | grep -qw "$_crb" || \
    kubectl create clusterrolebinding "$_crb" --clusterrole=cluster-admin --serviceaccount=$_ns:$_sa
helm init --wait --service-account "$_sa" --upgrade --history-max "$_max_history"
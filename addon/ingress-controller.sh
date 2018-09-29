#!/bin/bash

# https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/installation.md

kubectl apply -f ./nginxinc/namespace.yaml

kubectl apply -f ./nginxinc/psp.yaml

helm install --name nginxinc --namespace nginx-ingress -f ./nginxinc/values.yaml ./nginxinc/helm-chart


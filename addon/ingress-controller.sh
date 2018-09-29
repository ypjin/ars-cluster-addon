#!/bin/bash

# https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/installation.md

kubectl apply -f ./nginxinc/namespace.yaml

kubectl apply -f ./nginxinc/psp.yaml

echo
echo >>>
echo install ingress controller for tenant services...
echo
helm install --name tenantinc --namespace ars-tenant-ingress -f ./nginxinc/values-tenant.yaml ./nginxinc/helm-chart

echo
echo >>>
echo install ingress controller for ARS system services...
echo
helm install --name systeminc --namespace ars-system-ingress -f ./nginxinc/values-system.yaml ./nginxinc/helm-chart

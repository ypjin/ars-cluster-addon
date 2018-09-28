#!/bin/bash

########################################################################################################################
#                      INSTALLATION of ISTIO release 1.0
########################################################################################################################

echo_and_exit() {
  echo "$@"
  exit 1
}

# ./istio.sh spectest.jin.apirs.net yuping-k8s-kops-state
usage() {
   cat <<EOF
Usage: $0  <CLUSTER_NAME>   <S3_BUCKET_NAME>
EOF
}

istio_init(){
  echo "install istio..."
  
  if [[ "$#" -ne "2" ]]; then
    usage
    return 1
  fi

  istiodir=$(mktemp -d) || return 1

# cat > api-server.json << EOF
#   kubeAPIServer:
#     admissionControl:
#     - NamespaceLifecycle
#     - LimitRanger
#     - ServiceAccount
#     - PersistentVolumeLabel
#     - DefaultStorageClass
#     - DefaultTolerationSeconds
#     - MutatingAdmissionWebhook
#     - ValidatingAdmissionWebhook
#     - ResourceQuota
#     - NodeRestriction
#     - Priority

# EOF


#  kops get cluster --name $1 --state $2 -o yaml > $istiodir/cluster.yaml || return 1
#  cat api-server.json >> $istiodir/cluster.yaml
#  echo " " >> $istiodir/cluster.yaml
#  echo "---" >> $istiodir/cluster.yaml
#  echo " " >> $istiodir/cluster.yaml
#  kops get ig --name $1 --state $2 -o yaml >> $istiodir/cluster.yaml || return 1

#  kops replace -f $istiodir/cluster.yaml --name $1 --state $2 || return 1
#  kops update cluster --yes  --name $1 --state $2 || return 1
#  kops rolling-update cluster --name $1 --state $2 --yes || return 1

 curl -o $istiodir/istio.tar.gz -sfL https://github.com/istio/istio/archive/1.0.0.tar.gz && \
 tar -C $istiodir -xvzf $istiodir/istio.tar.gz istio-1.0.0/install/kubernetes/helm/istio || return 1

 kubectl apply -f $istiodir/istio-1.0.0/install/kubernetes/helm/istio/templates/crds.yaml || return 1

 helm install $istiodir/istio-1.0.0/install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set ingress.enabled=false \
  --set gateways.istio-ingressgateway.enabled=true \
  --set gateways.istio-egressgateway.enabled=true \
  --set galley.enabled=false \
  --set sidecarInjectorWebhook.enabled=true \
  --set mixer.enabled=true \
  --set prometheus.enabled=true \
  --set grafana.enabled=true \
  --set servicegraph.enabled=true \
  --set global.proxy.envoyStatsd.enabled=true    

 echo "wait for istio to be ready..."

 ready=0
 SECONDS=0
 while [[ $ready -lt 1 ]]; do
    sleep 1
   ready=$(kubectl get deploy -n istio-system istio-egressgateway -o jsonpath='{.status.readyReplicas}')
    [[ $SECONDS -gt 40 ]] && break
 done
 [[ $SECONDS -gt 40 ]] && return 1 || echo "istio-egressgateway pods are ready"

 ready=0
 SECONDS=0
 while [[ $ready -lt 1 ]]; do
    sleep 1
    ready=$(kubectl get deploy -n istio-system istio-ingressgateway -o jsonpath='{.status.readyReplicas}')
    [[ $SECONDS -gt 40 ]] && break
 done
 [[ $SECONDS -gt 40 ]] && return 1 || echo "istio-ingressgateway pods are ready"

 ready=0
 SECONDS=0
 while [[ $ready -lt 1 ]]; do
    sleep 1
    ready=$(kubectl get deploy -n istio-system istio-pilot -o jsonpath='{.status.readyReplicas}')
    [[ $SECONDS -gt 60 ]] && break
 done
 [[ $SECONDS -gt 60 ]] && return 1 || echo "istio-pilot pods are ready"


 ready=0
 SECONDS=0
 while [[ $ready -lt 1 ]]; do
    sleep 1
    ready=$(kubectl get deploy -n istio-system istio-telemetry -o jsonpath='{.status.readyReplicas}')
    [[ $SECONDS -gt 40 ]] && break
 done
 [[ $SECONDS -gt 40 ]] && return 1 || echo "istio-telemetry pods are ready"

 ready=0
 SECONDS=0
 while [[ $ready -lt 1 ]]; do
    sleep 1
    ready=$(kubectl get deploy -n istio-system prometheus -o jsonpath='{.status.readyReplicas}')
    [[ $SECONDS -gt 40 ]] && break
 done
 [[ $SECONDS -gt 40 ]] && return 1 || echo "prometheus pods are ready"

 ready=0
 SECONDS=0    
 while [[ $ready -lt 1 ]]; do
    sleep 1
    ready=$(kubectl get deploy -n istio-system servicegraph -o jsonpath='{.status.readyReplicas}')
    [[ $SECONDS -gt 40 ]] && break
 done
 [[ $SECONDS -gt 40 ]] && return 1 || echo "servicegraph pods are ready"

 ready=0
 SECONDS=0
 while [[ $ready -lt 1 ]]; do
    sleep 1
    ready=$(kubectl get deploy -n istio-system istio-sidecar-injector -o jsonpath='{.status.readyReplicas}')
    [[ $SECONDS -gt 60 ]] && break
 done
 [[ $SECONDS -gt 60 ]] && return 1 || echo "istio-sidecar-injector pods are ready"
    
 echo "install istio done..."

 echo "istio cleanup directory..."
 rm -fr $istiodir
}

istio_init $1 $2 || echo_and_exit "istio failed"

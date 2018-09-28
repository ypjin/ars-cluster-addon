#!/bin/bash

########################################################################################################################
#                      INSTALLATION of a custom version metrics-server
########################################################################################################################

echo_and_exit() {
  echo "$@"
  exit 1
}

metrics_server_init(){

  echo "install metrics-server..."
     
  metricserverdir=$(mktemp -d) || return 1
   
  curl -sfL -o $metricserverdir/metrics-server.tar.gz https://github.com/abfathi/metrics-server/tarball/master && \
      tar -C $metricserverdir -xvzf $metricserverdir/metrics-server.tar.gz abfathi-metrics-server*/deploy/1.8+/*.yaml && \
      rm -f $metricserverdir/*.tar.gz && mv $metricserverdir/abfathi-metrics-server* $metricserverdir/metrics-server || return 1
 
  kubectl create -f $metricserverdir/metrics-server/deploy/1.8+/ || return 1

  echo "wait for metrics-server to be ready..."

  ready=0
  SECONDS=0
  while [[ $ready -lt 1 ]]; do
    sleep 1
    ready=$(kubectl get deploy -n kube-system metrics-server -o jsonpath='{.status.readyReplicas}')
    [[ $SECONDS -gt 40 ]] && break
  done
  [[ $SECONDS -gt 40 ]] && return 1 || echo "metrics-server pods are ready"
    
  echo "done"

  echo "metrics-server cleanup directory..."
  rm -fr $metricserverdir
}

metrics_server_init || echo_and_exit "metrics server failed"
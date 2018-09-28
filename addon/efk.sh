#!/bin/bash

########################################################################################################################
# INSTALLATION of a custom version of elascticseach and fluentd 
########################################################################################################################

usage() {
   cat <<EOF
Usage: $0 <AWS_ZONE>
EOF
}

echo_and_exit() {
  echo "$@"
  exit 1
}

efk_init(){
  echo "install efk..."
  
  if [[ "$#" -ne "1" ]]; then
    usage
    return 1
  fi

  # efkdir=$(mktemp -d) || return 1
  # echo "efkdir="$efkdir

  local AWS_ZONE=$1


  # curl -sfL -o $efkdir/efk.tar.gz https://github.com/ypjin/kubernetes/tarball/deploy-ES-to-ARS && \
  #  tar -C $efkdir -xvzf $efkdir/efk.tar.gz ypjin-kubernetes*/./cluster/addons/ && \
  #  rm -f $efkdir/*.tar.gz && mv $efkdir/ypjin-kubernetes* $efkdir/kubernetes || return 1

  # https://github.com/ypjin/kubernetes/commit/ff87891d0d729fab22c0f3c4e47393500695da86
  sed -i -e "s@zone: eu-central-1a@zone: ${AWS_ZONE}@g" ./fluentd-es/aws_ssd.yaml


  kubectl delete -f ./fluentd-es/fluentd-es-configmap.yaml
  kubectl delete -f ./fluentd-es/fluentd-es-ds.yaml
  kubectl delete -f ./fluentd-es/aws_ssd.yaml
  kubectl delete -f ./fluentd-es/es-statefulset.yaml
  kubectl delete -f ./fluentd-es/es-service.yaml
  kubectl delete -f ./fluentd-es/kibana-deployment.yaml
  kubectl delete -f ./fluentd-es/kibana-service.yaml


  kubectl create -f ./fluentd-es/fluentd-es-configmap.yaml || return 1
  kubectl create -f ./fluentd-es/fluentd-es-ds.yaml || return 1
  
  kubectl create -f ./fluentd-es/aws_ssd.yaml || return 1

  kubectl create -f ./fluentd-es/es-statefulset.yaml || return 1
  kubectl create -f ./fluentd-es/es-service.yaml || return 1

  kubectl create -f ./fluentd-es/kibana-deployment.yaml || return 1
  kubectl create -f ./fluentd-es/kibana-service.yaml || return 1

  # echo "efk cleanup directory..."
  # rm -fr $efkdir
}

efk_init $1 || echo_and_exit "efk init failed"

#!/bin/bash

########################################################################################################################
# Customised version from https://github.com/kubernetes/kops/blob/master/addons/cluster-autoscaler/cluster-autoscaler.sh
# INSTALLATION of kubernetes Cluster Autoscaler on worker nodes
########################################################################################################################

echo_and_exit() {
  echo "$@"
  exit 1
}

# ./cluster-autoscaler.sh spectest.jin.apirs.net 5 us-west-2 s3://yuping-k8s-kops-state
usage() {
   cat <<EOF
Usage: $0  <CLUSTER_NAME> <MAX_NODES> <AWS_REGION> <S3_BUCKET_NAME>
EOF
}

cluster_autoscaler_init(){
  
  if [[ "$#" -ne "4" ]]; then
    usage
    return 1
  fi

  clusterautoscalerdir=$(mktemp -d) || return 1

  echo "clusterautoscalerdir="$clusterautoscalerdir
  
  #Set all the variables in this section
  local CLUSTER_NAME=$1
  local CLOUD_PROVIDER=aws
  local IMAGE=k8s.gcr.io/cluster-autoscaler:v1.2.2
  local MIN_NODES=1
  local MAX_NODES=$2
  local AWS_REGION=$3
  local KOPS_STATE_STORE=$4
  local INSTANCE_GROUP_NAME="ars-tenant-nodes"
  local ASG_NAME="${INSTANCE_GROUP_NAME}.${CLUSTER_NAME}" 
  local IAM_ROLE="nodes.${CLUSTER_NAME}"  
  local SSL_CERT_PATH="/etc/ssl/certs/ca-bundle.crt" 

  echo " Set up Autoscaling"
  echo " Update the minSize and maxSize attributes for the kops instancegroup."

#################################################################################################################
# apiVersion: kops/v1alpha2
# kind: InstanceGroup
# metadata:
#  creationTimestamp: 2018-08-27T17:20:19Z
#  labels:
#    kops.k8s.io/cluster: dev.arscluster.k8s.local
#  name: nodes
# spec:
#  image: ami-de8fb135
#  machineType: m4.large
#  maxSize: 5
#  minSize: 1


#################################################################################################################
 
 kops get ig $INSTANCE_GROUP_NAME --name ${CLUSTER_NAME} --state ${KOPS_STATE_STORE} -o yaml >> $clusterautoscalerdir/ig.yaml || return 1

 sed -i -e "s@minSize: [0-9]*@minSize: ${MIN_NODES}@" $clusterautoscalerdir/ig.yaml
 sed -i -e "s@maxSize: [0-9]*@maxSize: ${MAX_NODES}@" $clusterautoscalerdir/ig.yaml

 kops replace -f $clusterautoscalerdir/ig.yaml --name ${CLUSTER_NAME} --state ${KOPS_STATE_STORE} || return 1
 kops update cluster --yes  --name ${CLUSTER_NAME} --state ${KOPS_STATE_STORE} || return 1

# à decaler plus bas possiblement
 kops rolling-update cluster  --yes --name ${CLUSTER_NAME} --state ${KOPS_STATE_STORE} || return 1

#################################################################################################################

#  echo "   Running kops update cluster --yes"
#  kops update cluster --yes --state ${KOPS_STATE_STORE} --name ${CLUSTER_NAME}
 
 echo " Creating IAM policy to allow aws-cluster-autoscaler access to AWS autoscaling groups…"
cat > asg-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": "*"
        }
    ]
}
EOF

 local ASG_POLICY_NAME=aws-cluster-autoscaler
 local TESTOUTPUT=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName == "aws-cluster-autoscaler") | .Arn')
 
 if [[ $? -eq 0 && -n "$TESTOUTPUT" ]]
 then
   echo "  Policy already exists\n"
   ASG_POLICY_ARN=$TESTOUTPUT
 else
   echo " Policy does not yet exist, creating now"
   ASG_POLICY=$(aws iam create-policy --policy-name $ASG_POLICY_NAME --policy-document file://asg-policy.json)
   ASG_POLICY_ARN=$(echo $ASG_POLICY | jq -r '.Policy.Arn')
 fi

 echo "  Attaching policy to IAM Role…\n"
 aws iam attach-role-policy --policy-arn $ASG_POLICY_ARN --role-name $IAM_ROLE

 rm -f ./asg-policy.json

 wget -O $clusterautoscalerdir/cluster-autoscaler-one-asg.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-one-asg.yaml
 
 sed -i -e "s@value: us-east-1@value: ${AWS_REGION}@g" $clusterautoscalerdir/cluster-autoscaler-one-asg.yaml
 sed -i -e "s@cloud-provider=aws@cloud-provider=${CLOUD_PROVIDER}@g" $clusterautoscalerdir/cluster-autoscaler-one-asg.yaml
 sed -i -e "s@nodes=1:10:k8s-worker-asg-1@nodes=${MIN_NODES}:${MAX_NODES}:${ASG_NAME}@g" $clusterautoscalerdir/cluster-autoscaler-one-asg.yaml
 sed -i -e "s@mountPath: /etc/ssl/certs/ca-certificates.crt@mountPath: ${SSL_CERT_PATH}@g" $clusterautoscalerdir/cluster-autoscaler-one-asg.yaml
 
 kubectl apply -f $clusterautoscalerdir/cluster-autoscaler-one-asg.yaml || return 1

 echo "wait for cluster-autoscaler to be ready..."
 ready=0
 SECONDS=0

 while [[ $ready -lt 1 ]]; do
   sleep 1
   ready=$(kubectl get deploy -n kube-system cluster-autoscaler -o jsonpath='{.status.readyReplicas}')
   [[ $SECONDS -gt 40 ]] && break
 done

 [[ $SECONDS -gt 40 ]] && return 1 || echo "cluster-autoscaler pods are ready"
 echo "Done"
 rm -fr $clusterautoscalerdir
}

cluster_autoscaler_init $1 $2 $3 $4|| echo_and_exit "cluster-autoscaler init failed"

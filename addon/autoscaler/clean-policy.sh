
#!/bin/bash

# ./clean-policy.sh spectest.jin.apirs.net
usage() {
   cat <<EOF
Usage: $0  <CLUSTER_NAME>
EOF
}

echo_and_exit() {
  echo "$@"
  exit 1
}

##########################################################################################################################################
# this should be called at the moment the cluster is destroyed to detach policy and delete it to allow proper cluster destroy
# !!!!!! Ideally should be called from within destroyInfra.sh  script 
# (peut etre un peu trop intrusif mais bon seul moyen trouvé pour l'instant pour synchroniser le nettoyage)
##########################################################################################################################################
detach_policy() {

  if [[ "$#" -ne "1" ]]; then
    usage
    return 1
  fi

   local CLUSTER_NAME=$1
   local IAM_ROLE="nodes.${CLUSTER_NAME}"
   local TESTOUTPUT=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName == "aws-cluster-autoscaler") | .Arn')

   if [[ $? -eq 0 && -n "$TESTOUTPUT" ]]
   then
    echo " Policy already exists"
    ASG_POLICY_ARN=$TESTOUTPUT
    echo " detaching policy to IAM Role"
    aws iam detach-role-policy --policy-arn $ASG_POLICY_ARN --role-name $IAM_ROLE
    aws iam delete-policy --policy-arn $ASG_POLICY_ARN
 else
   echo " Policy does not yet exist, nothing to do"
 fi
}

detach_policy $1 || echo_and_exit "clean up policy failed"
#!/bin/bash

kubectl delete psp restricted
kubectl delete clusterrole psp-restricted
kubectl delete clusterrolebinding psp-restricted


# https://kubernetes.io/docs/concepts/policy/pod-security-policy/
# https://kubernetes.io/docs/reference/access-authn-authz/rbac/
kubectl create -f- <<EOF

apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
  annotations:
    # seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default'
    # apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
    # seccomp.security.alpha.kubernetes.io/defaultProfileName:  'docker/default'
    # apparmor.security.beta.kubernetes.io/defaultProfileName:  'runtime/default'
spec:
  privileged: false
  # Required to prevent escalations to root.
  allowPrivilegeEscalation: false
  # This is redundant with non-root + disallow privilege escalation,
  # but we can provide it for defense in depth.
  requiredDropCapabilities:
    - ALL
  # Allow core volume types.
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    # Assume that persistentVolumes set up by the cluster admin are safe to use.
    - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    # Require the container to run without root privileges.
    # rule: 'MustRunAsNonRoot'
    rule: 'RunAsAny'
  seLinux:
    # This policy assumes the nodes are using AppArmor rather than SELinux.
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  readOnlyRootFilesystem: false


# apiVersion: extensions/v1beta1
# kind: PodSecurityPolicy
# metadata:
#   name: restricted
#   annotations:
#     seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
# spec:
#   privileged: true
#   allowPrivilegeEscalation: true
#   allowedCapabilities:
#   - '*'
#   volumes:
#   - '*'
#   hostNetwork: true
#   hostPorts:
#   - min: 0
#     max: 65535
#   hostIPC: true
#   hostPID: true
#   runAsUser:
#     rule: 'RunAsAny'
#   seLinux:
#     rule: 'RunAsAny'
#   supplementalGroups:
#     rule: 'RunAsAny'
#   fsGroup:
#     rule: 'RunAsAny'



---

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-restricted
rules:
- apiGroups: ['extensions']
  resources: ['podsecuritypolicies']
  verbs:     ['use']
  resourceNames:
  - restricted

---

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-restricted
roleRef:
  kind: ClusterRole
  name: psp-restricted
  apiGroup: rbac.authorization.k8s.io
subjects:
# Authorize all service accounts in a namespace:
- kind: Group
  apiGroup: rbac.authorization.k8s.io
  name: system:serviceaccounts

EOF
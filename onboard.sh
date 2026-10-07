cat > onboard.sh <<'EOF'
#!/bin/bash
# Usage: ./onboard.sh <practice> <cost-center>
P=$1; CC=$2
cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $P
  labels:
    practice: $P
    cost-center: $CC
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota
  namespace: $P
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
    pods: "10"
    persistentvolumeclaims: "2"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: $P
spec:
  limits:
  - type: Container
    default: {cpu: 200m, memory: 256Mi}
    defaultRequest: {cpu: 100m, memory: 128Mi}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: deployer
  namespace: $P
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: $P
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "pods/log", "services", "deployments", "statefulsets", "configmaps", "persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer
  namespace: $P
subjects:
- kind: ServiceAccount
  name: deployer
  namespace: $P
roleRef:
  kind: Role
  name: deployer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: same-namespace-only
  namespace: $P
spec:
  podSelector: {}
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector: {}
YAML
EOF
chmod +x onboard.sh
./onboard.sh practice-a cc-1001
./onboard.sh practice-b cc-2002

#!/bin/bash
# Checks Kubernetes version and warns about feature availability

K8S_VERSION=$(kubectl version -o json 2>/dev/null | \
  python3 -c "import json,sys; v=json.load(sys.stdin); print(v['serverVersion']['minor'])" 2>/dev/null || echo "unknown")

echo "Detected K8s minor version: 1.$K8S_VERSION"

if [ "$K8S_VERSION" -lt 35 ] 2>/dev/null; then
  echo ""
  echo "⚠️  In-Place Pod Resize (Scenario 05) requires K8s 1.35+ (currently GA)"
  echo "   Your version: 1.$K8S_VERSION"
  echo "   Upgrade: minikube start --kubernetes-version=v1.35.0"
  echo ""
fi

if [ "$K8S_VERSION" -ge 35 ] 2>/dev/null; then
  echo "✅ K8s 1.35+ detected — all scenarios available including in-place resize"
fi

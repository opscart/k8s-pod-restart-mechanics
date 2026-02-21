#!/bin/bash
# ==========================================================
# 04-istio-routing / 01-setup.sh
# PURPOSE: Deploy two app versions with Istio routing
# WHAT YOU WILL LEARN: Istio routing changes NEVER restart pods
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 04: Istio Routing — Zero Pod Restarts"
echo "========================================================"
echo ""
echo "We will deploy two versions of an app behind Istio."
echo "Then change routing rules and prove no pod restarts."
echo ""
echo "Istio updates Envoy's in-memory route table via xDS."
echo "No file write. No process signal. No pod restart. Ever."
echo ""

# Check Istio is installed
kubectl get ns istio-system > /dev/null 2>&1 || {
  echo "❌ Istio not installed. Run: minikube addons enable istio-provision"
  exit 1
}
echo "✅ Istio detected"

kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - > /dev/null

kubectl apply -f 04-istio-routing/deployment.yaml
kubectl apply -f 04-istio-routing/service.yaml
kubectl apply -f 04-istio-routing/destination-rule.yaml
kubectl apply -f 04-istio-routing/virtual-service-v1.yaml

echo "✅ echo-v1 deployed (2 replicas)"
echo "✅ echo-v2 deployed (2 replicas)"
echo "✅ Service created: echo"
echo "✅ DestinationRule created"
echo "✅ VirtualService created: 100% traffic → v1"

echo ""
echo "Waiting for pods..."
kubectl wait --for=condition=ready pod -l app=echo,version=v1 \
  -n $NS --timeout=90s
kubectl wait --for=condition=ready pod -l app=echo,version=v2 \
  -n $NS --timeout=90s

echo ""
echo "--- All pods running ---"
kubectl get pods -l app=echo -n $NS
echo ""

echo "--- Current routing: 100% → v1 ---"
kubectl get virtualservice echo -n $NS -o yaml | grep -A10 "route:"
echo ""

echo "========================================================"
echo "  SETUP COMPLETE"
echo "========================================================"
echo ""
echo "Both app versions are running."
echo "All traffic currently routes to v1."
echo ""
echo "Next step: Run  bash 04-istio-routing/02-check-baseline.sh"
echo ""

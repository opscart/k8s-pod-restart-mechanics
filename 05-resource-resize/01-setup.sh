#!/bin/bash
NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 05: In-Place Pod Resize — Setup"
echo "========================================================"
echo ""
echo "Deploying pod with explicit resizePolicy:"
echo ""
echo "  cpu:    NotRequired     → resize CPU, process untouched"
echo "  memory: RestartContainer → resize memory, container restarts"
echo "                             pod UID and IP remain the same"
echo ""

kubectl create namespace $NS --dry-run=client -o yaml | \
  kubectl apply -f - > /dev/null

kubectl apply -f 05-resource-resize/pod.yaml
echo "✅ Pod created: resize-demo"

echo ""
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod/resize-demo \
  -n $NS --timeout=60s

echo ""
echo "--- Current resources ---"
kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.spec.containers[0].resources}' | python3 -m json.tool

echo ""
echo "--- resizePolicy defined ---"
kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.spec.containers[0].resizePolicy}' | python3 -m json.tool

echo ""
echo "Next step: Run  bash 05-resource-resize/02-check-baseline.sh"
echo ""

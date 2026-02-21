#!/bin/bash
# ==========================================================
# 03-image-update / 01-setup.sh
# PURPOSE: Deploy app with nginx:1.25 — record pod identity
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 03: Image Update — Three Scenarios"
echo "========================================================"
echo ""
echo "This lab covers three scenarios:"
echo "  Scenario A: Successful image update"
echo "  Scenario B: Bad image (does not exist)"
echo "  Scenario C: Image exists but container crashes"
echo ""
echo "Key question for each: does the pod restart or get recreated?"
echo "The difference matters — name, UID, and IP all tell the story."
echo ""

kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl apply -f 03-image-update/deployment.yaml
echo "✅ Deployment created: image-demo (nginx:1.25, 1 replica)"

echo ""
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod -l app=image-demo \
  -n $NS --timeout=60s

echo ""
echo "========================================================"
echo "  RECORD THESE — compare them after each scenario"
echo "========================================================"
echo ""

POD=$(kubectl get pod -l app=image-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo "Pod name:     $POD"
echo "Pod UID:      $(kubectl get pod $POD -n $NS -o jsonpath='{.metadata.uid}')"
echo "Pod IP:       $(kubectl get pod $POD -n $NS -o jsonpath='{.status.podIP}')"
echo "Image:        $(kubectl get pod $POD -n $NS -o jsonpath='{.spec.containers[0].image}')"
echo "Restart count: $(kubectl get pod $POD -n $NS -o jsonpath='{.status.containerStatuses[0].restartCount}')"

echo ""
echo "--- ReplicaSet ---"
kubectl get rs -l app=image-demo -n $NS
echo ""
echo "Next step: Run  bash 03-image-update/02-scenario-a-good-image.sh"
echo ""

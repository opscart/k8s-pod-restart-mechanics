#!/bin/bash
# ==========================================================
# 03-image-update / 03-scenario-b-bad-image.sh
# SCENARIO B: Update to an image that does not exist
# PROVES: Kubernetes protects old pods until new ones are healthy
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  SCENARIO B: Bad Image (does not exist)"
echo "========================================================"
echo ""
echo "Updating image to nginx:this-tag-does-not-exist"
echo "The pull will fail. What happens to the running pod?"
echo ""

# Record current running pod
POD_BEFORE=$(kubectl get pod -l app=image-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo "Current running pod: $POD_BEFORE"
echo "Current image:       nginx:1.27"
echo ""

kubectl set image deployment/image-demo \
  app=nginx:this-tag-does-not-exist -n $NS
echo "✅ Bad image update triggered"
echo ""
echo "Waiting 30 seconds to observe behavior..."
sleep 30

echo ""
echo "========================================================"
echo "  RESULTS"
echo "========================================================"
echo ""
echo "--- All pods in namespace ---"
kubectl get pods -l app=image-demo -n $NS
echo ""
echo "--- Is the original pod still running? ---"
kubectl get pod $POD_BEFORE -n $NS 2>/dev/null && \
  echo "✅ YES — original pod still running" || \
  echo "original pod gone"
echo ""
echo "--- New pod status (should be ImagePullBackOff) ---"
NEW_POD=$(kubectl get pod -l app=image-demo -n $NS \
  --field-selector=status.phase!=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$NEW_POD" ]; then
  kubectl describe pod $NEW_POD -n $NS | grep -A5 "State:"
fi
echo ""

echo "========================================================"
echo "  KEY TAKEAWAY"
echo "========================================================"
echo ""
echo "  Bad image → new pod stuck in ImagePullBackOff"
echo "  Old pod:   STILL RUNNING (Kubernetes safety net)"
echo ""
echo "  Kubernetes will NOT kill the old pod until the"
echo "  new pod is healthy. Your app stays available."
echo ""
echo "Rolling back to fix this..."
kubectl rollout undo deployment/image-demo -n $NS
kubectl rollout status deployment/image-demo -n $NS --timeout=60s
echo "✅ Rolled back — original image restored"
echo ""
echo "Next step: Run  bash 03-image-update/04-scenario-c-crashloop.sh"
echo ""

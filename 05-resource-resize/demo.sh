#!/bin/bash
# Scenario 05: In-Place Pod Resize (CPU — No Restart)
# Requires: K8s 1.35+ (GA)
set -e
NS="restart-demos"

echo "=============================================="
echo " Scenario 05: In-Place Resource Resize (1.35+)"
echo "=============================================="

# Version gate
bash scripts/version-check.sh

kubectl apply -f 05-resource-resize/pod-with-resize-policy.yaml
kubectl wait --for=condition=ready pod/resize-demo -n $NS --timeout=60s

echo ""
echo "--- Initial resources ---"
kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.spec.containers[0].resources}' | python3 -m json.tool

RESTART_BEFORE=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')

echo ""
echo "--- Applying CPU resize: 200m → 1000m (no restart expected) ---"
kubectl patch pod resize-demo -n $NS \
  --subresource resize \
  -p "$(cat 05-resource-resize/resize-cpu-patch.json)"

echo ""
echo "--- Watching resize status (up to 30s) ---"
for i in {1..15}; do
  STATUS=$(kubectl get pod resize-demo -n $NS \
    -o jsonpath='{.status.resize}' 2>/dev/null || echo "")
  echo "  [$i] resize status: '${STATUS:-complete}'"
  [ -z "$STATUS" ] && break
  sleep 2
done

echo ""
echo "--- Allocated resources after resize ---"
kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.containerStatuses[0].allocatedResources}' | \
  python3 -m json.tool 2>/dev/null || \
  kubectl get pod resize-demo -n $NS \
    -o jsonpath='{.spec.containers[0].resources}' | python3 -m json.tool

RESTART_AFTER=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')

echo ""
echo "=== EVIDENCE ==="
echo "Restart count BEFORE: $RESTART_BEFORE"
echo "Restart count AFTER:  $RESTART_AFTER"

if [ "$RESTART_BEFORE" = "$RESTART_AFTER" ]; then
  echo "✅ CONFIRMED: CPU resize completed — ZERO container restarts"
else
  echo "ℹ  Container restarted (expected for memory resize with RestartContainer policy)"
fi

echo ""
echo "--- Events (resize progression) ---"
kubectl get events -n $NS \
  --field-selector involvedObject.name=resize-demo \
  --sort-by='.lastTimestamp' | tail -10

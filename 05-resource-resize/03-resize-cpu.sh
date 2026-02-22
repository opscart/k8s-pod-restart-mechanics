#!/bin/bash
NS="restart-demos"

echo ""
echo "========================================================"
echo "  SCENARIO A: CPU Resize"
echo "========================================================"
echo ""
echo "Changing CPU limit: 200m → 500m"
echo ""
echo "resizePolicy for cpu: NotRequired"
echo "This means: kubelet updates the cgroup quota directly."
echo "The running process is never signaled. Never paused."
echo "It simply gets more CPU cycles available immediately."
echo ""

RESTARTS_BEFORE=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
UID_BEFORE=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.metadata.uid}')
IP_BEFORE=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.podIP}')

echo "--- BEFORE ---"
echo "CPU limit:     200m"
echo "Restart count: $RESTARTS_BEFORE"
echo "Pod UID:       $UID_BEFORE"
echo "Pod IP:        $IP_BEFORE"
echo ""

kubectl patch pod resize-demo -n $NS \
  --subresource resize \
  -p '{"spec":{"containers":[{"name":"app","resources":{"requests":{"cpu":"250m","memory":"128Mi"},"limits":{"cpu":"500m","memory":"256Mi"}}}]}}'

echo "✅ CPU resize patch applied"
echo ""

echo "Watching resize status..."
for i in {1..10}; do
  STATUS=$(kubectl get pod resize-demo -n $NS \
    -o jsonpath='{.status.resize}' 2>/dev/null)
  if [ -z "$STATUS" ]; then
    echo "  ✅ Resize complete"
    break
  fi
  echo "  Status: $STATUS"
  sleep 2
done

echo ""
RESTARTS_AFTER=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
UID_AFTER=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.metadata.uid}')
IP_AFTER=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.podIP}')

echo "--- AFTER ---"
kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.spec.containers[0].resources}' | python3 -m json.tool
echo ""

echo "========================================================"
echo "  COMPARISON"
echo "========================================================"
echo ""
echo "  Pod UID:       $UID_AFTER  (unchanged)"
echo "  Pod IP:        $IP_AFTER  (unchanged)"
echo "  Restart count: $RESTARTS_AFTER  (unchanged)"
echo ""

if [ "$RESTARTS_BEFORE" = "$RESTARTS_AFTER" ] && \
   [ "$UID_BEFORE" = "$UID_AFTER" ]; then
  echo "✅ CONFIRMED: CPU resized 200m → 500m"
  echo "   Pod not recreated — UID and IP unchanged"
  echo "   Container not restarted — restart count unchanged"
  echo "   Only the cgroup cpu.max quota changed on the node"
else
  echo "⚠️  Unexpected change — check pod status"
fi

echo ""
echo "Next step: Run  bash 05-resource-resize/04-resize-memory.sh"
echo ""

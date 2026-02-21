#!/bin/bash
# ==========================================================
# 03-image-update / 04-scenario-c-crashloop.sh
# SCENARIO C: Image exists but container crashes immediately
# PROVES: Crash = restart in SAME pod (name/UID unchanged)
#         This is different from image update (recreation)
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  SCENARIO C: Container Crash (CrashLoopBackOff)"
echo "========================================================"
echo ""
echo "Deploying a pod that exits immediately on startup."
echo "Watch what happens — does Kubernetes recreate or restart?"
echo ""

kubectl apply -f 03-image-update/deployment-crashloop.yaml
echo "✅ crash-demo deployed"
echo ""
echo "Waiting 40 seconds to observe crash behavior..."
sleep 40

echo ""
echo "========================================================"
echo "  RESULTS"
echo "========================================================"
echo ""

CRASH_POD=$(kubectl get pod -l app=crash-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo "--- Pod status ---"
kubectl get pod $CRASH_POD -n $NS
echo ""

echo "--- Restart count (watch it climb) ---"
RESTARTS=$(kubectl get pod $CRASH_POD -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')
echo "Restart count: $RESTARTS"
echo ""

echo "--- Pod name and UID ---"
echo "Pod name: $CRASH_POD"
echo "Pod UID:  $(kubectl get pod $CRASH_POD -n $NS -o jsonpath='{.metadata.uid}')"
echo ""

echo "--- What happened inside ---"
kubectl describe pod $CRASH_POD -n $NS | grep -A8 "State:"
echo ""

echo "========================================================"
echo "  COMPARISON: Crash vs Image Update"
echo "========================================================"
echo ""
echo "  IMAGE UPDATE (Scenario A):"
echo "    Pod name:     CHANGED  (new pod created)"
echo "    Pod UID:      CHANGED  (different object)"
echo "    Pod IP:       CHANGED  (new network identity)"
echo "    Restart count: 0       (fresh pod)"
echo ""
echo "  CONTAINER CRASH (Scenario C):"
echo "    Pod name:     SAME     (same pod object)"
echo "    Pod UID:      SAME     (same object)"
echo "    Pod IP:       SAME     (same network identity)"
echo "    Restart count: $RESTARTS      (climbs with each crash)"
echo ""
echo "This is the core distinction:"
echo "  Recreation = new pod, new identity, restart count resets"
echo "  Restart    = same pod, same identity, restart count climbs"
echo ""
echo "When someone says 'the pod restarted' — ask which one."
echo "The answer changes your entire debugging approach."
echo ""
echo "Done with Lab 03."
echo "Run  bash 03-image-update/05-cleanup.sh  to remove lab resources"
echo ""

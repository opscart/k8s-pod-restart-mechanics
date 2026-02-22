#!/bin/bash
NS="restart-demos"

echo ""
echo "========================================================"
echo "  BASELINE: Record pod identity before any resize"
echo "========================================================"
echo ""

POD_UID=$(kubectl get pod resize-demo -n $NS -o jsonpath='{.metadata.uid}')
POD_IP=$(kubectl get pod resize-demo -n $NS -o jsonpath='{.status.podIP}')
RESTARTS=$(kubectl get pod resize-demo -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')

echo "Pod name:      resize-demo"
echo "Pod UID:       $POD_UID"
echo "Pod IP:        $POD_IP"
echo "Restart count: $RESTARTS"
echo "CPU limit:     200m"
echo "Memory limit:  256Mi"
echo ""
echo "After BOTH resizes — CPU and memory — the UID and IP"
echo "will remain the same. That is what 1.35 GA enables."
echo ""
echo "The only difference between the two scenarios is"
echo "whether the CONTAINER restarts inside the same pod."
echo ""
echo "Next step: Run  bash 05-resource-resize/03-resize-cpu.sh"
echo ""

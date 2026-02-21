#!/bin/bash
# ==========================================================
# 04-istio-routing / 02-check-baseline.sh
# PURPOSE: Record restart counts BEFORE routing change
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  BASELINE: Record restart counts before routing change"
echo "========================================================"
echo ""
echo "We record restart counts NOW."
echo "After changing the VirtualService, we compare."
echo "If counts are the same — zero restarts occurred."
echo ""

echo "--- All echo pods and their restart counts ---"
kubectl get pods -l app=echo -n $NS \
  -o custom-columns="NAME:.metadata.name,VERSION:.metadata.labels.version,RESTARTS:.status.containerStatuses[0].restartCount,AGE:.metadata.creationTimestamp"
echo ""

echo "--- Current VirtualService (100% to v1) ---"
echo "Run: kubectl get virtualservice echo -n $NS"
kubectl get virtualservice echo -n $NS
echo ""

echo "Write down the restart counts above — all should be 0."
echo "They must stay the same after we change the routing rule."
echo ""
echo "Next step: Run  bash 04-istio-routing/03-change-routing.sh"
echo ""

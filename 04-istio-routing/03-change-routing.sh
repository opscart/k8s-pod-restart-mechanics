#!/bin/bash
# ==========================================================
# 04-istio-routing / 03-change-routing.sh
# PURPOSE: Change routing 100%→v1 to 80/20 canary split
#          Prove ZERO pod restarts occur
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  CHANGING ROUTING: 100% v1 → 80% v1 / 20% v2"
echo "========================================================"
echo ""
echo "This simulates a canary deployment."
echo "20% of traffic shifts to v2 — without touching any pod."
echo ""

# Record restart counts before
echo "--- Restart counts BEFORE ---"
kubectl get pods -l app=echo -n $NS \
  -o custom-columns="NAME:.metadata.name,VERSION:.metadata.labels.version,RESTARTS:.status.containerStatuses[0].restartCount"
echo ""

kubectl apply -f 04-istio-routing/virtual-service-canary.yaml
echo "✅ VirtualService updated: 80% v1 / 20% v2"
echo ""

echo "Waiting 3 seconds for xDS push to propagate..."
sleep 3

echo ""
echo "--- Verify new routing rule ---"
echo "Run: kubectl get virtualservice echo -n $NS -o yaml | grep -A15 route:"
kubectl get virtualservice echo -n $NS -o yaml | grep -A15 "route:"
echo ""

echo "========================================================"
echo "  RESULTS — Did any pod restart?"
echo "========================================================"
echo ""

echo "--- Restart counts AFTER ---"
kubectl get pods -l app=echo -n $NS \
  -o custom-columns="NAME:.metadata.name,VERSION:.metadata.labels.version,RESTARTS:.status.containerStatuses[0].restartCount"
echo ""

echo "--- Pod ages unchanged (same pods, still running) ---"
kubectl get pods -l app=echo -n $NS
echo ""

echo "========================================================"
echo "  KEY TAKEAWAY"
echo "========================================================"
echo ""
echo "  Routing changed: 100% v1 → 80/20 split"
echo "  Pod restart count: unchanged"
echo "  Pod ages: unchanged — same pods still running"
echo ""
echo "  WHY: Istiod pushed the new route config to Envoy"
echo "  via a persistent gRPC stream (xDS protocol)."
echo "  Envoy swapped its in-memory route table."
echo "  No file write. No process signal. No restart."
echo ""
echo "Next step: Run  bash 04-istio-routing/04-full-cutover.sh"
echo "           (Send 100% traffic to v2)"
echo ""

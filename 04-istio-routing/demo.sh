#!/bin/bash
# Scenario 04: Istio Routing — Proves ZERO pod restarts on VirtualService change
set -e
NS="restart-demos"

echo "=============================================="
echo " Scenario 04: Istio xDS Routing Change"
echo "=============================================="

kubectl apply -f 04-istio-routing/deployment.yaml
kubectl apply -f 04-istio-routing/service.yaml
kubectl apply -f 04-istio-routing/destination-rule.yaml
kubectl apply -f 04-istio-routing/virtual-service-v1.yaml

echo "Waiting for pods with Istio sidecar..."
kubectl wait --for=condition=ready pod -l app=echo,version=v1 \
  -n $NS --timeout=90s

POD=$(kubectl get pod -l app=echo,version=v1 -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

RESTART_BEFORE=$(kubectl get pod $POD -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')

echo ""
echo "--- Pod: $POD ---"
echo "--- Restart count BEFORE: $RESTART_BEFORE ---"
echo ""
echo "--- Envoy routes BEFORE VirtualService change ---"
kubectl exec $POD -n $NS -c istio-proxy -- \
  pilot-agent request GET routes 2>/dev/null | \
  python3 -c "
import json, sys
try:
    routes = json.load(sys.stdin)
    for r in routes:
        print(f'  Route: {r.get(\"name\", \"unknown\")}')
except:
    print('  (parse error — check Istio version)')
" || echo "  (pilot-agent not available in this Istio version)"

echo ""
echo "--- Applying canary VirtualService (80/20 split) ---"
kubectl apply -f 04-istio-routing/virtual-service-canary.yaml

echo "Waiting 3s for xDS push..."
sleep 3

echo ""
echo "--- Envoy routes AFTER VirtualService change (same pod) ---"
kubectl exec $POD -n $NS -c istio-proxy -- \
  pilot-agent request GET routes 2>/dev/null | \
  python3 -c "
import json, sys
try:
    routes = json.load(sys.stdin)
    for r in routes:
        print(f'  Route: {r.get(\"name\", \"unknown\")}')
except:
    print('  (parse error)')
" || echo "  (pilot-agent not available)"

RESTART_AFTER=$(kubectl get pod $POD -n $NS \
  -o jsonpath='{.status.containerStatuses[0].restartCount}')

echo ""
echo "=== EVIDENCE ==="
echo "Restart count BEFORE: $RESTART_BEFORE"
echo "Restart count AFTER:  $RESTART_AFTER"

if [ "$RESTART_BEFORE" = "$RESTART_AFTER" ]; then
  echo ""
  echo "✅ CONFIRMED: VirtualService change — ZERO pod restarts"
  echo "   xDS push updated Envoy routing in-memory (milliseconds)"
else
  echo ""
  echo "⚠️  Unexpected restart detected — check pod events"
  kubectl describe pod $POD -n $NS | grep -A 10 "Events:"
fi

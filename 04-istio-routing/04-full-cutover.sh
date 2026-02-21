#!/bin/bash
# ==========================================================
# 04-istio-routing / 04-full-cutover.sh
# PURPOSE: Move 100% traffic to v2 — still zero restarts
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  FULL CUTOVER: 100% traffic → v2"
echo "========================================================"
echo ""

# Record before
BEFORE=$(kubectl get pods -l app=echo -n $NS \
  -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}')

kubectl patch virtualservice echo -n $NS \
  --type=json \
  -p='[
    {"op":"replace","path":"/spec/http/0/route/0/destination/subset","value":"v2"},
    {"op":"replace","path":"/spec/http/0/route/0/weight","value":100}
  ]' 2>/dev/null || \
kubectl apply -f - << 'VSEOF'
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: echo
  namespace: restart-demos
spec:
  hosts:
  - echo
  http:
  - route:
    - destination:
        host: echo
        subset: v2
      weight: 100
VSEOF

echo "✅ All traffic now routed to v2"
sleep 3

AFTER=$(kubectl get pods -l app=echo -n $NS \
  -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}')

echo ""
echo "--- Final restart count comparison ---"
echo "BEFORE: $BEFORE"
echo "AFTER:  $AFTER"
echo ""

if [ "$BEFORE" = "$AFTER" ]; then
  echo "✅ CONFIRMED: Three routing changes. Zero pod restarts."
  echo "   100%→v1, then 80/20 split, then 100%→v2."
  echo "   Same pods running throughout."
else
  echo "⚠️  Unexpected restart — check kubectl describe pod"
fi

echo ""
echo "--- All pods still running, ages unchanged ---"
kubectl get pods -l app=echo -n $NS
echo ""
echo "Done with Lab 04."
echo "Run  bash 04-istio-routing/05-cleanup.sh  to remove lab resources"
echo ""

#!/bin/bash
# ==========================================================
# 07-stakater-reloader / 03-update-configmap.sh
# PURPOSE: Update ConfigMap and watch Reloader trigger restart
# KEY MOMENT: No kubectl rollout restart needed
# ==========================================================

NS="restart-demos"

POD_BEFORE=$(kubectl get pod -l app=reloader-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  UPDATING CONFIGMAP — Reloader handles the rest"
echo "========================================================"
echo ""
echo "Pod before update: $POD_BEFORE"
echo ""
echo "Updating APP_MESSAGE..."
echo ""

kubectl patch configmap reloader-demo-config -n $NS \
  -p '{"data":{"APP_MESSAGE":"Hello from OpsCart v2 — auto reloaded!"}}'

echo "✅ ConfigMap updated"
echo ""
echo "--- Verify ConfigMap has new value ---"
echo "Run: kubectl get configmap reloader-demo-config -n $NS -o jsonpath='{.data.APP_MESSAGE}' && echo"
kubectl get configmap reloader-demo-config -n $NS \
  -o jsonpath='{.data.APP_MESSAGE}' && echo
echo ""
echo "Reloader detected the ConfigMap change."
echo "It is now adding a hash annotation to the pod template"
echo "which triggers the Deployment controller to roll out new pods."
echo ""
echo "Watching rolling restart..."
kubectl rollout status deployment/reloader-demo \
  -n $NS --timeout=60s

echo ""
echo "--- New pod created by Reloader ---"
POD_AFTER=$(kubectl get pod -l app=reloader-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
kubectl get pod $POD_AFTER -n $NS
echo ""

echo "--- Reloader annotation added to pod template ---"
echo "Run: kubectl get deploy reloader-demo -n $NS -o jsonpath='{.spec.template.metadata.annotations}'"
kubectl get deploy reloader-demo -n $NS \
  -o jsonpath='{.spec.template.metadata.annotations}' | \
  python3 -m json.tool 2>/dev/null || \
kubectl get deploy reloader-demo -n $NS \
  -o jsonpath='{.spec.template.metadata.annotations}'
echo ""
echo ""
echo "  Pod before: $POD_BEFORE"
echo "  Pod after:  $POD_AFTER"
echo ""
echo "Next step: Run  bash 07-stakater-reloader/04-verify-result.sh"
echo ""

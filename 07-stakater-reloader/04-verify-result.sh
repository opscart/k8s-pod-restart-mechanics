#!/bin/bash
# ==========================================================
# 07-stakater-reloader / 04-verify-result.sh
# PURPOSE: Confirm new pod has updated APP_MESSAGE
# ==========================================================

NS="restart-demos"

POD=$(kubectl get pod -l app=reloader-demo -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  VERIFY: New pod has updated ConfigMap value"
echo "========================================================"
echo ""

echo "--- APP_MESSAGE in new pod ---"
echo "Run: kubectl exec $POD -n $NS -- env | grep APP_MESSAGE"
kubectl exec $POD -n $NS -- env | grep APP_MESSAGE
echo ""

echo "========================================================"
echo "  KEY TAKEAWAY"
echo "========================================================"
echo ""
echo "  What happened without Reloader (manual process):"
echo "    1. Update ConfigMap"
echo "    2. Remember to run: kubectl rollout restart deployment/x"
echo "    3. Hope nobody forgets step 2 in production"
echo ""
echo "  What happened WITH Reloader:"
echo "    1. Update ConfigMap"
echo "    2. Done. Reloader handled the rest automatically."
echo ""
echo "  Reloader is not magic — it still restarts the pod."
echo "  Env vars still require a restart to update."
echo "  Reloader just makes sure that restart always happens."
echo ""
echo "Done with Lab 07."
echo "Run  bash 07-stakater-reloader/05-cleanup.sh  when done"
echo ""

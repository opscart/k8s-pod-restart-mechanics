#!/bin/bash
# ==========================================================
# 02-secret / 04-restart-fix.sh
# PURPOSE: Restart the env pod and prove it now reads the updated password
# THE FIX: A restart is the only way to update env vars
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  FIXING Pod A — Restart to pick up new password"
echo "========================================================"
echo ""
echo "Pod A is stuck on the old password."
echo "The only fix is a restart — the process must re-read"
echo "env vars from the pod spec, which now reflects the updated password."
echo ""

kubectl rollout restart deployment/secret-demo-env -n $NS

echo "Waiting for new pod to be ready..."
kubectl rollout status deployment/secret-demo-env -n $NS --timeout=60s

# Fresh pod name after restart
ENV_POD=$(kubectl get pod -l app=secret-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=secret-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  AFTER RESTART"
echo "========================================================"
echo ""

echo "[ Pod A — ENV VAR — after restart ]"
kubectl exec $ENV_POD -n $NS -- env | grep DB_PASSWORD
echo "  ✅ Now reading env-db-password — restart picked up the new secret"
echo ""

echo "[ Pod B — VOLUME MOUNT — untouched ]"
kubectl exec $VOL_POD -n $NS -- cat /etc/secrets/DB_PASSWORD
echo "  ✅ Still env-db-password — never needed a restart"
echo ""

echo "========================================================"
echo "  KEY TAKEAWAY"
echo "========================================================"
echo ""
echo "  ENV VAR:      Secret rotated → pod uses wrong value"
echo "                → must restart → restart picks up new value"
echo ""
echo "  VOLUME MOUNT: Secret rotated → kubelet syncs file"
echo "                → pod reads new value automatically"
echo "                → no restart ever needed"
echo ""
echo "Choose volume mounts for secrets that rotate."
echo "Use env vars only for values that never change."
echo ""
echo "Done with Lab 02."
echo "Run  bash 02-secret/05-cleanup.sh  to remove lab resources"
echo ""

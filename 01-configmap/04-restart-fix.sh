#!/bin/bash
# ==========================================================
# 01-configmap / 04-restart-fix.sh
# PURPOSE: Restart the env pod and prove it now reads red
# THE FIX: A restart is the only way to update env vars
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  FIXING Pod A — Restart to pick up new value"
echo "========================================================"
echo ""
echo "Pod A is stuck on blue."
echo "The only fix is a restart — the process must re-read"
echo "env vars from the pod spec, which now reflects red."
echo ""

kubectl rollout restart deployment/config-demo-env -n $NS

echo "Waiting for new pod to be ready..."
kubectl rollout status deployment/config-demo-env -n $NS --timeout=60s

# Fresh pod name after restart
ENV_POD=$(kubectl get pod -l app=config-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=config-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  AFTER RESTART"
echo "========================================================"
echo ""

echo "[ Pod A — ENV VAR — after restart ]"
echo "Run: kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR"
kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR
echo "  ✅ Now reading red — restart picked up the new ConfigMap value"
echo ""

echo "[ Pod B — VOLUME MOUNT — untouched ]"
echo "Run: kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR"
kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR && echo
echo "  ✅ Still red — never needed a restart"
echo ""

echo "========================================================"
echo "  KEY TAKEAWAY"
echo "========================================================"
echo ""
echo "  ENV VAR:      ConfigMap updated → pod sees old value"
echo "                → must restart → restart picks up new value"
echo ""
echo "  VOLUME MOUNT: ConfigMap updated → kubelet syncs file"
echo "                → pod reads new value automatically"
echo "                → no restart ever needed"
echo ""
echo "Choose volume mounts for config that changes at runtime."
echo "Use env vars only for values set once at deploy time."
echo ""
echo "Done with Lab 01."
echo "Run  bash 01-configmap/05-cleanup.sh  to remove lab resources"
echo ""

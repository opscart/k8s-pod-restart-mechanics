#!/bin/bash
# ==========================================================
# 01-configmap / 03-update-configmap.sh
# PURPOSE: Update the ConfigMap, wait for sync, check both pods
# THIS IS THE KEY MOMENT — same ConfigMap, two different outcomes
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  UPDATING THE CONFIGMAP: blue → red"
echo "========================================================"
echo ""
echo "Imagine a config change was pushed — APP_COLOR changed to red."
echo "Kubernetes ConfigMap is updated. What do the pods see?"
echo ""

kubectl patch configmap app-config -n $NS \
  -p '{"data":{"APP_COLOR":"red"}}'

echo "✅ ConfigMap updated in Kubernetes"
echo ""
echo "--- Verify the ConfigMap was updated ---"
echo "Run this yourself to confirm:"
echo ""
echo "  kubectl get configmap app-config -n $NS \\"
echo "    -o jsonpath='{.data.APP_COLOR}' && echo"
echo ""
echo "Output:"
kubectl get configmap app-config -n $NS \
  -o jsonpath='{.data.APP_COLOR}' && echo
echo ""
echo "Kubernetes now stores: red"
echo "But what do the RUNNING PODS actually see? That is the question."
echo ""
echo "Waiting 90 seconds for kubelet to sync the volume mount..."
echo "(kubelet syncs volume-mounted ConfigMaps on a periodic schedule)"
echo ""

for i in $(seq 90 -10 10); do
  echo "  ...${i}s remaining"
  sleep 10
done

# Re-query pod names fresh after wait
ENV_POD=$(kubectl get pod -l app=config-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=config-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  RESULTS — What do the pods see now?"
echo "========================================================"
echo ""

echo "[ Pod A — ENV VAR ]"
echo "Run: kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR"
kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR
echo ""
echo "  ⚠️  Still showing blue (the old value)."
echo "  The env var was baked into the process at startup."
echo "  Kubernetes cannot reach into process memory and change it."
echo "  This pod is showing the WRONG color and doesn't know it."
echo ""

echo "[ Pod B — VOLUME MOUNT ]"
echo "Run: kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR"
kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR && echo
echo ""
echo "  ✅ Now showing red (the new value)."
echo "  kubelet swapped the file on disk automatically."
echo "  No restart. No human intervention. Just works."
echo ""

echo "--- Verify the symlink swap happened ---"
echo "Run: kubectl exec $VOL_POD -n $NS -- ls -la /etc/config/"
kubectl exec $VOL_POD -n $NS -- ls -la /etc/config/
echo ""
echo "The timestamp on ..data directory changed — that is the swap."
echo ""

echo "========================================================"
echo "  CONCLUSION"
echo "========================================================"
echo ""
echo "  Kubernetes ConfigMap:  red   (updated)"
echo "  Pod A (env var):       blue  (WRONG — stuck on old value)"
echo "  Pod B (volume mount):  red   (CORRECT — synced automatically)"
echo ""
echo "In production: Pod A would render the wrong color, use the wrong"
echo "feature flag, or connect to the wrong endpoint — silently."
echo ""
echo "Next step: Run  bash 01-configmap/04-restart-fix.sh"
echo "           (Fix Pod A by restarting it)"
echo ""

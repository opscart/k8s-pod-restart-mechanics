#!/bin/bash
# ==========================================================
# 01-configmap / 02-check-baseline.sh
# PURPOSE: Confirm both pods see the original value
# ==========================================================

NS="restart-demos"

ENV_POD=$(kubectl get pod -l app=config-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=config-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  BASELINE: What do both pods see right now?"
echo "========================================================"
echo ""

echo "[ Pod A — ENV VAR ]"
echo "Run: kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR"
kubectl exec $ENV_POD -n $NS -- env | grep APP_COLOR
echo ""

echo "[ Pod B — VOLUME MOUNT ]"
echo "Run: kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR"
kubectl exec $VOL_POD -n $NS -- cat /etc/config/APP_COLOR && echo
echo ""

echo "Both pods see blue. Makes sense — nothing changed yet."
echo ""

echo "========================================================"
echo "  VERIFY THE CONFIGMAP YOURSELF"
echo "========================================================"
echo ""
echo "Want to check what Kubernetes stores in the ConfigMap?"
echo ""
echo "  kubectl get configmap app-config -n $NS \\"
echo "    -o jsonpath='{.data.APP_COLOR}' && echo"
echo ""
echo "Output:"
kubectl get configmap app-config -n $NS \
  -o jsonpath='{.data.APP_COLOR}' && echo
echo ""

echo "========================================================"
echo "  HOW Pod B STORES THE CONFIGMAP ON DISK"
echo "========================================================"
echo ""
echo "Run this inside Pod B to see the actual file structure:"
echo ""
echo "  kubectl exec $VOL_POD -n $NS -- ls -la /etc/config/"
echo ""
kubectl exec $VOL_POD -n $NS -- ls -la /etc/config/
echo ""
echo "Notice the ..data symlink pointing to a timestamped directory."
echo "When the ConfigMap changes, kubelet swaps THAT symlink atomically."
echo "The file on disk updates. No pod restart needed."
echo ""
echo "Next step: Run  bash 01-configmap/03-update-configmap.sh"
echo ""

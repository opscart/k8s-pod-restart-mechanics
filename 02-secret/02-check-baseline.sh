#!/bin/bash
# ==========================================================
# 02-secret / 02-check-baseline.sh
# PURPOSE: Confirm both pods see the original password
# ==========================================================

NS="restart-demos"

ENV_POD=$(kubectl get pod -l app=secret-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=secret-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  BASELINE: What do both pods see right now?"
echo "========================================================"
echo ""

echo "[ Pod A — ENV VAR ]"
kubectl exec $ENV_POD -n $NS -- env | grep DB_PASSWORD
echo ""

echo "[ Pod B — VOLUME MOUNT ]"
kubectl exec $VOL_POD -n $NS -- cat /etc/secrets/DB_PASSWORD
echo ""
echo ""

echo "Both pods see db-password. Makes sense — nothing changed yet."
echo ""

echo "========================================================"
echo "  VERIFY THE SECRET YOURSELF"
echo "========================================================"
echo ""
echo "Want to check what Kubernetes actually stores in the secret?"
echo "Secrets are base64 encoded. Run this to decode and read it:"
echo ""
echo "  kubectl get secret app-secret -n $NS \\"
echo "    -o jsonpath='{.data.DB_PASSWORD}' | base64 -d && echo"
echo ""
echo "Output:"
kubectl get secret app-secret -n $NS \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d && echo
echo ""
echo ""
echo "Want to see all keys inside the secret?"
echo ""
echo "  kubectl get secret app-secret -n $NS -o yaml"
echo ""
kubectl get secret app-secret -n $NS -o yaml | grep -A5 "data:"
echo ""

echo "========================================================"
echo "  HOW Pod B STORES THE SECRET ON DISK"
echo "========================================================"
echo ""
echo "Run this inside Pod B to see the actual file structure:"
echo ""
echo "  kubectl exec $VOL_POD -n $NS -- ls -la /etc/secrets/"
echo ""
kubectl exec $VOL_POD -n $NS -- ls -la /etc/secrets/
echo ""
echo "Notice the ..data symlink pointing to a timestamped directory."
echo "When the secret changes, kubelet swaps THAT symlink atomically."
echo "The file on disk updates. No pod restart needed."
echo ""
echo "Next step: Run  bash 02-secret/03-update-secret.sh"
echo ""
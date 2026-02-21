#!/bin/bash
# ==========================================================
# 02-secret / 03-update-secret.sh
# PURPOSE: Rotate the password, wait for sync, check both pods
# THIS IS THE KEY MOMENT — same secret, two different outcomes
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  ROTATING THE PASSWORD"
echo "========================================================"
echo ""
echo "Imagine your security team just rotated the DB password."
echo "They updated the Kubernetes secret. What do the pods see?"
echo ""

kubectl patch secret app-secret -n $NS \
  -p '{"stringData":{"DB_PASSWORD":"env-db-password"}}'

echo "✅ Secret updated in Kubernetes"
echo ""
echo "--- Verify the secret was updated ---"
echo "Run this yourself to confirm Kubernetes has the new password:"
echo ""
echo "  kubectl get secret app-secret -n $NS \\"
echo "    -o jsonpath='{.data.DB_PASSWORD}' | base64 -d && echo"
echo ""
echo "Output:"
kubectl get secret app-secret -n $NS \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d && echo
echo ""
echo ""
echo "Kubernetes now stores: env-db-password"
echo "But what do the RUNNING PODS actually see? That is the question."
echo ""
echo "Waiting 90 seconds for kubelet to sync the volume mount..."
echo "(kubelet syncs volume-mounted secrets on a periodic schedule)"
echo ""

for i in $(seq 90 -10 10); do
  echo "  ...${i}s remaining"
  sleep 10
done

# Re-query pod names fresh after wait
ENV_POD=$(kubectl get pod -l app=secret-demo-env -n $NS \
  -o jsonpath='{.items[0].metadata.name}')
VOL_POD=$(kubectl get pod -l app=secret-demo-volume -n $NS \
  -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "========================================================"
echo "  RESULTS — What do the pods see now?"
echo "========================================================"
echo ""

echo "[ Pod A — ENV VAR ]"
echo "Run: kubectl exec $ENV_POD -n $NS -- env | grep DB_PASSWORD"
kubectl exec $ENV_POD -n $NS -- env | grep DB_PASSWORD
echo ""
echo "  ⚠️  Still showing db-password (the old password)."
echo "  The env var was baked into the process at startup."
echo "  Kubernetes cannot reach into process memory and change it."
echo "  This pod is using the WRONG password and doesn't know it."
echo ""

echo "[ Pod B — VOLUME MOUNT ]"
echo "Run: kubectl exec $VOL_POD -n $NS -- cat /etc/secrets/DB_PASSWORD"
kubectl exec $VOL_POD -n $NS -- cat /etc/secrets/DB_PASSWORD
echo ""
echo "  ✅ Now showing env-db-password (the new password)."
echo "  kubelet swapped the file on disk automatically."
echo "  No restart. No human intervention. Just works."
echo ""

echo "--- Verify the symlink swap happened ---"
echo "Run: kubectl exec $VOL_POD -n $NS -- ls -la /etc/secrets/"
kubectl exec $VOL_POD -n $NS -- ls -la /etc/secrets/
echo ""
echo "The timestamp on ..data directory changed — that is the swap."
echo ""

echo "========================================================"
echo "  CONCLUSION"
echo "========================================================"
echo ""
echo "  Kubernetes secret:    env-db-password  (updated)"
echo "  Pod A (env var):      db-password         (WRONG — stuck)"
echo "  Pod B (volume mount): env-db-password  (CORRECT — synced)"
echo ""
echo "In production: Pod A would fail DB connections after rotation."
echo "No error thrown. No alert fired. Silent failure."
echo ""
echo "Next step: Run  bash 02-secret/04-restart-fix.sh"
echo "           (Fix Pod A by restarting it)"
echo ""
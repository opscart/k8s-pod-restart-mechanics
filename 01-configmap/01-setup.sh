#!/bin/bash
# ==========================================================
# 01-configmap / 01-setup.sh
# PURPOSE: Deploy everything needed for the ConfigMap lab
# WHAT YOU WILL LEARN: How two pods consume the same ConfigMap
#                      differently — env var vs volume mount
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 01: ConfigMap — Env Var vs Volume Mount"
echo "========================================================"
echo ""
echo "We will deploy:"
echo "  1. A ConfigMap holding an app color value"
echo "  2. Pod A — reads the ConfigMap as an ENV VAR"
echo "  3. Pod B — reads the ConfigMap as a VOLUME MOUNT (file)"
echo ""
echo "Same ConfigMap. Two different consumption methods."
echo "We will see how each behaves when the ConfigMap changes."
echo ""

kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - > /dev/null

kubectl apply -f 01-configmap/configmap.yaml
echo "✅ ConfigMap created: app-config (APP_COLOR=blue)"

kubectl apply -f 01-configmap/deployment-env.yaml
echo "✅ Pod A deployed: config-demo-env (reads via ENV VAR)"

kubectl apply -f 01-configmap/deployment-volume.yaml
echo "✅ Pod B deployed: config-demo-volume (reads via VOLUME MOUNT)"

echo ""
echo "Waiting for both pods to be ready..."
kubectl wait --for=condition=ready pod -l app=config-demo-env \
  -n $NS --timeout=60s
kubectl wait --for=condition=ready pod -l app=config-demo-volume \
  -n $NS --timeout=60s

echo ""
echo "========================================================"
echo "  SETUP COMPLETE"
echo "========================================================"
echo ""
echo "Both pods are running. Both currently see APP_COLOR=blue"
echo ""
echo "Want to verify? Run:"
echo "  kubectl get configmap app-config -n $NS -o yaml"
echo ""
kubectl get configmap app-config -n $NS -o yaml | grep -A5 "data:"
echo ""
echo "Next step: Run  bash 01-configmap/02-check-baseline.sh"
echo ""

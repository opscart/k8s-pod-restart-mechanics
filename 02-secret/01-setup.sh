#!/bin/bash
# ==========================================================
# 02-secret / 01-setup.sh
# PURPOSE: Deploy everything needed for the Secret lab
# WHAT YOU WILL LEARN: How two pods consume the same secret
#                      differently — env var vs volume mount
# ==========================================================

NS="restart-demos"

echo ""
echo "========================================================"
echo "  LAB 02: Secret — Env Var vs Volume Mount"
echo "========================================================"
echo ""
echo "We will deploy:"
echo "  1. A Secret holding a database password"
echo "  2. Pod A — reads the secret as an ENV VAR"
echo "  3. Pod B — reads the secret as a VOLUME MOUNT (file)"
echo ""
echo "Same secret. Two different consumption methods."
echo "We will see how each behaves when the secret changes."
echo ""

# Create namespace if needed
kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - > /dev/null

# Deploy the secret
kubectl apply -f 02-secret/secret.yaml
echo "✅ Secret created: app-secret"

# Deploy Pod A — env var
kubectl apply -f 02-secret/deployment-env.yaml
echo "✅ Pod A deployed: secret-demo-env (reads via ENV VAR)"

# Deploy Pod B — volume mount
kubectl apply -f 02-secret/deployment-volume.yaml
echo "✅ Pod B deployed: secret-demo-volume (reads via VOLUME MOUNT)"

echo ""
echo "Waiting for both pods to be ready..."
kubectl wait --for=condition=ready pod -l app=secret-demo-env \
  -n $NS --timeout=60s
kubectl wait --for=condition=ready pod -l app=secret-demo-volume \
  -n $NS --timeout=60s

echo ""
echo "========================================================"
echo "  SETUP COMPLETE"
echo "========================================================"
echo ""
echo "Both pods are running. Both currently see DB_PASSWORD=db-password"
echo ""
echo "Next step: Run  bash 02-secret/02-check-baseline.sh"
echo ""

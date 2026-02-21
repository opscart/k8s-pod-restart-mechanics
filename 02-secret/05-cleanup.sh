#!/bin/bash
# ==========================================================
# 02-secret / 05-cleanup.sh
# PURPOSE: Remove all lab 02 resources
# ==========================================================

NS="restart-demos"

echo ""
echo "Cleaning up Lab 02 resources..."

kubectl delete deployment secret-demo-env secret-demo-volume \
  -n $NS --ignore-not-found
kubectl delete secret app-secret \
  -n $NS --ignore-not-found

echo "✅ Lab 02 resources removed"
echo ""
